-- FAC B13 • GARANTIR CONTA PRINCIPAL COMO LÍDER
-- Execute depois que a conta lucaa3548@gmail.com existir no Authentication.

update public.profiles p
set approved=true, role='lider', status='ativo', updated_at=now()
from auth.users u
where p.id=u.id and lower(u.email)=lower('lucaa3548@gmail.com');

select p.name,p.rp_id,p.discord,p.role,p.approved,p.status,u.email
from public.profiles p
join auth.users u on u.id=p.id
where lower(u.email)=lower('lucaa3548@gmail.com');
