-- Rode SOMENTE depois de criar sua conta pelo site.
-- Troque o e-mail abaixo pelo e-mail cadastrado e clique em Run.

update public.profiles p
set approved = true,
    role = 'lider',
    status = 'ativo',
    updated_at = now()
from auth.users u
where p.id = u.id
  and lower(u.email) = lower('SEU_EMAIL_AQUI');

-- Conferência:
select p.name, p.rp_id, u.email, p.role, p.approved, p.status
from public.profiles p
join auth.users u on u.id = p.id
where lower(u.email) = lower('SEU_EMAIL_AQUI');
