# FAC B13 — versão estática final

Esta versão não usa Vite, npm, variáveis do Vercel nem Supabase Auth.
O navegador chama as RPCs do Supabase diretamente via REST usando somente a Publishable Key.

## Instalação
1. Supabase > SQL Editor: execute `supabase/01_INSTALAR_B13_SEM_EMAIL.sql` inteiro uma vez.
2. Publique TODOS os arquivos desta pasta no GitHub/Vercel.
3. No Vercel não configure Build Command; o projeto é estático.
4. Abra o site e entre com a conta principal criada pelo SQL.

Se o SQL já foi executado com sucesso antes, não precisa rodá-lo de novo.
