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
