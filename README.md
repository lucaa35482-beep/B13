# FAC B13 — versão final sem confirmação de e-mail

Esta versão remove a dependência do Supabase Auth. O Supabase é usado como banco + RPC seguro. Isso elimina o erro `email rate limit exceeded`.

## Instalação
1. Supabase > SQL Editor > New query.
2. Cole TODO o arquivo `supabase/01_INSTALAR_B13_SEM_EMAIL.sql` e clique em Run.
3. No GitHub, substitua o projeto pelos arquivos desta pasta.
4. O Vercel fará o deploy Vite automaticamente. Se necessário, faça Redeploy sem cache.
5. Abra o domínio e entre pela aba **Entrar**. A conta principal da liderança já é criada pelo SQL.

## Importante
- A senha da conta principal não está escrita em texto aberto no frontend ou no SQL; o banco recebe apenas um hash pré-calculado.
- Novos membros podem usar a aba **Cadastrar** sem receber e-mail. Eles ficam aguardando aprovação da liderança.
- A Publishable key do Supabase é pública por definição. Não use `service_role` no frontend.
