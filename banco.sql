-- Execute no Supabase: SQL Editor > New query > cole tudo > Run.
-- Ajuste o domínio do e-mail do administrador, se for diferente de lavanderia.app.

-- 1) Reservas -------------------------------------------------------------
create table if not exists public.reservas (
  id          bigint generated always as identity primary key,
  dia         date    not null,
  maquina     text    not null check (maquina in ('lavadora-1','lavadora-2','secadora-1','secadora-2')),
  hora        int     not null check (hora between 8 and 21),
  apartamento int     not null check (apartamento between 1 and 42),
  user_id     uuid    not null default auth.uid(),
  criado_em   timestamptz not null default now(),
  unique (dia, maquina, hora)            -- impede dois moradores no mesmo horário
);
alter table public.reservas enable row level security;
drop policy if exists "ler reservas"      on public.reservas;
drop policy if exists "reservar"          on public.reservas;
drop policy if exists "cancelar propria"  on public.reservas;
create policy "ler reservas"     on public.reservas for select to authenticated using (true);
create policy "reservar"         on public.reservas for insert to authenticated with check (user_id = auth.uid());
create policy "cancelar propria" on public.reservas for delete to authenticated using (user_id = auth.uid());

-- 2) Ciclos dos sensores (IoT simulado) -----------------------------------
create table if not exists public.ciclos_sensor (
  id          bigint generated always as identity primary key,
  maquina     text not null check (maquina in ('lavadora-1','lavadora-2','secadora-1','secadora-2')),
  inicio      timestamptz not null,
  fim         timestamptz not null,
  duracao_min int  not null,
  corrente_a  numeric(5,2) not null check (corrente_a > 0),
  check (fim > inicio)
);
alter table public.ciclos_sensor enable row level security;
drop policy if exists "ler ciclos"       on public.ciclos_sensor;
drop policy if exists "admin grava ciclos" on public.ciclos_sensor;
create policy "ler ciclos" on public.ciclos_sensor for select to authenticated using (true);
create policy "admin grava ciclos" on public.ciclos_sensor for all to authenticated
  using      ((auth.jwt() ->> 'email') = 'admin@lavanderia.app')
  with check ((auth.jwt() ->> 'email') = 'admin@lavanderia.app');

-- 3) Recuperação de senha (pedidos do morador + redefinição pelo síndico) -----
-- Como os e-mails (apto7@lavanderia.app) não existem de verdade, a recuperação
-- por e-mail do Supabase não funciona. Fluxo adotado:
--   morador  -> esqueci-senha.html cria um pedido (sem precisar estar logado)
--   síndico  -> admin-senhas.html vê os pedidos e gera uma senha temporária
--   morador  -> entra com a temporária e é obrigado a trocar (trocar_senha = true)
create table if not exists public.pedidos_senha (
  id          bigint generated always as identity primary key,
  apartamento int  not null check (apartamento between 1 and 42),
  contato     text check (contato is null or char_length(contato) <= 80),
  status      text not null default 'pendente' check (status in ('pendente','atendido','recusado')),
  criado_em   timestamptz not null default now(),
  atendido_em timestamptz
);
-- no máximo um pedido pendente por apartamento (evita spam)
create unique index if not exists pedido_senha_pendente_unico
  on public.pedidos_senha (apartamento) where status = 'pendente';

alter table public.pedidos_senha enable row level security;
drop policy if exists "morador pede senha"   on public.pedidos_senha;
drop policy if exists "admin le pedidos"     on public.pedidos_senha;
drop policy if exists "admin atualiza pedidos" on public.pedidos_senha;
create policy "morador pede senha" on public.pedidos_senha for insert to anon, authenticated
  with check (status = 'pendente' and atendido_em is null);
create policy "admin le pedidos" on public.pedidos_senha for select to authenticated
  using ((auth.jwt() ->> 'email') = 'admin@lavanderia.app');
create policy "admin atualiza pedidos" on public.pedidos_senha for update to authenticated
  using      ((auth.jwt() ->> 'email') = 'admin@lavanderia.app')
  with check ((auth.jwt() ->> 'email') = 'admin@lavanderia.app');

-- Redefine a senha de um morador. Só o administrador consegue executar.
-- Roda como "security definer" para não precisar da chave service_role no navegador.
create or replace function public.admin_redefinir_senha(p_apartamento int, p_senha text)
returns void
language plpgsql
security definer
set search_path = public, extensions, auth
as $$
declare
  v_id uuid;
begin
  if (auth.jwt() ->> 'email') is distinct from 'admin@lavanderia.app' then
    raise exception 'Apenas o administrador pode redefinir senhas.' using errcode = '42501';
  end if;
  if p_apartamento is null or p_apartamento not between 1 and 42 then
    raise exception 'Apartamento inválido.';
  end if;
  if p_senha is null or char_length(p_senha) < 6 then
    raise exception 'A senha precisa ter pelo menos 6 caracteres.';
  end if;

  update auth.users
     set encrypted_password = crypt(p_senha, gen_salt('bf')),
         raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || '{"trocar_senha": true}'::jsonb,
         updated_at = now()
   where email = 'apto' || p_apartamento || '@lavanderia.app'
   returning id into v_id;

  if v_id is null then
    raise exception 'Usuário do apartamento % não encontrado em Authentication > Users.', p_apartamento;
  end if;

  delete from auth.sessions where user_id = v_id;   -- encerra logins antigos

  update public.pedidos_senha
     set status = 'atendido', atendido_em = now()
   where apartamento = p_apartamento and status = 'pendente';
end;
$$;
revoke all on function public.admin_redefinir_senha(int, text) from public, anon;
grant execute on function public.admin_redefinir_senha(int, text) to authenticated;

-- Lista os 42 apartamentos com a situação de acesso (só o administrador).
-- Lê auth.users por "security definer"; o navegador nunca recebe a chave service_role.
create or replace function public.admin_listar_moradores()
returns table (
  apto          int,
  existe        boolean,
  ultimo_acesso timestamptz,
  trocar_senha  boolean,
  pedido_id     bigint,
  contato       text,
  pedido_em     timestamptz
)
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if (auth.jwt() ->> 'email') is distinct from 'admin@lavanderia.app' then
    raise exception 'Apenas o administrador pode listar moradores.' using errcode = '42501';
  end if;
  return query
    select g.n,
           u.id is not null,
           u.last_sign_in_at,
           coalesce((u.raw_user_meta_data ->> 'trocar_senha') = 'true', false),
           p.id,
           p.contato,
           p.criado_em
      from generate_series(1, 42) as g(n)
      left join auth.users u on u.email = 'apto' || g.n || '@lavanderia.app'
      left join public.pedidos_senha p on p.apartamento = g.n and p.status = 'pendente'
     order by g.n;
end;
$$;
revoke all on function public.admin_listar_moradores() from public, anon;
grant execute on function public.admin_listar_moradores() to authenticated;
