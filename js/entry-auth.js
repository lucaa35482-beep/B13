import './bootstrap.js';
// O script clássico fica em public/js para ser copiado para o build final do Vercel.
const script = document.createElement('script');
script.src = '/js/auth.js';
script.async = false;
document.body.appendChild(script);
