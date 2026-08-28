(() => {
  const cfg = window.B13_CONFIG || {};
  const configured = cfg.SUPABASE_URL && cfg.SUPABASE_ANON_KEY &&
    !cfg.SUPABASE_URL.includes('SEU-PROJETO') && !cfg.SUPABASE_ANON_KEY.includes('SUA-CHAVE');
  window.B13_CONFIGURED = !!configured;
  window.b13 = configured ? window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY) : null;

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
    return { leaves, kits, gross, member_amount: gross * B13_RULES.memberPercent, org_amount: gross * B13_RULES.orgPercent };
  };
  window.showToast = (msg, type='ok') => {
    let t=document.getElementById('b13Toast');
    if(!t){t=document.createElement('div');t.id='b13Toast';document.body.appendChild(t)}
    t.className='toast '+type;t.textContent=msg;clearTimeout(window.__b13ToastTimer);
    window.__b13ToastTimer=setTimeout(()=>t.remove(),3200);
  };
  window.requireSupabase = () => {
    if(!window.B13_CONFIGURED){
      alert('Configure o Supabase em js/config.js antes de usar o sistema.');
      location.href='index.html'; return false;
    }
    return true;
  };
  window.getSessionProfile = async () => {
    if(!requireSupabase()) return null;
    const {data:{session}} = await b13.auth.getSession();
    if(!session){location.href='index.html';return null;}
    const {data:profile,error}=await b13.from('profiles').select('*').eq('id',session.user.id).single();
    if(error || !profile){await b13.auth.signOut();location.href='index.html';return null;}
    return {session,profile};
  };
  window.signOutB13 = async () => { if(window.b13) await b13.auth.signOut(); location.href='index.html'; };
})();
