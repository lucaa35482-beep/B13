import { createClient } from '@supabase/supabase-js';

// FAC B13 usa o Supabase somente como banco/RPC.
// Não depende do Supabase Auth, então não há confirmação de e-mail nem rate limit de e-mail.
const SUPABASE_URL = 'https://thcqeuhmrhzyssvemaer.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_92cmGjpVBye576YY5ee97g_PXUH9996';

window.b13 = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false }
});

window.B13_RULES = {
  dailyGoal: 1000,
  kitsPerLeaf: 3,
  publicPrice: 300,
  memberSalePrice: 280,
  memberPercent: 0.20,
  orgPercent: 0.80
};

window.money = (v) => '$ ' + Number(v || 0).toLocaleString('pt-BR');
window.initials = (name='') => name.split(/\s+/).filter(Boolean).slice(0,2).map(x=>x[0]).join('').toUpperCase() || 'B13';
window.calcDelivery = (leaves) => {
  leaves = Number(leaves || 0);
  const kits = leaves * B13_RULES.kitsPerLeaf;
  const gross = kits * B13_RULES.publicPrice;
  return {leaves,kits,gross,member_amount:gross*B13_RULES.memberPercent,org_amount:gross*B13_RULES.orgPercent};
};

window.showToast = (msg, type='ok') => {
  let t=document.getElementById('b13Toast');
  if(!t){t=document.createElement('div');t.id='b13Toast';document.body.appendChild(t)}
  t.className='toast '+type;t.textContent=msg;
  clearTimeout(window.__b13ToastTimer);window.__b13ToastTimer=setTimeout(()=>t.remove(),3200);
};

window.b13Token = () => localStorage.getItem('b13_session_token') || '';
window.b13SetToken = (t) => localStorage.setItem('b13_session_token', t);
window.b13ClearToken = () => localStorage.removeItem('b13_session_token');

window.b13Rpc = async (fn, args={}) => {
  const {data,error}=await b13.rpc(fn,args);
  if(error) throw error;
  return data;
};

window.getSessionProfile = async () => {
  const token=b13Token();
  if(!token){location.href='index.html';return null;}
  try{
    const profile=await b13Rpc('b13_me',{p_token:token});
    if(!profile || !profile.id) throw new Error('Sessão inválida');
    return {profile};
  }catch(e){b13ClearToken();location.href='index.html';return null;}
};

window.signOutB13 = async () => {
  const token=b13Token();
  try{if(token) await b13.rpc('b13_logout',{p_token:token});}catch(e){}
  b13ClearToken();location.href='index.html';
};
