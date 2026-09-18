const bootView = document.getElementById('boot-view');
const bootStatus = document.getElementById('boot-status');
const appView = document.getElementById('app-view');
const userBadge = document.getElementById('user-badge');
const logoutButton = document.getElementById('logout-button');

const counts = {
  clientes: document.getElementById('count-clientes'),
  suministros: document.getElementById('count-suministros'),
  expedientes: document.getElementById('count-expedientes'),
  documentos: document.getElementById('count-documentos')
};

function showError(message) {
  bootStatus.textContent = message;
  bootStatus.classList.add('error');
}

async function api(path, options) {
  const response = await fetch(path, {
    credentials: 'same-origin',
    headers: { 'accept': 'application/json' },
    ...options
  });

  const raw = await response.text();
  let data = {};

  if (raw) {
    try {
      data = JSON.parse(raw);
    } catch {
      data = { raw };
    }
  }

  if (!response.ok) {
    const detail =
      data.error ||
      (data.raw ? data.raw.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 240) : '') ||
      response.statusText ||
      'Error desconocido';

    throw new Error(`Backend ${response.status}: ${detail}`);
  }

  return data;
}

async function start() {
  try {
    const me = await api('/api/me');
    userBadge.textContent = `${me.nombre || me.email} · ${String(me.rol || '').toUpperCase()}`;

    const dashboard = await api('/api/dashboard');
    Object.entries(counts).forEach(([key, element]) => {
      element.textContent = dashboard[key] ?? 0;
    });

    bootView.hidden = true;
    appView.hidden = false;
  } catch (error) {
    showError(error.message);
  }
}

logoutButton.addEventListener('click', () => {
  window.location.href = '/cdn-cgi/access/logout';
});

start();
