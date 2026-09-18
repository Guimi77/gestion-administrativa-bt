const ALLOWED_DOMAIN = 'electricabt.com';

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store'
    }
  });
}

function corporateEmail(request) {
  const value = request.headers.get('cf-access-authenticated-user-email');
  return value ? value.trim().toLowerCase() : '';
}

async function ensureUser(request, env) {
  const email = corporateEmail(request);

  if (!email || !email.endsWith('@' + ALLOWED_DOMAIN)) {
    return { error: json({ error: 'Acceso corporativo requerido.' }, 401) };
  }

  let user = await env.DB.prepare(
    'SELECT id, email, nombre, rol, activo FROM usuarios WHERE lower(email) = ?'
  ).bind(email).first();

  if (!user) {
    const id = crypto.randomUUID();
    await env.DB.prepare(
      "INSERT INTO usuarios (id, email, rol, activo) VALUES (?, ?, 'tecnico', 1)"
    ).bind(id, email).run();

    user = { id, email, nombre: null, rol: 'tecnico', activo: 1 };
  }

  if (Number(user.activo) !== 1) {
    return { error: json({ error: 'Usuario desactivado.' }, 403) };
  }

  return { user };
}

function canWrite(user) {
  return user.rol === 'admin' || user.rol === 'oficina';
}

async function dashboard(env) {
  const [clientes, suministros, expedientes, documentos] = await Promise.all([
    env.DB.prepare('SELECT COUNT(*) AS total FROM clientes WHERE activo = 1').first(),
    env.DB.prepare('SELECT COUNT(*) AS total FROM suministros WHERE activo = 1').first(),
    env.DB.prepare("SELECT COUNT(*) AS total FROM expedientes WHERE estado = 'abierto'").first(),
    env.DB.prepare('SELECT COUNT(*) AS total FROM documentos').first()
  ]);

  return {
    clientes: Number(clientes?.total || 0),
    suministros: Number(suministros?.total || 0),
    expedientes: Number(expedientes?.total || 0),
    documentos: Number(documentos?.total || 0)
  };
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (!url.pathname.startsWith('/api/')) {
      return env.ASSETS.fetch(request);
    }

    if (url.pathname === '/api/health') {
      return json({ ok: true, service: 'gestion-administrativa-bt' });
    }

    const auth = await ensureUser(request, env);
    if (auth.error) return auth.error;

    if (url.pathname === '/api/me' && request.method === 'GET') {
      return json({
        email: auth.user.email,
        nombre: auth.user.nombre,
        rol: auth.user.rol,
        activo: true
      });
    }

    if (url.pathname === '/api/dashboard' && request.method === 'GET') {
      return json(await dashboard(env));
    }

    if (url.pathname === '/api/clientes' && request.method === 'GET') {
      const result = await env.DB.prepare(
        'SELECT id, nombre, nombre_fiscal, cif_nif, telefono, email, activo FROM clientes ORDER BY nombre LIMIT 100'
      ).all();
      return json({ items: result.results || [] });
    }

    if (url.pathname === '/api/clientes' && request.method === 'POST') {
      if (!canWrite(auth.user)) {
        return json({ error: 'Tu rol no permite crear clientes.' }, 403);
      }

      let body;
      try {
        body = await request.json();
      } catch {
        return json({ error: 'JSON no valido.' }, 400);
      }

      const nombre = String(body?.nombre || '').trim();
      if (!nombre) {
        return json({ error: 'El nombre del cliente es obligatorio.' }, 400);
      }

      const id = crypto.randomUUID();
      await env.DB.prepare(
        `INSERT INTO clientes
        (id, nombre, nombre_fiscal, cif_nif, telefono, email)
        VALUES (?, ?, ?, ?, ?, ?)`
      ).bind(
        id,
        nombre,
        body?.nombre_fiscal || null,
        body?.cif_nif || null,
        body?.telefono || null,
        body?.email || null
      ).run();

      return json({ id, nombre }, 201);
    }

    return json({ error: 'Ruta no encontrada.' }, 404);
  }
};
