# FAC B13 — Projeto limpo (Vercel + Supabase)

Esta é a versão limpa do projeto. Ela **não usa `js/config.js`** e não possui URL antiga gravada no JavaScript.

## 1. Supabase — zerar e instalar
No Supabase, abra **SQL Editor > New query** e execute o arquivo inteiro:

`supabase/01_RESET_E_INSTALAR_B13.sql`

**Atenção:** esse script apaga e recria as tabelas/estruturas B13 (`profiles`, `deliveries`, `notices`, `admin_logs`). Use somente porque você decidiu refazer a B13 do zero.

Depois disso, cadastre a primeira conta pelo site. Para transformar essa conta em líder, abra:

`supabase/02_PROMOVER_PRIMEIRO_LIDER.sql`

Troque o e-mail de exemplo pelo e-mail usado no cadastro e execute.

## 2. Vercel — Variáveis de Ambiente
Em **Project > Settings > Environment Variables**, crie como tipo **Configuração**:

`VITE_SUPABASE_URL`

Valor:

`https://thcqeuhmrhzyssvemaer.supabase.co`

Depois:

`VITE_SUPABASE_ANON_KEY`

Valor:

`sb_publishable_92cmGjpVBye576YY5ee97g_PXUH9996`

Use em Production, Preview e Development se desejar. Após salvar, faça um **Redeploy**.

A chave acima é a **Publishable key**. Não coloque `service_role` ou Secret key no frontend.

## 3. GitHub/Vercel
Envie **os arquivos extraídos deste projeto** para o repositório conectado ao Vercel. Não envie apenas o ZIP para servir como site.

O Vercel executará:

`npm run build`

E publicará a pasta:

`dist`

## 4. Cadastro
O cadastro cria o usuário no Supabase Auth e o trigger cria automaticamente o registro em `public.profiles`. Novas contas começam aguardando aprovação.

Não existe login padrão gravado no código.
