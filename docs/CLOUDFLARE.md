# Despliegue en Cloudflare

## Arquitectura V0.1

```text
GitHub
  |
  v
Cloudflare Worker
  + Static Assets
  + API /api/*
  |
  +-- D1 (datos administrativos)
  +-- R2 (documentos privados)
  +-- Cloudflare Access (@electricabt.com)
```

## 1. Importar el repositorio

En Cloudflare:

1. Workers & Pages.
2. Create application.
3. Import a repository.
4. Conectar GitHub si todavía no está conectado.
5. Elegir `Guimi77/gestion-administrativa-bt`.
6. Rama de producción: `main`.
7. El nombre del Worker debe ser exactamente `gestion-administrativa-bt`.
8. Deploy command: `npx wrangler deploy`.
9. Guardar y desplegar.

El repositorio ya contiene `wrangler.jsonc`, por lo que Cloudflare no debe generar otra configuración.

## 2. D1 y R2

El archivo `wrangler.jsonc` declara:

- D1 binding: `DB`
- R2 binding: `DOCUMENTS`

Wrangler puede aprovisionar recursos declarados durante el primer despliegue. Después del despliegue, verificar en el panel que ambos bindings existen.

### Aplicar migraciones D1

Después de disponer de la base remota:

```bash
npm install
npm run db:migrate:remote
```

La primera migración crea las tablas:

- usuarios
- clientes
- suministros
- expedientes
- documentos
- historico
- procesamientos

No introducir datos reales antes de verificar la migración y Access.

## 3. Proteger el Worker con Cloudflare Access

En el Worker `gestion-administrativa-bt`:

1. Abrir la pestaña Access.
2. Protect this Worker behind Access.
3. Proteger producción y previews.
4. Política Allow.
5. Condición: Email domain = `electricabt.com`.
6. Aplicar.

Access debe proteger el Worker completo. La API vuelve a comprobar el dominio como defensa adicional.

## 4. Usuarios y roles

La primera vez que una cuenta corporativa accede a la API, se crea en `usuarios` con:

```text
rol = tecnico
activo = 1
```

Roles:

- `admin`: administración completa.
- `oficina`: lectura y escritura administrativa.
- `tecnico`: lectura.

La creación de clientes por API está limitada actualmente a `admin` y `oficina`.

## 5. Logout

La aplicación usa la ruta gestionada por Cloudflare Access:

```text
/cdn-cgi/access/logout
```

## 6. Seguridad

- Nunca almacenar claves API, tokens ni credenciales en GitHub.
- Nunca almacenar PDFs reales ni datos de clientes en el repositorio público.
- R2 debe permanecer privado.
- Access es la barrera perimetral.
- La API comprueba además el email corporativo y el estado del usuario.
- Antes de introducir datos reales, verificar desde una cuenta autorizada y otra no autorizada.

## 7. Prueba mínima

Una vez desplegado:

1. Abrir la URL del Worker en una ventana privada.
2. Confirmar que Cloudflare pide autenticación.
3. Entrar con una cuenta `@electricabt.com`.
4. Confirmar que aparece el panel.
5. Verificar `/api/health`.
6. Verificar `/api/me`.
7. Verificar que una cuenta externa no puede acceder.

## Estado

El código está preparado. Falta realizar el primer despliegue en la cuenta Cloudflare, aplicar la migración D1 y activar Access.
