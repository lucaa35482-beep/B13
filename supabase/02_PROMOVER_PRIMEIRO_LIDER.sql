-- FAC B13 • PROMOVER A PRIMEIRA CONTA PARA LÍDER
-- 1) Cadastre sua conta normalmente no site.
-- 2) Troque o e-mail abaixo pelo mesmo e-mail usado no cadastro.
-- 3) Execute este comando no Supabase > SQL Editor.

update public.profiles p
set
  approved = true,
  role = 'lider',
  status = 'ativo',
  updated_at = now()
from auth.users u
where p.id = u.id
  and lower(u.email) = lower('SEU_EMAIL@EXEMPLO.COM');

-- Confere o resultado sem mostrar senha ou segredo:
select p.name, p.rp_id, p.discord, p.role, p.approved, p.status, u.email
from public.profiles p
join auth.users u on u.id = p.id
where lower(u.email) = lower('SEU_EMAIL@EXEMPLO.COM');
