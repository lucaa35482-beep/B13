# FAC B13 • Configurações editáveis

Esta versão parte do sistema que já estava funcionando e adiciona edição das regras pela Central da Liderança.

## Atualização sem apagar dados
1. No Supabase > SQL Editor, execute **somente** `supabase/03_ATIVAR_CONFIGURACOES_EDITAVEIS.sql`.
2. Substitua os arquivos do site no GitHub pelos desta pasta e faça o deploy no Vercel.
3. Entre em **Liderança > Configurações**.

A liderança pode editar: meta diária, porcentagem do membro, porcentagem da FAC B13, venda para membro e venda para público.

Ao salvar, as novas entregas passam a usar as novas regras e todos os **pagamentos pendentes** são recalculados automaticamente. Pagamentos já marcados como **pago** não são alterados, preservando o histórico.

A conversão continua fixa em **1 folha = 3 kits**.
