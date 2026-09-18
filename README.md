# Gestión Administrativa BT

Base administrativa independiente para ELECTRICA BT.

## Objetivo V0.1

Construir un núcleo estable para gestionar:

- Clientes
- Suministros / CUPS
- Documentos
- Expedientes
- Histórico por cliente y suministro
- Usuarios y permisos

## Acceso

La aplicación es privada y se protege mediante Cloudflare Access.

- Solo cuentas corporativas `@electricabt.com`.
- Sin acceso anónimo.
- Roles iniciales: `admin`, `oficina`, `tecnico`.
- Un usuario nuevo entra como `tecnico`.
- Un usuario desactivado pierde acceso.
- La API vuelve a validar el dominio aunque Access ya haya autenticado la petición.
- En V0.1 no existe borrado desde la interfaz.

## Principios

1. **Independencia entre proyectos.** Gestión Administrativa BT no depende de Xispa, CAD Unifilar, Asesor Energético ni Odoo para funcionar.
2. **No regresión.** Las integraciones futuras se añaden mediante interfaces versionadas y pruebas.
3. **Privacidad.** Este repositorio es público. Nunca se guardarán aquí documentos reales, nombres de clientes, direcciones, CUPS, teléfonos, CIF/NIF ni credenciales.
4. **Trazabilidad.** Los datos extraídos de documentos deben conservar su origen, parser y versión.
5. **Seguridad desde el diseño.** Cloudflare Access protege el perímetro y la aplicación mantiene permisos internos.
6. **No inventar datos.** Los datos desconocidos o ambiguos deben quedar pendientes de revisión.

## Arquitectura activa

```text
GitHub
  |
  v
Cloudflare Worker
  + Static Assets
  + API
  |
  +-- Cloudflare Access
  |     Solo @electricabt.com
  |
  +-- D1
  |     Datos administrativos
  |
  +-- OneDrive / SharePoint corporativo
        Documentos reales
```

D1 guarda metadatos y referencias de documento (`external_id`, `web_url`, hash y relación con cliente/CUPS). Los archivos reales permanecen en el almacenamiento corporativo existente.

Las integraciones externas seguirán siendo independientes y versionadas:

- Xispa
- CAD Unifilar
- Asesor Energético
- Odoo

## Archivos principales

- `public/index.html`: interfaz activa.
- `public/app.js`: frontend conectado a la API del Worker.
- `src/index.js`: API, autenticación interna y permisos.
- `wrangler.jsonc`: configuración Cloudflare.
- `migrations/0001_initial.sql`: esquema inicial D1.
- `docs/CLOUDFLARE.md`: despliegue y seguridad.
- `docs/ARCHITECTURE.md`: arquitectura y contratos entre sistemas.

## Supabase

Los archivos de `supabase/` se conservan temporalmente como referencia de la primera propuesta arquitectónica, pero **ya no forman parte del backend activo**.

## Estado

El backend activo usa Cloudflare Workers + D1 + Access. R2 se descarta para evitar activar facturación por uso. Los documentos se integrarán con OneDrive/SharePoint corporativo sin duplicarlos en Cloudflare.
