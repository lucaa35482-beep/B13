-- ============================================================
-- FAC B13 • INSTALAÇÃO LIMPA / REINSTALAÇÃO SUPABASE
-- ATENÇÃO: este script APAGA e recria somente as estruturas B13
-- (profiles, deliveries, notices, admin_logs e tipos/funções B13).
-- Use agora para corrigir instalação parcial / erro "already exists".
-- Execute o arquivo INTEIRO no Supabase > SQL Editor > Run.
-- ============================================================

-- 0) LIMPEZA SEGURA DAS ESTRUTURAS B13
-- Remove primeiro o trigger no Auth para ele não apontar para função/tabela antiga.
drop trigger if exists on_auth_user_created on auth.users;

-- Tabelas B13 (CASCADE remove policies, triggers e dependências dessas tabelas).
drop table if exists public.admin_logs cascade;
drop table if exists public.notices cascade;
drop table if exists public.deliveries cascade;
drop table if exists public.profiles cascade;

-- Funções B13.
drop function if exists public.normalize_delivery_values() cascade;
drop function if exists public.handle_new_user() cascade;
drop function if exists public.is_approved_user() cascade;
drop function if exists public.is_leadership() cascade;
drop function if exists public.get_b13_daily_progress() cascade;
drop function if exists public.get_b13_ranking() cascade;

-- Tipos B13.
drop type if exists public.payment_status cascade;
drop type if exists public.b13_status cascade;
drop type if exists public.b13_role cascade;

-- 1) EXTENSÃO E TIPOS
create extension if not exists pgcrypto;

create type public.b13_role as enum ('membro','recrutador','gerente','sub_lider','lider');
create type public.b13_status as enum ('ativo','inativo');
create type public.payment_status as enum ('pendente','pago');

-- 2) TABELAS
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  rp_id text not null unique,
  discord text,
  role public.b13_role not null default 'membro',
  approved boolean not null default false,
  status public.b13_status not null default 'ativo',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.deliveries (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.profiles(id) on delete cascade,
  leaves integer not null check (leaves > 0),
  kits integer not null check (kits > 0),
  gross_amount numeric(14,2) not null default 0 check (gross_amount >= 0),
  member_amount numeric(14,2) not null default 0 check (member_amount >= 0),
  org_amount numeric(14,2) not null default 0 check (org_amount >= 0),
  payment_status public.payment_status not null default 'pendente',
  paid_at timestamptz,
  paid_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.notices (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  important boolean not null default false,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.admin_logs (
  id bigint generated always as identity primary key,
  action text not null,
  actor_id uuid references public.profiles(id),
  actor_name text,
  target_user_id uuid references public.profiles(id),
  delivery_id uuid references public.deliveries(id),
  created_at timestamptz not null default now()
);

create index deliveries_member_idx on public.deliveries(member_id);
create index deliveries_payment_idx on public.deliveries(payment_status);
create index profiles_approved_idx on public.profiles(approved);

-- 3) CÁLCULO AUTOMÁTICO DA ENTREGA
-- 1 folha = 3 kits | $300 por kit | membro 20% | FAC B13 80%
create or replace function public.normalize_delivery_values()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  new.kits := new.leaves * 3;
  new.gross_amount := new.kits * 300;
  new.member_amount := new.gross_amount * 0.20;
  new.org_amount := new.gross_amount * 0.80;
  if tg_op = 'INSERT' then
    new.payment_status := 'pendente';
    new.paid_at := null;
    new.paid_by := null;
  end if;
  return new;
end;
$$;

create trigger normalize_delivery_before_write
before insert on public.deliveries
for each row execute procedure public.normalize_delivery_values();

-- 4) CRIA O PERFIL AUTOMATICAMENTE APÓS CADASTRO NO AUTH
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- A conta principal da liderança já nasce aprovada como líder.
  if lower(coalesce(new.email,'')) = lower('lucaa3548@gmail.com') then
    insert into public.profiles (id,name,rp_id,discord,role,approved,status)
    values (
      new.id,
      coalesce(new.raw_user_meta_data->>'name','Lucas'),
      coalesce(new.raw_user_meta_data->>'rp_id','866'),
      new.raw_user_meta_data->>'discord',
      'lider',
      true,
      'ativo'
    );
  else
    insert into public.profiles (id,name,rp_id,discord)
    values (
      new.id,
      coalesce(new.raw_user_meta_data->>'name','Novo membro'),
      coalesce(new.raw_user_meta_data->>'rp_id',new.id::text),
      new.raw_user_meta_data->>'discord'
    );
  end if;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- 5) FUNÇÕES DE PERMISSÃO
create or replace function public.is_approved_user()
returns boolean
language sql stable security definer
set search_path=public
as $$
  select exists(
    select 1 from public.profiles p
    where p.id=auth.uid() and p.approved=true and p.status='ativo'
  )
$$;

create or replace function public.is_leadership()
returns boolean
language sql stable security definer
set search_path=public
as $$
  select exists(
    select 1 from public.profiles p
    where p.id=auth.uid()
      and p.approved=true
      and p.status='ativo'
      and p.role in ('gerente','sub_lider','lider')
  )
$$;

-- 6) RANKING / PROGRESSO
create or replace function public.get_b13_daily_progress()
returns table(member_id uuid, member_name text, total_leaves bigint)
language sql stable security definer
set search_path=public
as $$
  select p.id, p.name,
         coalesce(sum(d.leaves) filter (
           where timezone('America/Sao_Paulo',d.created_at)::date =
                 timezone('America/Sao_Paulo',now())::date
         ),0)::bigint
  from public.profiles p
  left join public.deliveries d on d.member_id=p.id
  where p.approved=true and p.status='ativo'
  group by p.id,p.name
  order by 3 desc, p.name;
$$;

create or replace function public.get_b13_ranking()
returns table(member_id uuid, member_name text, total_leaves bigint, total_deliveries bigint)
language sql stable security definer
set search_path=public
as $$
  select p.id, p.name,
         coalesce(sum(d.leaves),0)::bigint,
         count(d.id)::bigint
  from public.profiles p
  left join public.deliveries d on d.member_id=p.id
  where p.approved=true and p.status='ativo'
  group by p.id,p.name
  order by coalesce(sum(d.leaves),0) desc, p.name;
$$;

grant execute on function public.get_b13_daily_progress() to authenticated;
grant execute on function public.get_b13_ranking() to authenticated;

-- 7) RLS
alter table public.profiles enable row level security;
alter table public.deliveries enable row level security;
alter table public.notices enable row level security;
alter table public.admin_logs enable row level security;

-- PROFILES
create policy "profile read own"
on public.profiles for select to authenticated
using (id=auth.uid());

create policy "leadership read all profiles"
on public.profiles for select to authenticated
using (public.is_leadership());

create policy "leadership update profiles"
on public.profiles for update to authenticated
using (public.is_leadership())
with check (public.is_leadership());

-- DELIVERIES
create policy "member read own deliveries"
on public.deliveries for select to authenticated
using (member_id=auth.uid() or public.is_leadership());

create policy "member insert own deliveries"
on public.deliveries for insert to authenticated
with check (member_id=auth.uid() and public.is_approved_user());

create policy "leadership update deliveries"
on public.deliveries for update to authenticated
using (public.is_leadership())
with check (public.is_leadership());

-- AVISOS
create policy "approved users read notices"
on public.notices for select to authenticated
using (public.is_approved_user());

create policy "leadership insert notices"
on public.notices for insert to authenticated
with check (public.is_leadership());

create policy "leadership update notices"
on public.notices for update to authenticated
using (public.is_leadership())
with check (public.is_leadership());

create policy "leadership delete notices"
on public.notices for delete to authenticated
using (public.is_leadership());

-- LOGS
create policy "leadership read logs"
on public.admin_logs for select to authenticated
using (public.is_leadership());

create policy "leadership insert logs"
on public.admin_logs for insert to authenticated
with check (public.is_leadership());

-- 8) PERMISSÕES DE TABELA
grant select on public.profiles to authenticated;
grant update(role,approved,status,updated_at) on public.profiles to authenticated;
grant select,insert on public.deliveries to authenticated;
grant update(payment_status,paid_at,paid_by) on public.deliveries to authenticated;
grant select,insert,update,delete on public.notices to authenticated;
grant select,insert on public.admin_logs to authenticated;
grant usage, select on sequence public.admin_logs_id_seq to authenticated;

-- ============================================================
-- PRONTO.
-- Depois:
-- 1) Cadastre a sua conta normalmente pelo site B13.
-- 2) Volte ao SQL Editor e rode SOMENTE o UPDATE abaixo,
--    trocando o e-mail pelo e-mail usado no seu cadastro:
--
-- update public.profiles p
-- set approved=true, role='lider', status='ativo', updated_at=now()
-- from auth.users u
-- where p.id=u.id and u.email='SEU_EMAIL@EXEMPLO.COM';
--
-- 3) Entre novamente no site. Sua conta abrirá o Painel da Liderança.
-- ============================================================

-- ============================================================
-- OBSERVAÇÃO DE AUTENTICAÇÃO
-- Se você não quiser confirmação de e-mail durante os testes:
-- Supabase > Authentication > Providers > Email
-- desative "Confirm email" temporariamente.
-- ============================================================
