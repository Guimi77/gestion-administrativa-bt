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
  +-- Cloudflare Access (@electricabt.com)
  +-- OneDrive / SharePoint corporativo (documentos)
```

## Objetivo de coste

La aplicación se mantiene en Cloudflare Free. No se activa R2 ni ningún servicio de pago por uso para documentos.

En el plan Free, si D1 alcanza sus límites diarios, las consultas fallan hasta el siguiente reinicio de cuota en lugar de generar sobrecostes.

## 1. Importar el repositorio

En Cloudflare:

1. Workers & Pages.
2. Create application.
3. Import a repository.
4. Conectar GitHub.
5. Elegir `Guimi77/gestion-administrativa-bt`.
6. Rama de producción: `main`.
7. Worker: `gestion-administrativa-bt`.
8. Deploy command: `npx wrangler deploy`.
9. Guardar y desplegar.

## 2. D1

El archivo `wrangler.jsonc` declara únicamente:

- D1 binding: `DB`

No existe binding R2.

### Aplicar migraciones D1

```bash
npm install
npm run db:migrate:remote
```

La primera migración crea:

- usuarios
- clientes
- suministros
- expedientes
- documentos
- historico
- procesamientos

La tabla `documentos` no almacena el PDF. Guarda su proveedor, identificador externo, URL, hash y relaciones administrativas.

## 3. Documentos

Proveedor previsto: OneDrive / SharePoint corporativo.

D1 conservará:

```text
storage_provider
external_id
web_url
ruta_logica
hash_archivo
```

El archivo real sigue en Microsoft 365.

La integración automática mediante Microsoft Graph se implementará como módulo independiente. Hasta entonces no se debe copiar documentación real al repositorio.

## 4. Cloudflare Access

En el Worker `gestion-administrativa-bt`:

1. Pestaña Access.
2. Protect this Worker behind Access.
3. Scope: All traffic.
4. Política Allow.
5. Condición: Email domain = `electricabt.com`.
6. Aplicar.

La API vuelve a comprobar el dominio como defensa adicional.

## 5. Usuarios y roles

Primer acceso corporativo:

```text
rol = tecnico
activo = 1
```

Roles:

- `admin`: administración.
- `oficina`: lectura y escritura administrativa.
- `tecnico`: lectura.

## 6. Seguridad

- No almacenar secretos en GitHub.
- No almacenar documentos reales en GitHub.
- No activar R2 para este proyecto.
- Access protege el perímetro.
- La API verifica dominio y usuario activo.
- Probar con una cuenta autorizada y otra externa antes de introducir datos reales.

## 7. Prueba mínima

1. Abrir la URL del Worker en ventana privada.
2. Confirmar que Access exige autenticación.
3. Entrar con `@electricabt.com`.
4. Confirmar el panel.
5. Verificar `/api/health`.
6. Verificar `/api/me`.
7. Confirmar que una cuenta externa no entra.
