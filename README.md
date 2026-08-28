# FAC B13 — versão corrigida

Esta versão corrige o problema em que as abas **Entrar/Cadastrar** apareciam na tela, mas não respondiam ao clique depois do deploy no Vercel.

## O que foi corrigido
O Vite não estava levando `auth.js`, `member.js` e `leader.js` para o `dist` porque eles eram carregados dinamicamente. Agora esses arquivos ficam também em `public/js/`, então o Vercel os publica corretamente.

## Supabase
A URL pública e a Publishable key já estão configuradas em `js/bootstrap.js`.
Nunca use uma chave `service_role`/secret no frontend.

## Publicação
1. Substitua os arquivos do repositório pelos desta versão.
2. Faça commit na branch `main`.
3. Aguarde o Vercel criar um novo deploy ou faça Redeploy sem cache.
4. Abra o domínio principal e use Ctrl+F5.
5. Rode `supabase/01_RESET_E_INSTALAR_B13.sql` apenas se quiser reinstalar o banco B13 do zero.
