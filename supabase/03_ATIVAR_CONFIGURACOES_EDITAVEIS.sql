-- ============================================================
-- FAC B13 • CONFIGURAÇÕES EDITÁVEIS
-- Execute UMA VEZ no Supabase > SQL Editor > Run.
-- NÃO apaga contas, entregas, pagamentos, avisos ou logs.
-- Depois publique os arquivos novos do site.
-- ============================================================

create table if not exists public.b13_settings (
  singleton boolean primary key default true check (singleton = true),
  daily_goal integer not null default 1000 check (daily_goal > 0),
  kits_per_leaf integer not null default 3 check (kits_per_leaf > 0),
  member_sale_price numeric(12,2) not null default 280 check (member_sale_price >= 0),
  public_price numeric(12,2) not null default 300 check (public_price >= 0),
  member_percent numeric(7,6) not null default 0.20 check (member_percent >= 0 and member_percent <= 1),
  org_percent numeric(7,6) not null default 0.80 check (org_percent >= 0 and org_percent <= 1),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.b13_accounts(id)
);

insert into public.b13_settings(singleton,daily_goal,kits_per_leaf,member_sale_price,public_price,member_percent,org_percent)
values(true,1000,3,280,300,0.20,0.80)
on conflict (singleton) do nothing;

alter table public.b13_settings enable row level security;
revoke all on public.b13_settings from anon, authenticated;

create or replace function public.b13_get_settings(p_token text)
returns jsonb
language plpgsql stable security definer
set search_path=public,extensions,pg_temp
as $$
declare s public.b13_settings;
begin
  perform public.b13_require_account(p_token);
  select * into s from public.b13_settings where singleton=true;
  return jsonb_build_object(
    'daily_goal',s.daily_goal,
    'kits_per_leaf',s.kits_per_leaf,
    'member_sale_price',s.member_sale_price,
    'public_price',s.public_price,
    'member_percent',s.member_percent,
    'org_percent',s.org_percent,
    'updated_at',s.updated_at
  );
end $$;

create or replace function public.b13_admin_update_settings(
  p_token text,
  p_daily_goal integer,
  p_member_percent numeric,
  p_org_percent numeric,
  p_member_sale_price numeric,
  p_public_price numeric
)
returns jsonb
language plpgsql security definer
set search_path=public,extensions,pg_temp
as $$
declare
  actor uuid;
  actor_name text;
  s public.b13_settings;
  changed_pending integer := 0;
begin
  actor := public.b13_require_leader(p_token);
  select name into actor_name from public.b13_accounts where id=actor;

  if p_daily_goal is null or p_daily_goal <= 0 then
    raise exception 'B13: A meta diária precisa ser maior que zero.';
  end if;
  if p_member_sale_price is null or p_member_sale_price < 0 or p_public_price is null or p_public_price < 0 then
    raise exception 'B13: Os preços não podem ser negativos.';
  end if;
  if p_member_percent is null or p_org_percent is null or p_member_percent < 0 or p_org_percent < 0 or p_member_percent > 1 or p_org_percent > 1 then
    raise exception 'B13: Porcentagem inválida.';
  end if;
  if abs((p_member_percent + p_org_percent) - 1) > 0.0001 then
    raise exception 'B13: As porcentagens do membro e da FAC precisam somar 100%%.';
  end if;

  update public.b13_settings
  set daily_goal=p_daily_goal,
      member_sale_price=round(p_member_sale_price,2),
      public_price=round(p_public_price,2),
      member_percent=p_member_percent,
      org_percent=p_org_percent,
      updated_at=now(),
      updated_by=actor
  where singleton=true
  returning * into s;

  -- Atualiza somente pagamentos ainda pendentes. Pagamentos já pagos ficam como histórico.
  update public.deliveries d
  set kits = d.leaves * s.kits_per_leaf,
      gross_amount = round((d.leaves * s.kits_per_leaf * s.public_price)::numeric,2),
      member_amount = round((d.leaves * s.kits_per_leaf * s.public_price * s.member_percent)::numeric,2),
      org_amount = round((d.leaves * s.kits_per_leaf * s.public_price * s.org_percent)::numeric,2)
  where d.payment_status='pendente';
  get diagnostics changed_pending = row_count;

  insert into public.admin_logs(action,actor_id,actor_name)
  values(
    'Configurações atualizadas: meta '||s.daily_goal||
    ', membro '||round(s.member_percent*100,2)||'%, FAC '||round(s.org_percent*100,2)||
    '%, venda membro $'||s.member_sale_price||', venda público $'||s.public_price||
    ' ('||changed_pending||' pagamentos pendentes recalculados)',
    actor,actor_name
  );

  return jsonb_build_object(
    'daily_goal',s.daily_goal,
    'kits_per_leaf',s.kits_per_leaf,
    'member_sale_price',s.member_sale_price,
    'public_price',s.public_price,
    'member_percent',s.member_percent,
    'org_percent',s.org_percent,
    'updated_at',s.updated_at,
    'pending_recalculated',changed_pending
  );
end $$;

-- Entregas novas passam a usar as regras salvas na Administração.
create or replace function public.b13_submit_delivery(p_token text,p_leaves integer)
returns jsonb language plpgsql security definer
set search_path=public,extensions,pg_temp
as $$
declare
  uid uuid;
  kits integer;
  gross numeric;
  rec numeric;
  org numeric;
  did uuid;
  a public.b13_accounts;
  s public.b13_settings;
begin
  uid:=public.b13_require_account(p_token);
  select * into a from public.b13_accounts where id=uid;
  if not a.approved or a.status<>'ativo' then raise exception 'B13: Conta sem permissão para registrar entrega.'; end if;
  if p_leaves is null or p_leaves<=0 then raise exception 'B13: Quantidade de folhas inválida.'; end if;

  select * into s from public.b13_settings where singleton=true;
  kits:=p_leaves*s.kits_per_leaf;
  gross:=round((kits*s.public_price)::numeric,2);
  rec:=round((gross*s.member_percent)::numeric,2);
  org:=round((gross*s.org_percent)::numeric,2);

  insert into public.deliveries(member_id,leaves,kits,gross_amount,member_amount,org_amount)
  values(uid,p_leaves,kits,gross,rec,org)
  returning id into did;

  return jsonb_build_object('id',did,'leaves',p_leaves,'kits',kits,'gross_amount',gross,'member_amount',rec,'org_amount',org);
end $$;

grant execute on function public.b13_get_settings(text) to anon,authenticated;
grant execute on function public.b13_admin_update_settings(text,integer,numeric,numeric,numeric,numeric) to anon,authenticated;
grant execute on function public.b13_submit_delivery(text,integer) to anon,authenticated;

select 'OK - configurações editáveis ativadas sem apagar dados.' as resultado;
