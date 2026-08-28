import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = (import.meta.env.VITE_SUPABASE_URL || '').trim().replace(/\/$/, '');
const SUPABASE_ANON_KEY = (import.meta.env.VITE_SUPABASE_ANON_KEY || '').trim();

const configured =
  /^https:\/\/[a-z0-9-]+\.supabase\.co$/i.test(SUPABASE_URL) &&
  (SUPABASE_ANON_KEY.startsWith('sb_publishable_') || SUPABASE_ANON_KEY.startsWith('eyJ'));

window.B13_CONFIG = { SUPABASE_URL, SUPABASE_ANON_KEY };
window.B13_CONFIGURED = configured;
window.b13 = configured
  ? createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true
      }
    })
  : null;

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
  const kits = leaves * window.B13_RULES.kitsPerLeaf;
  const gross = kits * window.B13_RULES.publicPrice;
  return {
    leaves,
    kits,
    gross,
    member_amount: gross * window.B13_RULES.memberPercent,
    org_amount: gross * window.B13_RULES.orgPercent
  };
};

window.showToast = (msg, type='ok') => {
  let t = document.getElementById('b13Toast');
  if (!t) {
    t = document.createElement('div');
    t.id = 'b13Toast';
    document.body.appendChild(t);
  }
  t.className = 'toast ' + type;
  t.textContent = msg;
  clearTimeout(window.__b13ToastTimer);
  window.__b13ToastTimer = setTimeout(() => t.remove(), 3200);
};

window.requireSupabase = () => {
  if (!window.B13_CONFIGURED) {
    alert('Supabase não configurado. No Vercel, adicione VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY e faça um novo deploy.');
    location.href = 'index.html';
    return false;
  }
  return true;
};

window.getSessionProfile = async () => {
  if (!window.requireSupabase()) return null;
  const { data: { session } } = await window.b13.auth.getSession();
  if (!session) { location.href = 'index.html'; return null; }
  const { data: profile, error } = await window.b13.from('profiles').select('*').eq('id', session.user.id).single();
  if (error || !profile) {
    await window.b13.auth.signOut();
    location.href = 'index.html';
    return null;
  }
  return { session, profile };
};

window.signOutB13 = async () => {
  if (window.b13) await window.b13.auth.signOut();
  location.href = 'index.html';
};
