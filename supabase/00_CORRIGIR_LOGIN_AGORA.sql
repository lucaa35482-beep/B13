-- ============================================================
-- FAC B13 • CORREÇÃO IMEDIATA DO LOGIN
-- Corrige o erro: function digest(text, unknown) does not exist
-- NÃO apaga contas, entregas, avisos ou dados existentes.
-- Execute TODO este arquivo no Supabase > SQL Editor > Run.
-- ============================================================

create schema if not exists extensions;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pgcrypto') then
    begin
      execute 'alter extension pgcrypto set schema extensions';
    exception when others then
      null;
    end;
  else
    execute 'create extension pgcrypto with schema extensions';
  end if;
end $$;

create or replace function public.b13_login(p_email text,p_password text)
returns jsonb
language plpgsql
security definer
set search_path=public,extensions,pg_temp
as $$
declare
  a public.b13_accounts;
  t uuid;
  calc text;
begin
  select * into a
  from public.b13_accounts
  where lower(email)=lower(trim(p_email))
  limit 1;

  if a.id is null then
    raise exception 'B13: E-mail ou senha inválidos.';
  end if;

  calc := encode(
    extensions.digest(
      convert_to(coalesce(p_password,'') || a.password_salt, 'UTF8'),
      'sha256'
    ),
    'hex'
  );

  if calc <> a.password_hash then
    raise exception 'B13: E-mail ou senha inválidos.';
  end if;

  if not a.approved then
    raise exception 'B13: Seu cadastro ainda aguarda aprovação da liderança.';
  end if;

  if a.status <> 'ativo' then
    raise exception 'B13: Sua conta está desativada.';
  end if;

  delete from public.b13_sessions
  where account_id=a.id and expires_at<=now();

  insert into public.b13_sessions(account_id)
  values(a.id)
  returning token into t;

  return jsonb_build_object(
    'token',t::text,
    'id',a.id,
    'name',a.name,
    'rp_id',a.rp_id,
    'discord',a.discord,
    'email',a.email,
    'role',a.role::text,
    'approved',a.approved,
    'status',a.status::text
  );
end $$;

create or replace function public.b13_register(
  p_name text,
  p_rp_id text,
  p_discord text,
  p_email text,
  p_password text
)
returns jsonb
language plpgsql
security definer
set search_path=public,extensions,pg_temp
as $$
declare
  salt text;
  h text;
begin
  if length(trim(coalesce(p_name,'')))<2 then
    raise exception 'B13: Informe o nome do personagem.';
  end if;
  if length(trim(coalesce(p_rp_id,'')))<1 then
    raise exception 'B13: Informe o ID do RP.';
  end if;
  if position('@' in coalesce(p_email,''))<2 then
    raise exception 'B13: Informe um e-mail válido.';
  end if;
  if length(coalesce(p_password,''))<6 then
    raise exception 'B13: A senha precisa ter no mínimo 6 caracteres.';
  end if;
  if exists(select 1 from public.b13_accounts where lower(email)=lower(trim(p_email))) then
    raise exception 'B13: Este e-mail já está cadastrado.';
  end if;
  if exists(select 1 from public.b13_accounts where rp_id=trim(p_rp_id)) then
    raise exception 'B13: Este ID do RP já está cadastrado.';
  end if;

  salt := encode(extensions.gen_random_bytes(16),'hex');
  h := encode(
    extensions.digest(convert_to(p_password || salt,'UTF8'),'sha256'),
    'hex'
  );

  insert into public.b13_accounts(
    name,rp_id,discord,email,password_salt,password_hash,role,approved,status
  ) values(
    trim(p_name),trim(p_rp_id),nullif(trim(p_discord),''),lower(trim(p_email)),
    salt,h,'membro',false,'ativo'
  );

  return jsonb_build_object(
    'ok',true,
    'message','Cadastro criado! Agora aguarde a aprovação da liderança.'
  );
end $$;

grant execute on function public.b13_login(text,text) to anon,authenticated;
grant execute on function public.b13_register(text,text,text,text,text) to anon,authenticated;

-- Testes finais. O resultado deve mostrar LOGIN_OK e HASH_OK.
select
  case when to_regprocedure('public.b13_login(text,text)') is not null then 'LOGIN_OK' else 'LOGIN_ERRO' end as login,
  case when encode(extensions.digest(convert_to('teste','UTF8'),'sha256'),'hex') is not null then 'HASH_OK' else 'HASH_ERRO' end as hash;
