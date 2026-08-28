(function(){
'use strict';
const $=id=>document.getElementById(id);
const tabs=[...document.querySelectorAll('.auth-tab')];
const loginForm=$('loginForm'),registerForm=$('registerForm');
function message(id,text,type='info'){const el=$(id);el.className='message '+type;el.textContent=text;}
function setBusy(form,busy){const btn=form.querySelector('button[type="submit"]');if(!btn)return;btn.disabled=busy;btn.dataset.label=btn.dataset.label||btn.textContent;btn.textContent=busy?'AGUARDE...':btn.dataset.label;}

tabs.forEach(btn=>btn.addEventListener('click',()=>{tabs.forEach(x=>x.classList.remove('active'));btn.classList.add('active');loginForm.classList.toggle('hidden',btn.dataset.tab!=='login');registerForm.classList.toggle('hidden',btn.dataset.tab!=='register');}));

(async()=>{const token=window.b13Token();if(!token)return;try{const p=await window.b13Rpc('b13_me',{p_token:token});if(p&&p.id)location.replace(['gerente','sub_lider','lider'].includes(p.role)?'leader.html':'member.html');}catch(e){window.b13ClearToken();}})();

loginForm.addEventListener('submit',async e=>{e.preventDefault();const email=$('loginEmail').value.trim(),password=$('loginPassword').value;if(!email||!password){message('loginMessage','Preencha e-mail e senha.','error');return;}message('loginMessage','Entrando...','info');setBusy(loginForm,true);try{const data=await window.b13Rpc('b13_login',{p_email:email,p_password:password});if(!data||!data.token)throw new Error('Resposta de login inválida.');window.b13SetToken(data.token);location.replace(['gerente','sub_lider','lider'].includes(data.role)?'leader.html':'member.html');}catch(err){message('loginMessage',String(err.message||'Falha no acesso').replace('B13: ',''),'error');}finally{setBusy(loginForm,false);}});

registerForm.addEventListener('submit',async e=>{e.preventDefault();const args={p_name:$('regName').value.trim(),p_rp_id:$('regRpId').value.trim(),p_discord:$('regDiscord').value.trim(),p_email:$('regEmail').value.trim(),p_password:$('regPassword').value};message('registerMessage','Criando cadastro...','info');setBusy(registerForm,true);try{const data=await window.b13Rpc('b13_register',args);registerForm.reset();message('registerMessage',(data&&data.message)||'Cadastro criado. Aguarde aprovação da liderança.','ok');}catch(err){message('registerMessage',String(err.message||'Falha no cadastro').replace('B13: ',''),'error');}finally{setBusy(registerForm,false);}});
})();
