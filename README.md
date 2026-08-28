# FAC B13 — Projeto com Supabase

Esta versão tem **dois painéis realmente diferentes**:

- `member.html` — painel pessoal do membro.
- `leader.html` — central administrativa da liderança.

O login identifica o cargo no Supabase e abre o painel correto automaticamente.

## O que fica salvo no Supabase

- contas e autenticação (Supabase Auth)
- perfis de membros
- ID do RP, Discord, cargo e status
- aprovação de novos cadastros
- entregas de farm
- folhas, kits e cálculos financeiros
- pagamentos pendentes/pagos
- data e responsável pelo pagamento
- avisos da liderança
- logs administrativos
- ranking (calculado no banco)

## Regras já configuradas

- Meta diária: **1.000 folhas**
- 1 folha = **3 kits**
- Cálculo da meta: **$300 por kit**
- Membro: **20%**
- FAC B13: **80%**
- Venda para membros: **$280/unidade**
- Venda para público/não membros: **$300/unidade**

## Como ligar ao Supabase

### 1. Criar o projeto
Crie um projeto em Supabase.

### 2. Criar as tabelas e segurança
Abra **SQL Editor** no Supabase e execute todo o arquivo:

`supabase/schema.sql`

Ele cria tabelas, funções, trigger de cadastro e políticas RLS.

### 3. Colocar URL e chave pública
No Supabase, vá em **Project Settings > API** e copie:

- Project URL
- `anon` / public key

Abra `js/config.js` e substitua:

```js
SUPABASE_URL: "https://thcqehumrhyzssvemaer.supabase.co",
SUPABASE_ANON_KEY: "sb_publishable_92cmGjpVBye576YY5ee97g_PXUH9996"
```

**Nunca coloque a `service_role` no site ou no GitHub.**

### 4. Criar o primeiro líder
Faça seu cadastro normalmente pelo site. Depois, no SQL Editor, rode:

```sql
update public.profiles p
set approved=true, role='lider', status='ativo'
from auth.users u
where p.id=u.id and u.email='SEU_EMAIL@EXEMPLO.COM';
```

Troque o e-mail pelo e-mail usado no cadastro.

### 5. Publicar no GitHub Pages
Envie para a raiz do repositório:

- `index.html`
- `member.html`
- `leader.html`
- `styles.css`
- pasta `js`
- pasta `supabase`
- `README.md`

Depois: **GitHub > Settings > Pages > Deploy from a branch > main > /(root)**.

## Segurança

Os controles administrativos não são apenas escondidos na tela. O banco usa **Row Level Security (RLS)** para impedir que um membro comum consulte ou altere dados administrativos.

A chave `anon/public` pode ficar no front-end porque as permissões reais são aplicadas pelas políticas RLS. A chave `service_role` não pode ser exposta.


## Configuração já aplicada para o seu projeto

A Project URL já está preenchida em `js/config.js`:

`https://thcqehumrhyzssvemaer.supabase.co`

A Publishable key mostrada na captura estava abreviada com `...`, então o arquivo deixa um único campo para você colar a chave completa copiada pelo botão **Copy** do Supabase. Depois disso, não precisa alterar mais nada nesse arquivo.

## Correção para erro `b13_role already exists`
Se você já tentou executar o SQL antes e apareceu esse erro, use agora o arquivo `supabase/INSTALACAO_LIMPA.sql`. Ele remove somente as estruturas do sistema B13 e as recria na ordem correta. **Ele apaga dados B13 existentes**, então use para a instalação inicial/reinstalação.
