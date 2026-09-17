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

La aplicación es privada.

- Solo cuentas corporativas `@electricabt.com`.
- Sin acceso anónimo.
- Sin registro público por email/contraseña.
- Roles iniciales: `admin`, `oficina`, `tecnico`.
- RLS activada en todas las tablas del núcleo.
- En V0.1 no se conceden permisos `DELETE` a usuarios autenticados.

La configuración detallada está en [`docs/AUTH.md`](docs/AUTH.md).

## Principios

1. **Independencia entre proyectos.** Gestión Administrativa BT no depende de Xispa, CAD Unifilar, Asesor Energético ni Odoo para funcionar.
2. **No regresión.** Las integraciones futuras se añaden mediante interfaces versionadas y pruebas.
3. **Privacidad.** Este repositorio es público. Nunca se guardarán aquí documentos reales, nombres de clientes, direcciones, CUPS, teléfonos, CIF/NIF ni credenciales.
4. **Trazabilidad.** Los datos extraídos de documentos deben conservar su origen, parser y versión.
5. **Seguridad desde el diseño.** Los datos reales vivirán en almacenamiento privado y la autorización se implementa con Auth + RLS en Supabase.
6. **No inventar datos.** Los datos desconocidos o ambiguos deben quedar pendientes de revisión.

## Arquitectura prevista

```text
GitHub Pages / Web App
        |
        v
     Supabase
  + PostgreSQL
  + Auth corporativo
  + Storage privado
  + RLS
        |
        +--> Integraciones externas versionadas
             - Asesor Energético
             - Xispa
             - CAD Unifilar
             - Odoo
```

## Archivos principales

- `index.html`: interfaz base y pantalla de acceso.
- `app.js`: sesión corporativa y guardas del frontend.
- `config.js`: configuración pública del cliente Supabase; nunca secretos.
- `supabase/schema.sql`: tablas, Auth hook, usuarios, roles y políticas RLS.
- `docs/AUTH.md`: procedimiento de autenticación y verificación.
- `docs/ARCHITECTURE.md`: arquitectura general y contratos entre sistemas.

## Estado

La carcasa de autenticación y el modelo de permisos V0.1 están preparados en código. Falta crear el proyecto Supabase independiente, ejecutar el esquema, configurar el proveedor OAuth corporativo y verificar las políticas antes de introducir datos reales.
