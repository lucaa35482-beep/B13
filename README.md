# FAC B13 — Sistema de Membros e Farms

Projeto front-end pronto para subir no GitHub Pages.

## Incluído
- Login e cadastro de membros
- Aprovação de cadastro pela liderança
- Cargos: Membro, Recrutador, Gerente, Sub-Líder e Líder
- Entrega de farm com cálculo automático
- 1 folha = 3 kits
- Meta diária = 1.000 folhas
- Cálculo-base = $300 por kit
- Membro = 20%
- FAC B13 = 80%
- Venda para membros = $280/unidade
- Venda para público = $300/unidade
- Histórico de entregas
- Pagamentos pendentes/pagos
- Ranking
- Mural de avisos
- Painel da liderança
- Central de pagamentos
- Logs administrativos

## Contas de demonstração
- Líder: Lucas Monteiro / senha: 866
- Membro: João B13 / senha: 123

## Publicar no GitHub Pages
1. Extraia o ZIP.
2. Envie os arquivos para a raiz do seu repositório.
3. No GitHub, abra **Settings > Pages**.
4. Em **Build and deployment**, escolha **Deploy from a branch**.
5. Selecione a branch `main` e a pasta `/ (root)`.
6. Salve.

## Importante
Esta versão salva os dados no `localStorage` do navegador. Ela é ótima como protótipo/demonstração e para testar o layout.
Para vários usuários acessarem de computadores diferentes e compartilharem os mesmos dados, o próximo passo é conectar um backend/banco de dados, como Supabase, Firebase ou Node.js + PostgreSQL/MySQL.
