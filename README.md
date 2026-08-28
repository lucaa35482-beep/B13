FAC B13 — REVISÃO TOTAL

1. No Supabase > SQL Editor, execute TODO o arquivo supabase/01_REINSTALAR_B13_COMPLETO.sql.
2. Depois execute supabase/02_TESTAR_INSTALACAO.sql. Os 3 resultados devem ser OK.
3. No GitHub, substitua TODO o conteúdo antigo pelos arquivos desta pasta. Não misture versões antigas.
4. Aguarde o Vercel concluir o deploy da main.
5. Abra o domínio de produção e faça Ctrl+F5 uma vez.

Revisado nesta versão:
- removido header Authorization: Bearer com sb_publishable_ (erro importante da versão anterior);
- removida qualquer referência a B13_CONFIGURED;
- corrigidos IDs do DOM que dependiam de variáveis globais implícitas;
- login e cadastro mostram erro na própria tela e bloqueiam o botão enquanto processam;
- cache de JS/HTML desativado e scripts versionados;
- SQL único de reinstalação e SQL separado para conferir a instalação.
