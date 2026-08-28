# FAC B13 — versão final sem dependência de ENV

Esta versão já contém a URL pública correta do Supabase e a Publishable key no frontend.
Não é necessário cadastrar variáveis de ambiente no Vercel para o site funcionar.

## Supabase
1. Abra `supabase/01_RESET_E_INSTALAR_B13.sql`.
2. Cole no SQL Editor e execute uma vez para recriar a estrutura B13.
3. Cadastre a primeira conta pelo site.
4. Edite `supabase/02_PROMOVER_PRIMEIRO_LIDER.sql` com o e-mail da conta e execute.

## Vercel
Suba todos os arquivos deste projeto para o repositório e faça um novo deploy.
Framework: Vite
Build command: `npm run build`
Output: `dist`

A chave usada é do tipo Publishable (`sb_publishable_...`), adequada para frontend. Nunca use `service_role`/Secret key no navegador.
