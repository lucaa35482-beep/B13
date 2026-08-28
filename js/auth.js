const tabs=document.querySelectorAll('.auth-tab');
tabs.forEach(btn=>btn.addEventListener('click',()=>{
  tabs.forEach(x=>x.classList.remove('active'));btn.classList.add('active');
  document.getElementById('loginForm').classList.toggle('hidden',btn.dataset.tab!=='login');
  document.getElementById('registerForm').classList.toggle('hidden',btn.dataset.tab!=='register');
}));

if(window.B13_CONFIGURED) document.getElementById('setupWarning').classList.add('hidden');

function message(id,text,type='info'){
  const el=document.getElementById(id);el.className='message '+type;el.textContent=text;
}

async function routeLoggedUser(){
  if(!B13_CONFIGURED) return;
  const {data:{session}}=await b13.auth.getSession();
  if(!session) return;
  const {data:p}=await b13.from('profiles').select('role,approved,status').eq('id',session.user.id).single();
  if(!p || !p.approved || p.status!=='ativo') return;
  const leadership=['gerente','sub_lider','lider'];
  location.href=leadership.includes(p.role)?'leader.html':'member.html';
}
routeLoggedUser();

document.getElementById('loginForm').addEventListener('submit',async e=>{
  e.preventDefault(); if(!B13_CONFIGURED) return message('loginMessage','Configure o Supabase em js/config.js primeiro.','error');
  const email=document.getElementById('loginEmail').value.trim();
  const password=document.getElementById('loginPassword').value;
  message('loginMessage','Entrando...','info');
  const {data,error}=await b13.auth.signInWithPassword({email,password});
  if(error) return message('loginMessage','E-mail ou senha inválidos.','error');
  const {data:p,error:pe}=await b13.from('profiles').select('*').eq('id',data.user.id).single();
  if(pe || !p){await b13.auth.signOut();return message('loginMessage','Perfil não encontrado. Rode o schema do Supabase.','error');}
  if(!p.approved){await b13.auth.signOut();return message('loginMessage','Seu cadastro ainda aguarda aprovação da liderança.','warn');}
  if(p.status!=='ativo'){await b13.auth.signOut();return message('loginMessage','Sua conta está desativada. Fale com a liderança.','error');}
  location.href=['gerente','sub_lider','lider'].includes(p.role)?'leader.html':'member.html';
});

document.getElementById('registerForm').addEventListener('submit',async e=>{
  e.preventDefault(); if(!B13_CONFIGURED) return message('registerMessage','Configure o Supabase em js/config.js primeiro.','error');
  const name=document.getElementById('regName').value.trim(), rp_id=document.getElementById('regRpId').value.trim(), discord=document.getElementById('regDiscord').value.trim();
  const email=document.getElementById('regEmail').value.trim(), password=document.getElementById('regPassword').value;
  message('registerMessage','Criando cadastro...','info');
  const {data,error}=await b13.auth.signUp({email,password,options:{data:{name,rp_id,discord}}});
  if(error) return message('registerMessage',error.message,'error');
  if(data.session) await b13.auth.signOut();
  e.target.reset();
  message('registerMessage','Cadastro criado! Agora aguarde a aprovação da liderança.','ok');
});
