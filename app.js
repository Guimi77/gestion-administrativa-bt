import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.116.0/+esm';

const config = window.GABT_CONFIG || {};
const loginView = document.getElementById('login-view');
const appView = document.getElementById('app-view');
const loginButton = document.getElementById('login-button');
const logoutButton = document.getElementById('logout-button');
const loginStatus = document.getElementById('login-status');
const userBadge = document.getElementById('user-badge');

const counts = {
  clientes: document.getElementById('count-clientes'),
  suministros: document.getElementById('count-suministros'),
  expedientes: document.getElementById('count-expedientes'),
  documentos: document.getElementById('count-documentos')
};

function setLoginStatus(message, isError = false) {
  loginStatus.textContent = message;
  loginStatus.classList.toggle('error', isError);
}

function showLogin() {
  loginView.hidden = false;
  appView.hidden = true;
}

function showApp() {
  loginView.hidden = true;
  appView.hidden = false;
}

function hasCorporateDomain(email) {
  if (!email || !config.allowedDomain) return false;
  return email.toLowerCase().endsWith(`@${config.allowedDomain.toLowerCase()}`);
}

const isConfigured = Boolean(
  config.supabaseUrl &&
  config.supabasePublishableKey &&
  ['azure', 'google'].includes(config.authProvider)
);

if (!isConfigured) {
  showLogin();
  loginButton.disabled = true;
  setLoginStatus('Backend pendiente de conectar: faltan URL y publishable key de Supabase.');
} else {
  const supabase = createClient(config.supabaseUrl, config.supabasePublishableKey);

  async function loadDashboardCounts() {
    const requests = [
      supabase.from('clientes').select('*', { count: 'exact', head: true }),
      supabase.from('suministros').select('*', { count: 'exact', head: true }),
      supabase.from('expedientes').select('*', { count: 'exact', head: true }).eq('estado', 'abierto'),
      supabase.from('documentos').select('*', { count: 'exact', head: true })
    ];

    const results = await Promise.all(requests);
    const keys = ['clientes', 'suministros', 'expedientes', 'documentos'];

    results.forEach((result, index) => {
      if (!result.error && counts[keys[index]]) {
        counts[keys[index]].textContent = result.count ?? 0;
      }
    });
  }

  async function acceptSession(session) {
    const user = session?.user;

    if (!user || !hasCorporateDomain(user.email)) {
      await supabase.auth.signOut();
      showLogin();
      setLoginStatus('Acceso denegado. Solo se admiten cuentas @electricabt.com.', true);
      return;
    }

    const { data: profile, error } = await supabase
      .from('usuarios')
      .select('id,email,nombre,rol,activo')
      .eq('id', user.id)
      .maybeSingle();

    if (error || !profile) {
      await supabase.auth.signOut();
      showLogin();
      setLoginStatus('La cuenta existe, pero su perfil interno no está disponible. Revisar configuración de Auth/RLS.', true);
      return;
    }

    if (!profile.activo) {
      await supabase.auth.signOut();
      showLogin();
      setLoginStatus('Esta cuenta corporativa está desactivada.', true);
      return;
    }

    userBadge.textContent = `${profile.nombre || profile.email} · ${profile.rol.toUpperCase()}`;
    showApp();
    await loadDashboardCounts();
  }

  loginButton.addEventListener('click', async () => {
    loginButton.disabled = true;
    setLoginStatus('Redirigiendo al acceso corporativo…');

    const options = {
      redirectTo: `${window.location.origin}${window.location.pathname}`
    };

    if (config.authProvider === 'azure') {
      options.scopes = 'email';
    }

    const { error } = await supabase.auth.signInWithOAuth({
      provider: config.authProvider,
      options
    });

    if (error) {
      loginButton.disabled = false;
      setLoginStatus(`No se pudo iniciar sesión: ${error.message}`, true);
    }
  });

  logoutButton.addEventListener('click', async () => {
    await supabase.auth.signOut();
    userBadge.textContent = '';
    showLogin();
    loginButton.disabled = false;
    setLoginStatus('Sesión cerrada.');
  });

  supabase.auth.onAuthStateChange(async (_event, session) => {
    if (session) {
      await acceptSession(session);
    } else {
      showLogin();
    }
  });

  const { data } = await supabase.auth.getSession();
  if (data.session) {
    await acceptSession(data.session);
  } else {
    showLogin();
  }
}
