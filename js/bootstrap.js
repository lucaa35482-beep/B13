// Compatibilidade: garante que versões antigas de auth.js em cache não quebrem o login.
var B13_CONFIGURED = true;
var B13_CONFIG = {
  SUPABASE_URL: 'https://thcqeuhmrhzyssvemaer.supabase.co',
  SUPABASE_ANON_KEY: 'sb_publishable_92cmGjpVBye576YY5ee97g_PXUH9996'
};

(function(){
  'use strict';
  const SUPABASE_URL='https://thcqeuhmrhzyssvemaer.supabase.co';
  const SUPABASE_KEY='sb_publishable_92cmGjpVBye576YY5ee97g_PXUH9996';

  window.B13_RULES={dailyGoal:1000,kitsPerLeaf:3,publicPrice:300,memberSalePrice:280,memberPercent:0.20,orgPercent:0.80};
  window.money=(v)=>'$ '+Number(v||0).toLocaleString('pt-BR');
  window.initials=(name='')=>name.split(/\s+/).filter(Boolean).slice(0,2).map(x=>x[0]).join('').toUpperCase()||'B13';
  window.calcDelivery=(leaves)=>{leaves=Number(leaves||0);const kits=leaves*3,gross=kits*300;return{leaves,kits,gross,member_amount:gross*.2,org_amount:gross*.8}};
  window.showToast=(msg,type='ok')=>{let t=document.getElementById('b13Toast');if(!t){t=document.createElement('div');t.id='b13Toast';document.body.appendChild(t)}t.className='toast '+type;t.textContent=msg;clearTimeout(window.__b13ToastTimer);window.__b13ToastTimer=setTimeout(()=>t.remove(),3200)};
  window.b13Token=()=>localStorage.getItem('b13_session_token')||'';
  window.b13SetToken=(t)=>localStorage.setItem('b13_session_token',t);
  window.b13ClearToken=()=>localStorage.removeItem('b13_session_token');

  window.b13Rpc=async function(fn,args={}){
    const res=await fetch(`${SUPABASE_URL}/rest/v1/rpc/${fn}`,{
      method:'POST',
      headers:{'Content-Type':'application/json','apikey':SUPABASE_KEY,'Authorization':'Bearer '+SUPABASE_KEY},
      body:JSON.stringify(args)
    });
    let data=null; const text=await res.text();
    try{data=text?JSON.parse(text):null}catch{data=text}
    if(!res.ok){
      const msg=(data&&data.message)||('Erro '+res.status+' ao acessar o Supabase');
      throw new Error(msg);
    }
    return data;
  };
  window.getSessionProfile=async()=>{const token=b13Token();if(!token){location.href='index.html';return null}try{const profile=await b13Rpc('b13_me',{p_token:token});if(!profile||!profile.id)throw new Error('Sessão inválida');return{profile}}catch(e){b13ClearToken();location.href='index.html';return null}};
  window.signOutB13=async()=>{const token=b13Token();try{if(token)await b13Rpc('b13_logout',{p_token:token})}catch(e){}b13ClearToken();location.href='index.html'};
})();
