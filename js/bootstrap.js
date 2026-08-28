(function(){
  'use strict';
  const SUPABASE_URL='https://thcqeuhmrhzyssvemaer.supabase.co';
  const SUPABASE_KEY='sb_publishable_92cmGjpVBye576YY5ee97g_PXUH9996';

  window.B13_RULES={dailyGoal:1000,kitsPerLeaf:3,publicPrice:300,memberSalePrice:280,memberPercent:0.20,orgPercent:0.80};
  window.money=(v)=>'$ '+Number(v||0).toLocaleString('pt-BR');
  window.initials=(name='')=>name.split(/\s+/).filter(Boolean).slice(0,2).map(x=>x[0]).join('').toUpperCase()||'B13';
  window.calcDelivery=(leaves)=>{leaves=Number(leaves||0);const r=window.B13_RULES||{};const kits=leaves*Number(r.kitsPerLeaf||3),gross=kits*Number(r.publicPrice||300);return{leaves,kits,gross,member_amount:gross*Number(r.memberPercent||0),org_amount:gross*Number(r.orgPercent||0)}};
  window.showToast=(msg,type='ok')=>{let t=document.getElementById('b13Toast');if(!t){t=document.createElement('div');t.id='b13Toast';document.body.appendChild(t)}t.className='toast '+type;t.textContent=msg;clearTimeout(window.__b13ToastTimer);window.__b13ToastTimer=setTimeout(()=>t.remove(),3200)};
  window.b13Token=()=>localStorage.getItem('b13_session_token')||'';
  window.b13SetToken=(t)=>localStorage.setItem('b13_session_token',String(t||''));
  window.b13ClearToken=()=>localStorage.removeItem('b13_session_token');


  window.b13ApplySettings=function(data){
    if(!data)return window.B13_RULES;
    window.B13_RULES={
      dailyGoal:Number(data.daily_goal??data.dailyGoal??1000),
      kitsPerLeaf:Number(data.kits_per_leaf??data.kitsPerLeaf??3),
      publicPrice:Number(data.public_price??data.publicPrice??300),
      memberSalePrice:Number(data.member_sale_price??data.memberSalePrice??280),
      memberPercent:Number(data.member_percent??data.memberPercent??0.20),
      orgPercent:Number(data.org_percent??data.orgPercent??0.80)
    };
    return window.B13_RULES;
  };
  window.b13LoadSettings=async function(){
    const token=window.b13Token();
    if(!token)return window.B13_RULES;
    try{return window.b13ApplySettings(await window.b13Rpc('b13_get_settings',{p_token:token}));}
    catch(e){console.warn('B13 settings fallback:',e);return window.B13_RULES;}
  };

  window.b13Rpc=async function(fn,args={}){
    let res;
    try{
      res=await fetch(`${SUPABASE_URL}/rest/v1/rpc/${fn}`,{
        method:'POST',
        headers:{'Content-Type':'application/json','apikey':SUPABASE_KEY},
        body:JSON.stringify(args)
      });
    }catch(e){ throw new Error('Não foi possível conectar ao Supabase.'); }
    const text=await res.text();
    let data=null;
    try{data=text?JSON.parse(text):null}catch{data=text}
    if(!res.ok){
      const msg=(data&&data.message)||(data&&data.error_description)||(typeof data==='string'&&data)||('Erro '+res.status+' ao acessar o Supabase');
      throw new Error(msg);
    }
    return data;
  };

  window.getSessionProfile=async()=>{
    const token=window.b13Token();
    if(!token){location.replace('index.html');return null;}
    try{
      const profile=await window.b13Rpc('b13_me',{p_token:token});
      if(!profile||!profile.id)throw new Error('Sessão inválida');
      return {profile};
    }catch(e){window.b13ClearToken();location.replace('index.html');return null;}
  };
  window.signOutB13=async()=>{
    const token=window.b13Token();
    try{if(token)await window.b13Rpc('b13_logout',{p_token:token});}catch(e){}
    window.b13ClearToken();location.replace('index.html');
  };
})();
