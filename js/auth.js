
const tabs=document.querySelectorAll('.auth-tab');
tabs.forEach(btn=>btn.addEventListener('click',()=>{
  tabs.forEach(x=>x.classList.remove('active'));btn.classList.add('active');
  document.getElementById('loginForm').classList.toggle('hidden',btn.dataset.tab!=='login');
  document.getElementById('registerForm').classList.toggle('hidden',btn.dataset.tab!=='register');
}));
function message(id,text,type='info'){const el=document.getElementById(id);el.className='message '+type;el.textContent=text;}

(async()=>{
  const token=b13Token();if(!token)return;
  try{const p=await b13Rpc('b13_me',{p_token:token});if(p?.id)location.href=['gerente','sub_lider','lider'].includes(p.role)?'leader.html':'member.html';}catch(e){b13ClearToken();}
})();

document.getElementById('loginForm').addEventListener('submit',async e=>{
  e.preventDefault();
  const email=document.getElementById('loginEmail').value.trim();
  const password=document.getElementById('loginPassword').value;
  message('loginMessage','Entrando...','info');
  try{
    const data=await b13Rpc('b13_login',{p_email:email,p_password:password});
    b13SetToken(data.token);
    location.href=['gerente','sub_lider','lider'].includes(data.role)?'leader.html':'member.html';
  }catch(err){message('loginMessage',(err.message||'Falha no acesso').replace('B13: ',''),'error');}
});

document.getElementById('registerForm').addEventListener('submit',async e=>{
  e.preventDefault();
  const name=document.getElementById('regName').value.trim();
  const rp_id=document.getElementById('regRpId').value.trim();
  const discord=document.getElementById('regDiscord').value.trim();
  const email=document.getElementById('regEmail').value.trim();
  const password=document.getElementById('regPassword').value;
  message('registerMessage','Criando cadastro...','info');
  try{
    const data=await b13Rpc('b13_register',{p_name:name,p_rp_id:rp_id,p_discord:discord,p_email:email,p_password:password});
    e.target.reset();
    message('registerMessage',data.message||'Cadastro criado. Aguarde aprovação da liderança.','ok');
  }catch(err){message('registerMessage',(err.message||'Falha no cadastro').replace('B13: ',''),'error');}
});
