select 'conta_lider' as teste, case when exists(select 1 from public.b13_accounts where lower(email)='lucaa3548@gmail.com' and role='lider' and approved and status='ativo') then 'OK' else 'ERRO' end as resultado;
select 'funcao_login' as teste, case when to_regprocedure('public.b13_login(text,text)') is not null then 'OK' else 'ERRO' end as resultado;
select 'funcao_cadastro' as teste, case when to_regprocedure('public.b13_register(text,text,text,text,text)') is not null then 'OK' else 'ERRO' end as resultado;
