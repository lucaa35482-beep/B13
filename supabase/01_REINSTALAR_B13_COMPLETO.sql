-- ============================================================
-- FAC B13 • INSTALAÇÃO FINAL SEM SUPABASE AUTH
-- Não envia e-mail. Não usa confirmação por e-mail. Não sofre email rate limit.
-- ATENÇÃO: apaga e recria as estruturas B13 deste projeto.
-- Execute TODO este arquivo uma única vez no Supabase > SQL Editor > Run.
-- ============================================================

create extension if not exists pgcrypto;

-- LIMPEZA B13 ANTIGA
drop trigger if exists on_auth_user_created on auth.users;
drop table if exists public.b13_sessions cascade;
drop table if exists public.admin_logs cascade;
drop table if exists public.notices cascade;
drop table if exists public.deliveries cascade;
drop table if exists public.profiles cascade;
drop table if exists public.b13_accounts cascade;

do $$ begin execute 'drop type if exists public.payment_status cascade'; exception when others then null; end $$;
do $$ begin execute 'drop type if exists public.b13_status cascade'; exception when others then null; end $$;
do $$ begin execute 'drop type if exists public.b13_role cascade'; exception when others then null; end $$;

-- Remove funções B13 antigas/novas conhecidas
do $$ declare r record; begin
  for r in select p.oid::regprocedure as sig from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname like 'b13_%' loop
    execute 'drop function if exists '||r.sig||' cascade';
  end loop;
  for r in select p.oid::regprocedure as sig from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('normalize_delivery_values','handle_new_user','is_approved_user','is_leadership','get_b13_daily_progress','get_b13_ranking') loop
    execute 'drop function if exists '||r.sig||' cascade';
  end loop;
end $$;

create type public.b13_role as enum ('membro','recrutador','gerente','sub_lider','lider');
create type public.b13_status as enum ('ativo','inativo');
create type public.payment_status as enum ('pendente','pago');

create table public.b13_accounts (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  rp_id text not null unique,
  discord text,
  email text not null,
  password_salt text not null,
  password_hash text not null,
  role public.b13_role not null default 'membro',
  approved boolean not null default false,
  status public.b13_status not null default 'ativo',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index b13_accounts_email_lower_uidx on public.b13_accounts(lower(email));

create table public.b13_sessions (
  token uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.b13_accounts(id) on delete cascade,
  expires_at timestamptz not null default (now()+interval '30 days'),
  created_at timestamptz not null default now()
);
create index b13_sessions_account_idx on public.b13_sessions(account_id);
create index b13_sessions_expiry_idx on public.b13_sessions(expires_at);

create table public.deliveries (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.b13_accounts(id) on delete cascade,
  leaves integer not null check (leaves > 0),
  kits integer not null check (kits > 0),
  gross_amount numeric(14,2) not null check (gross_amount >= 0),
  member_amount numeric(14,2) not null check (member_amount >= 0),
  org_amount numeric(14,2) not null check (org_amount >= 0),
  payment_status public.payment_status not null default 'pendente',
  paid_at timestamptz,
  paid_by uuid references public.b13_accounts(id),
  created_at timestamptz not null default now()
);
create index deliveries_member_idx on public.deliveries(member_id);
create index deliveries_payment_idx on public.deliveries(payment_status);

create table public.notices (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  important boolean not null default false,
  created_by uuid references public.b13_accounts(id),
  created_at timestamptz not null default now()
);

create table public.admin_logs (
  id bigint generated always as identity primary key,
  action text not null,
  actor_id uuid references public.b13_accounts(id),
  actor_name text,
  target_user_id uuid references public.b13_accounts(id),
  delivery_id uuid references public.deliveries(id),
  created_at timestamptz not null default now()
);

-- Conta principal da liderança já pronta.
-- A senha NÃO está escrita em texto aberto aqui: abaixo há somente salt + hash.
insert into public.b13_accounts(name,rp_id,discord,email,password_salt,password_hash,role,approved,status)
values ('Lucas','866','luck_26','lucaa3548@gmail.com','11cc8190c4fa3aa66d7071ad9fa42a98','e7b403b486915cb171588b80d57b27fff04569db426c55c70950e8df1e20ec26','lider',true,'ativo');

-- Helpers internos
create or replace function public.b13_account_id(p_token text)
returns uuid language sql stable security definer set search_path=public,pg_temp as $$
  select s.account_id from public.b13_sessions s
  join public.b13_accounts a on a.id=s.account_id
  where s.token::text=p_token and s.expires_at>now() and a.status='ativo'
  limit 1
$$;

create or replace function public.b13_is_leader(p_token text)
returns boolean language sql stable security definer set search_path=public,pg_temp as $$
  select exists(select 1 from public.b13_accounts a where a.id=public.b13_account_id(p_token) and a.approved=true and a.status='ativo' and a.role in ('gerente','sub_lider','lider'))
$$;

create or replace function public.b13_require_account(p_token text)
returns uuid language plpgsql stable security definer set search_path=public,pg_temp as $$
declare v uuid; begin
  v:=public.b13_account_id(p_token);
  if v is null then raise exception 'B13: Sessão inválida ou expirada.'; end if;
  return v;
end $$;

create or replace function public.b13_require_leader(p_token text)
returns uuid language plpgsql stable security definer set search_path=public,pg_temp as $$
declare v uuid; begin
  v:=public.b13_require_account(p_token);
  if not public.b13_is_leader(p_token) then raise exception 'B13: Acesso restrito à liderança.'; end if;
  return v;
end $$;

-- LOGIN / CADASTRO
create or replace function public.b13_login(p_email text,p_password text)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare a public.b13_accounts; t uuid; calc text; begin
  select * into a from public.b13_accounts where lower(email)=lower(trim(p_email)) limit 1;
  if a.id is null then raise exception 'B13: E-mail ou senha inválidos.'; end if;
  calc:=encode(digest(coalesce(p_password,'')||a.password_salt,'sha256'),'hex');
  if calc<>a.password_hash then raise exception 'B13: E-mail ou senha inválidos.'; end if;
  if not a.approved then raise exception 'B13: Seu cadastro ainda aguarda aprovação da liderança.'; end if;
  if a.status<>'ativo' then raise exception 'B13: Sua conta está desativada.'; end if;
  delete from public.b13_sessions where account_id=a.id and expires_at<=now();
  insert into public.b13_sessions(account_id) values(a.id) returning token into t;
  return jsonb_build_object('token',t::text,'id',a.id,'name',a.name,'rp_id',a.rp_id,'discord',a.discord,'email',a.email,'role',a.role::text,'approved',a.approved,'status',a.status::text);
end $$;

create or replace function public.b13_register(p_name text,p_rp_id text,p_discord text,p_email text,p_password text)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare salt text; h text; begin
  if length(trim(coalesce(p_name,'')))<2 then raise exception 'B13: Informe o nome do personagem.'; end if;
  if length(trim(coalesce(p_rp_id,'')))<1 then raise exception 'B13: Informe o ID do RP.'; end if;
  if position('@' in coalesce(p_email,''))<2 then raise exception 'B13: Informe um e-mail válido.'; end if;
  if length(coalesce(p_password,''))<6 then raise exception 'B13: A senha precisa ter no mínimo 6 caracteres.'; end if;
  if exists(select 1 from public.b13_accounts where lower(email)=lower(trim(p_email))) then raise exception 'B13: Este e-mail já está cadastrado.'; end if;
  if exists(select 1 from public.b13_accounts where rp_id=trim(p_rp_id)) then raise exception 'B13: Este ID do RP já está cadastrado.'; end if;
  salt:=encode(gen_random_bytes(16),'hex');
  h:=encode(digest(p_password||salt,'sha256'),'hex');
  insert into public.b13_accounts(name,rp_id,discord,email,password_salt,password_hash,role,approved,status)
  values(trim(p_name),trim(p_rp_id),nullif(trim(p_discord),''),lower(trim(p_email)),salt,h,'membro',false,'ativo');
  return jsonb_build_object('ok',true,'message','Cadastro criado! Agora aguarde a aprovação da liderança.');
end $$;

create or replace function public.b13_logout(p_token text)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$ begin
  delete from public.b13_sessions where token::text=p_token; return true;
end $$;

create or replace function public.b13_me(p_token text)
returns jsonb language plpgsql stable security definer set search_path=public,pg_temp as $$
declare a public.b13_accounts; begin
  select * into a from public.b13_accounts where id=public.b13_require_account(p_token);
  return jsonb_build_object('id',a.id,'name',a.name,'rp_id',a.rp_id,'discord',a.discord,'email',a.email,'role',a.role::text,'approved',a.approved,'status',a.status::text,'created_at',a.created_at);
end $$;

-- MEMBRO
create or replace function public.b13_member_deliveries(p_token text)
returns table(id uuid,member_id uuid,leaves integer,kits integer,gross_amount numeric,member_amount numeric,org_amount numeric,payment_status text,paid_at timestamptz,created_at timestamptz)
language sql stable security definer set search_path=public,pg_temp as $$
  select d.id,d.member_id,d.leaves,d.kits,d.gross_amount,d.member_amount,d.org_amount,d.payment_status::text,d.paid_at,d.created_at
  from public.deliveries d where d.member_id=public.b13_require_account(p_token) order by d.created_at desc
$$;

create or replace function public.b13_submit_delivery(p_token text,p_leaves integer)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid; kits integer; gross numeric; rec numeric; org numeric; did uuid; a public.b13_accounts; begin
  uid:=public.b13_require_account(p_token); select * into a from public.b13_accounts where id=uid;
  if not a.approved or a.status<>'ativo' then raise exception 'B13: Conta sem permissão para registrar entrega.'; end if;
  if p_leaves is null or p_leaves<=0 then raise exception 'B13: Quantidade de folhas inválida.'; end if;
  kits:=p_leaves*3;gross:=kits*300;rec:=gross*0.20;org:=gross*0.80;
  insert into public.deliveries(member_id,leaves,kits,gross_amount,member_amount,org_amount) values(uid,p_leaves,kits,gross,rec,org) returning id into did;
  return jsonb_build_object('id',did,'leaves',p_leaves,'kits',kits,'gross_amount',gross,'member_amount',rec,'org_amount',org);
end $$;

create or replace function public.b13_ranking(p_token text)
returns table(member_id uuid,member_name text,total_leaves bigint,total_deliveries bigint)
language plpgsql stable security definer set search_path=public,pg_temp as $$ begin
  perform public.b13_require_account(p_token);
  return query select a.id,a.name,coalesce(sum(d.leaves),0)::bigint,count(d.id)::bigint from public.b13_accounts a left join public.deliveries d on d.member_id=a.id where a.approved=true and a.status='ativo' group by a.id,a.name order by coalesce(sum(d.leaves),0) desc,a.name;
end $$;

create or replace function public.b13_list_notices(p_token text)
returns table(id uuid,title text,body text,important boolean,created_at timestamptz)
language plpgsql stable security definer set search_path=public,pg_temp as $$ begin
  perform public.b13_require_account(p_token);
  return query select n.id,n.title,n.body,n.important,n.created_at from public.notices n order by n.created_at desc;
end $$;

-- ADMIN
create or replace function public.b13_admin_profiles(p_token text)
returns table(id uuid,name text,rp_id text,discord text,email text,role text,approved boolean,status text,created_at timestamptz)
language plpgsql stable security definer set search_path=public,pg_temp as $$ begin
  perform public.b13_require_leader(p_token);
  return query select a.id,a.name,a.rp_id,a.discord,a.email,a.role::text,a.approved,a.status::text,a.created_at from public.b13_accounts a order by a.created_at desc;
end $$;

create or replace function public.b13_admin_deliveries(p_token text)
returns table(id uuid,member_id uuid,member_name text,rp_id text,leaves integer,kits integer,gross_amount numeric,member_amount numeric,org_amount numeric,payment_status text,paid_at timestamptz,created_at timestamptz)
language plpgsql stable security definer set search_path=public,pg_temp as $$ begin
  perform public.b13_require_leader(p_token);
  return query select d.id,d.member_id,a.name,a.rp_id,d.leaves,d.kits,d.gross_amount,d.member_amount,d.org_amount,d.payment_status::text,d.paid_at,d.created_at from public.deliveries d join public.b13_accounts a on a.id=d.member_id order by d.created_at desc;
end $$;

create or replace function public.b13_admin_set_role(p_token text,p_account_id uuid,p_role text)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$ declare actor uuid; an text; begin
  actor:=public.b13_require_leader(p_token); select name into an from public.b13_accounts where id=actor;
  if p_role not in ('membro','recrutador','gerente','sub_lider','lider') then raise exception 'B13: Cargo inválido.'; end if;
  update public.b13_accounts set role=p_role::public.b13_role,updated_at=now() where id=p_account_id;
  insert into public.admin_logs(action,actor_id,actor_name,target_user_id) values('Cargo alterado para '||p_role,actor,an,p_account_id); return true;
end $$;

create or replace function public.b13_admin_set_status(p_token text,p_account_id uuid,p_status text)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$ declare actor uuid; an text; begin
  actor:=public.b13_require_leader(p_token); select name into an from public.b13_accounts where id=actor;
  if p_status not in ('ativo','inativo') then raise exception 'B13: Status inválido.'; end if;
  update public.b13_accounts set status=p_status::public.b13_status,updated_at=now() where id=p_account_id;
  if p_status='inativo' then delete from public.b13_sessions where account_id=p_account_id; end if;
  insert into public.admin_logs(action,actor_id,actor_name,target_user_id) values('Status alterado para '||p_status,actor,an,p_account_id); return true;
end $$;

create or replace function public.b13_admin_approve(p_token text,p_account_id uuid,p_approved boolean)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$ declare actor uuid; an text; begin
  actor:=public.b13_require_leader(p_token); select name into an from public.b13_accounts where id=actor;
  update public.b13_accounts set approved=p_approved,status=(case when p_approved then 'ativo'::public.b13_status else 'inativo'::public.b13_status end),updated_at=now() where id=p_account_id;
  insert into public.admin_logs(action,actor_id,actor_name,target_user_id) values(case when p_approved then 'Cadastro aprovado' else 'Cadastro recusado/desativado' end,actor,an,p_account_id); return true;
end $$;

create or replace function public.b13_admin_pay(p_token text,p_delivery_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$ declare actor uuid; an text; begin
  actor:=public.b13_require_leader(p_token); select name into an from public.b13_accounts where id=actor;
  update public.deliveries set payment_status='pago',paid_at=now(),paid_by=actor where id=p_delivery_id and payment_status='pendente';
  insert into public.admin_logs(action,actor_id,actor_name,delivery_id) values('Pagamento confirmado',actor,an,p_delivery_id); return true;
end $$;

create or replace function public.b13_admin_pay_all(p_token text)
returns integer language plpgsql security definer set search_path=public,pg_temp as $$ declare actor uuid; an text; n integer; begin
  actor:=public.b13_require_leader(p_token); select name into an from public.b13_accounts where id=actor;
  update public.deliveries set payment_status='pago',paid_at=now(),paid_by=actor where payment_status='pendente'; get diagnostics n=row_count;
  insert into public.admin_logs(action,actor_id,actor_name) values('Pagamentos pendentes confirmados em lote ('||n||')',actor,an); return n;
end $$;

create or replace function public.b13_admin_daily_progress(p_token text)
returns table(member_id uuid,member_name text,total_leaves bigint)
language plpgsql stable security definer set search_path=public,pg_temp as $$ begin
  perform public.b13_require_leader(p_token);
  return query select a.id,a.name,coalesce(sum(d.leaves) filter(where timezone('America/Sao_Paulo',d.created_at)::date=timezone('America/Sao_Paulo',now())::date),0)::bigint from public.b13_accounts a left join public.deliveries d on d.member_id=a.id where a.approved=true and a.status='ativo' group by a.id,a.name order by 3 desc,a.name;
end $$;

create or replace function public.b13_admin_ranking(p_token text)
returns table(member_id uuid,member_name text,total_leaves bigint,total_deliveries bigint)
language plpgsql stable security definer set search_path=public,pg_temp as $$ begin
  perform public.b13_require_leader(p_token);
  return query select a.id,a.name,coalesce(sum(d.leaves),0)::bigint,count(d.id)::bigint from public.b13_accounts a left join public.deliveries d on d.member_id=a.id where a.approved=true and a.status='ativo' group by a.id,a.name order by coalesce(sum(d.leaves),0) desc,a.name;
end $$;

create or replace function public.b13_admin_publish_notice(p_token text,p_title text,p_body text,p_important boolean default false)
returns uuid language plpgsql security definer set search_path=public,pg_temp as $$ declare actor uuid; an text; nid uuid; begin
  actor:=public.b13_require_leader(p_token); select name into an from public.b13_accounts where id=actor;
  if length(trim(coalesce(p_title,'')))<1 or length(trim(coalesce(p_body,'')))<1 then raise exception 'B13: Preencha título e mensagem.'; end if;
  insert into public.notices(title,body,important,created_by) values(trim(p_title),trim(p_body),coalesce(p_important,false),actor) returning id into nid;
  insert into public.admin_logs(action,actor_id,actor_name) values('Aviso publicado: '||trim(p_title),actor,an); return nid;
end $$;

create or replace function public.b13_admin_logs(p_token text)
returns table(id bigint,action text,actor_name text,created_at timestamptz)
language plpgsql stable security definer set search_path=public,pg_temp as $$ begin
  perform public.b13_require_leader(p_token);
  return query select l.id,l.action,l.actor_name,l.created_at from public.admin_logs l order by l.created_at desc limit 100;
end $$;

-- RLS: ninguém acessa tabelas diretamente. Toda operação passa pelas funções acima.
alter table public.b13_accounts enable row level security;
alter table public.b13_sessions enable row level security;
alter table public.deliveries enable row level security;
alter table public.notices enable row level security;
alter table public.admin_logs enable row level security;

revoke all on public.b13_accounts,public.b13_sessions,public.deliveries,public.notices,public.admin_logs from anon,authenticated;

-- Somente as RPCs públicas necessárias.
grant execute on function public.b13_login(text,text) to anon,authenticated;
grant execute on function public.b13_register(text,text,text,text,text) to anon,authenticated;
grant execute on function public.b13_logout(text) to anon,authenticated;
grant execute on function public.b13_me(text) to anon,authenticated;
grant execute on function public.b13_member_deliveries(text) to anon,authenticated;
grant execute on function public.b13_submit_delivery(text,integer) to anon,authenticated;
grant execute on function public.b13_ranking(text) to anon,authenticated;
grant execute on function public.b13_list_notices(text) to anon,authenticated;
grant execute on function public.b13_admin_profiles(text) to anon,authenticated;
grant execute on function public.b13_admin_deliveries(text) to anon,authenticated;
grant execute on function public.b13_admin_set_role(text,uuid,text) to anon,authenticated;
grant execute on function public.b13_admin_set_status(text,uuid,text) to anon,authenticated;
grant execute on function public.b13_admin_approve(text,uuid,boolean) to anon,authenticated;
grant execute on function public.b13_admin_pay(text,uuid) to anon,authenticated;
grant execute on function public.b13_admin_pay_all(text) to anon,authenticated;
grant execute on function public.b13_admin_daily_progress(text) to anon,authenticated;
grant execute on function public.b13_admin_ranking(text) to anon,authenticated;
grant execute on function public.b13_admin_publish_notice(text,text,text,boolean) to anon,authenticated;
grant execute on function public.b13_admin_logs(text) to anon,authenticated;

-- NÃO concedemos execute aos helpers internos diretamente.
revoke execute on function public.b13_account_id(text) from public,anon,authenticated;
revoke execute on function public.b13_is_leader(text) from public,anon,authenticated;
revoke execute on function public.b13_require_account(text) from public,anon,authenticated;
revoke execute on function public.b13_require_leader(text) from public,anon,authenticated;

select 'FAC B13 instalada com sucesso. Login do líder já está criado e não depende de e-mail.' as resultado;

-- Garantia extra para a API REST do Supabase.
grant usage on schema public to anon, authenticated;
