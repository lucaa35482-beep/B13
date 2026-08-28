# FAC B13 — CORREÇÃO DEFINITIVA

Esta versão corrige o erro `B13_CONFIGURED is not defined` e força o navegador/Vercel a carregar os arquivos JS novos usando cache-busting.

## Instalação
1. No Supabase > SQL Editor, execute **uma vez** `supabase/01_INSTALAR_B13_SEM_EMAIL.sql`.
2. No GitHub, substitua TODO o conteúdo antigo do projeto pelo conteúdo desta pasta. Não misture arquivos de versões anteriores.
3. Faça commit na `main` e aguarde o Vercel publicar.
4. Abra o domínio de produção e use Ctrl+F5.

## Acesso principal
- E-mail: o e-mail de liderança já cadastrado no SQL.
- Senha: a senha definida para essa conta no SQL desta versão.

O login não usa Supabase Auth nem envio de e-mail; ele usa RPCs do banco.
