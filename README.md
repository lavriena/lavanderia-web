# Lavanderia coletiva – agendamento e painel

Projeto Integrador em Computação IV (Univesp) – protótipo web de uma lavanderia coletiva predial
(2 lavadoras e 2 secadoras para 42 apartamentos).

## O que o app faz
- **Agendar:** reservas em blocos de 1 hora (8h às 21h); só quem reservou pode cancelar.
- **IoT simulado:** gera 120 dias de ciclos de uso, descartando leituras inválidas.
- **Aprendizagem de máquina:** regressão linear e Random Forest, com MAE e RMSE no conjunto de teste.
- **Painel:** mapa de calor, ocupação por máquina e os 5 próximos horários de pico previstos.

> O app funciona de dois modos: **demonstração** (sem banco; reservas só no navegador) e **conectado ao
> Supabase** (reservas e ciclos de sensor salvos no banco, compartilhados entre todos os moradores).
> Sem configurar o Supabase ele abre em modo demonstração.

## Ligar ao Supabase
1. No painel do Supabase, abra **SQL Editor → New query**, cole o conteúdo de `banco.sql` e clique em **Run**.
   Isso cria as tabelas `reservas` e `ciclos_sensor` com as regras de segurança (RLS): qualquer morador logado
   lê as reservas, só quem reservou cancela, e só o administrador grava os ciclos simulados.
2. Em **Authentication → Users**, os moradores entram com e-mail `apto{N}@lavanderia.app` (ex.: `apto7@lavanderia.app`)
   e a senha inicial padrão. Para forçar a troca no primeiro acesso, crie o usuário com
   `user_metadata = {"trocar_senha": true}`. O administrador é `admin@lavanderia.app`.
   Se os seus usuários já existem com outro formato de e-mail, ajuste `dominio` (e a função `emailDe`) no `index.html`.
3. Em **Project Settings → API**, copie a **Project URL** e a chave **anon / public** e cole no início do script,
   no objeto `CFG`, no `index.html`:
   ```js
   const CFG={url:'https://SEU-PROJETO.supabase.co',key:'SUA_CHAVE_ANON',dominio:'lavanderia.app'};
   ```
   Use **somente** a chave anon (pública). **Nunca** coloque a chave `service_role` nesta página.
4. Entre como `admin` (senha do admin) e, na aba **Painel**, clique em **Gerar e salvar dados simulados**.
   A partir daí o painel lê os ciclos direto do banco.

## Como rodar localmente
Abra o arquivo `index.html` no navegador. Não precisa instalar nada.

## Como publicar no GitHub
1. Crie um repositório vazio em https://github.com/new (ex.: `lavanderia-pi`).
2. Na pasta do projeto, rode:
```bash
git init
git add .
git commit -m "Primeira versão do app da lavanderia"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/lavanderia-pi.git
git push -u origin main
```
(Ou envie os arquivos pelo botão **Add file → Upload files** no site do GitHub.)

## Como publicar na Vercel
1. Acesse https://vercel.com e entre com sua conta do GitHub.
2. Clique em **Add New → Project** e escolha o repositório `lavanderia-pi`.
3. Em *Framework Preset* deixe **Other**. Não há comando de build nem pasta de saída.
4. Clique em **Deploy**. O endereço (algo como `lavanderia-pi.vercel.app`) é o link da aplicação
   para colocar no relatório.

Cada `git push` na branch `main` publica a nova versão automaticamente.

## Estrutura
```
index.html   # aplicação completa (HTML, CSS e JavaScript)
banco.sql    # tabelas e regras de segurança do Supabase
README.md
.gitignore
```
