# FAC B13 — Vercel + Supabase (variáveis de ambiente)

Esta versão NÃO possui URL nem chave do Supabase gravadas no código.
O Vercel injeta as configurações no build através das variáveis de ambiente.

## 1. Supabase — instalar o banco do zero
1. Abra Supabase > SQL Editor > New query.
2. Abra `supabase/INSTALAR_DO_ZERO.sql` deste projeto.
3. Copie TODO o conteúdo, cole no SQL Editor e clique em Run.
4. O script apaga/recria somente as estruturas B13: profiles, deliveries, notices, admin_logs, tipos, funções, triggers e policies B13.

## 2. Vercel — variáveis de ambiente
No projeto B13: Settings / Configurações > Environment Variables / Variáveis Ambientais.

Crie exatamente:

- `VITE_SUPABASE_URL`
  - Valor: sua Project URL, SEM `/rest/v1/`.
  - Exemplo: `https://xxxxxxxxxxxxxxxxxxxx.supabase.co`

- `VITE_SUPABASE_ANON_KEY`
  - Valor: sua `Publishable key` (começa com `sb_publishable_...`).
  - NÃO use Secret key nem service_role.

Marque Production, Preview e Development e salve.

## 3. GitHub / Vercel
1. Envie TODOS os arquivos deste projeto para o repositório GitHub (extraídos; não envie apenas o ZIP).
2. O Vercel detectará Vite automaticamente.
3. Framework Preset: Vite.
4. Build Command: `npm run build` (normalmente automático).
5. Output Directory: `dist` (normalmente automático).
6. Depois de criar/alterar variáveis, faça um novo Deploy/Redeploy.

## 4. URL do Vercel no Supabase
Supabase > Authentication > URL Configuration:
- Site URL: sua URL principal do Vercel.
- Redirect URLs: `https://SEU-SITE.vercel.app/**`

## 5. Criar o primeiro líder
1. Cadastre sua conta pelo próprio site B13.
2. Se a confirmação de e-mail estiver ativada, confirme seu e-mail antes do primeiro login.
3. No Supabase SQL Editor, abra `supabase/PROMOVER_PRIMEIRO_LIDER.sql`.
4. Troque `SEU_EMAIL_AQUI` pelo e-mail usado no cadastro (nas duas ocorrências).
5. Clique em Run.
6. Faça login novamente: contas com cargo `lider`, `sub_lider` ou `gerente` são encaminhadas ao painel da Liderança; membros comuns vão ao painel do Membro.

## Regras B13 configuradas no banco
- Meta diária: 1.000 folhas
- 1 folha = 3 kits
- Cálculo-base: $300 por kit
- Membro: 20%
- FAC B13: 80%
- Venda para membros: $280 por unidade
- Venda para público/não membros: $300 por unidade

## Segurança
- O navegador recebe apenas a Publishable key.
- As regras RLS do Supabase limitam o que membros e liderança podem ler/alterar.
- Nunca publique `secret key` ou `service_role` no GitHub, Vercel client-side ou arquivos JS.
