# Autenticación corporativa

## Regla de acceso

Gestión Administrativa BT es una aplicación privada.

- Dominio permitido: `@electricabt.com`
- Sin acceso anónimo
- Sin registro público por email/contraseña
- Usuario interno obligatorio y activo
- Roles iniciales: `admin`, `oficina`, `tecnico`
- RLS protege los datos aunque alguien intente saltarse la interfaz

## Capas de seguridad

1. El proveedor OAuth autentica la identidad corporativa.
2. El hook `Before User Created` rechaza cualquier email que no sea `@electricabt.com`.
3. El trigger de alta crea `public.usuarios` con rol inicial `tecnico`.
4. Las políticas RLS vuelven a exigir usuario activo y dominio corporativo.
5. `admin` puede gestionar roles y desactivar usuarios.
6. `oficina` puede leer y modificar datos administrativos.
7. `tecnico` tiene lectura en la V0.1.
8. Ningún usuario autenticado recibe permisos `DELETE` en la V0.1.

## Configuración de Supabase

Después de crear el proyecto:

1. Ejecutar `supabase/schema.sql` desde el SQL Editor.
2. En **Authentication > Hooks**, configurar **Before User Created** para usar la función Postgres:
   `public.hook_restrict_signup_to_electricabt`.
3. Configurar un proveedor OAuth corporativo:
   - `azure` para Microsoft 365 / Microsoft Entra ID.
   - `google` para Google Workspace.
4. Configurar la aplicación OAuth como organización/tenant corporativo siempre que el proveedor lo permita.
5. Añadir como Redirect URL la URL de producción de GitHub Pages y cualquier URL local usada para pruebas.
6. Copiar la URL del proyecto y una **publishable key** a `config.js`.
7. No usar nunca una `service_role`/secret key en GitHub Pages.
8. Iniciar sesión por primera vez con una cuenta corporativa y promover manualmente al administrador inicial en el SQL Editor.

Ejemplo de promoción inicial, sustituyendo el email por la cuenta real:

```sql
update public.usuarios
set rol = 'admin'
where email = 'usuario@electricabt.com';
```

## Verificación mínima

Antes de introducir datos reales:

- Una cuenta `@electricabt.com` válida puede autenticarse.
- Una cuenta externa es rechazada antes de crear usuario.
- Un usuario desactivado no puede leer datos.
- `tecnico` no puede modificar clientes ni suministros.
- `oficina` puede crear y editar, pero no borrar.
- `admin` puede modificar roles y desactivar usuarios.
- No existe acceso anónimo a ninguna tabla del núcleo.
- Security Advisor no informa de tablas públicas sin RLS.

## Nota sobre Data API

Los proyectos Supabase nuevos ya no deben asumir que las tablas creadas en `public` quedan expuestas automáticamente a Data API. El esquema incluye `GRANT` explícitos para los roles necesarios, pero la configuración de Data API del proyecto debe verificarse tras crear la base.
