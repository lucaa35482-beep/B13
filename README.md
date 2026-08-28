# FAC B13 — versão corrigida

## Se o banco já está instalado
No Supabase > SQL Editor, execute **somente** `supabase/00_CORRIGIR_LOGIN_AGORA.sql`.
Ele corrige o erro `function digest(text, unknown) does not exist` sem apagar os dados.

Depois atualize a página do site com `Ctrl + F5` e tente entrar novamente.

## Instalação do zero
Se quiser zerar toda a B13, execute `supabase/01_REINSTALAR_B13_COMPLETO.sql`.
Depois execute `supabase/02_TESTAR_INSTALACAO.sql`.

## Importante
A Publishable Key é usada apenas no frontend. Nunca coloque `service_role` ou Secret Key no site.
