# FAC B13 — acesso da liderança preparado

Projeto configurado com Supabase e com o e-mail principal da liderança **lucaa3548@gmail.com** já preenchido na tela de acesso.

## Importante sobre a senha
A senha **não foi colocada dentro dos arquivos públicos do site**. Se ela fosse gravada no JavaScript/HTML, qualquer pessoa conseguiria vê-la pelo navegador.

## Instalação limpa
1. No Supabase > SQL Editor, execute `supabase/01_RESET_E_INSTALAR_B13.sql`.
2. Publique estes arquivos no GitHub/Vercel.
3. Se a conta ainda não existir no Supabase Authentication, use a aba **Cadastrar** uma única vez com o e-mail principal e a sua senha. O trigger do banco já cria essa conta como `lider`, aprovada e ativa.
4. Depois disso, basta entrar normalmente; o sistema encaminha direto ao `leader.html`.
5. Se a conta já existia antes de rodar o SQL, execute `supabase/02_PROMOVER_PRIMEIRO_LIDER.sql` uma vez.

A URL e a Publishable key do Supabase já estão configuradas no frontend.
