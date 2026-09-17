-- Gestión Administrativa BT - esquema base V0.1
-- IMPORTANTE: no contiene datos reales ni credenciales.
-- Acceso previsto: únicamente identidades corporativas @electricabt.com.

create extension if not exists pgcrypto;

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

-- =========================================================
-- USUARIOS INTERNOS
-- =========================================================

create table if not exists public.usuarios (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  nombre text,
  rol text not null default 'tecnico' check (rol in ('admin', 'oficina', 'tecnico')),
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint usuarios_email_corporativo_chk
    check (lower(split_part(email, '@', 2)) = 'electricabt.com')
);

create index if not exists usuarios_rol_idx on public.usuarios(rol);
create index if not exists usuarios_activo_idx on public.usuarios(activo);

-- El hook se configura en Supabase Auth > Hooks > Before User Created.
-- Bloquea la creación de cualquier identidad que no pertenezca al dominio corporativo.
create or replace function public.hook_restrict_signup_to_electricabt(event jsonb)
returns jsonb
language plpgsql
as $$
declare
  user_email text;
  email_domain text;
begin
  user_email := lower(coalesce(event->'user'->>'email', ''));
  email_domain := split_part(user_email, '@', 2);

  if user_email = '' or email_domain <> 'electricabt.com' then
    return jsonb_build_object(
      'error', jsonb_build_object(
        'message', 'Acceso exclusivo para cuentas @electricabt.com.',
        'http_code', 403
      )
    );
  end if;

  return '{}'::jsonb;
end;
$$;

revoke execute on function public.hook_restrict_signup_to_electricabt(jsonb)
  from public, anon, authenticated;
grant execute on function public.hook_restrict_signup_to_electricabt(jsonb)
  to supabase_auth_admin;

-- Crea automáticamente el perfil interno después de un alta válida en Auth.
-- Se repite la comprobación de dominio como segunda barrera.
create or replace function public.handle_new_corporate_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if lower(split_part(coalesce(new.email, ''), '@', 2)) <> 'electricabt.com' then
    raise exception 'Acceso exclusivo para cuentas @electricabt.com';
  end if;

  insert into public.usuarios (id, email, nombre, rol, activo)
  values (
    new.id,
    lower(new.email),
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'),
    'tecnico',
    true
  )
  on conflict (id) do update
    set email = excluded.email,
        nombre = coalesce(excluded.nombre, public.usuarios.nombre),
        updated_at = now();

  return new;
end;
$$;

revoke execute on function public.handle_new_corporate_user()
  from public, anon, authenticated;

drop trigger if exists on_auth_user_created_gestion_bt on auth.users;
create trigger on_auth_user_created_gestion_bt
  after insert on auth.users
  for each row execute procedure public.handle_new_corporate_user();

-- Helpers privados para políticas RLS.
create or replace function private.current_user_active()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.usuarios u
    where u.id = (select auth.uid())
      and u.activo = true
      and lower(split_part(u.email, '@', 2)) = 'electricabt.com'
  );
$$;

create or replace function private.current_user_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select u.rol
  from public.usuarios u
  where u.id = (select auth.uid())
    and u.activo = true
    and lower(split_part(u.email, '@', 2)) = 'electricabt.com'
  limit 1;
$$;

revoke execute on function private.current_user_active() from public, anon;
revoke execute on function private.current_user_role() from public, anon;
grant execute on function private.current_user_active() to authenticated;
grant execute on function private.current_user_role() to authenticated;

-- =========================================================
-- NÚCLEO ADMINISTRATIVO
-- =========================================================

create table if not exists public.clientes (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  nombre_fiscal text,
  cif_nif text,
  telefono text,
  email text,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.suministros (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.clientes(id) on delete restrict,
  cups text,
  nombre text,
  direccion text,
  codigo_postal text,
  municipio text,
  provincia text,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (cups)
);

create table if not exists public.expedientes (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.clientes(id) on delete restrict,
  suministro_id uuid references public.suministros(id) on delete restrict,
  tipo text not null,
  titulo text not null,
  estado text not null default 'abierto',
  fecha_apertura date not null default current_date,
  fecha_cierre date,
  observaciones text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.documentos (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.clientes(id) on delete restrict,
  suministro_id uuid references public.suministros(id) on delete restrict,
  expediente_id uuid references public.expedientes(id) on delete set null,
  tipo text not null,
  nombre_archivo text not null,
  storage_path text not null,
  fecha_documento date,
  origen text,
  hash_archivo text,
  estado text not null default 'pendiente',
  created_at timestamptz not null default now()
);

create index if not exists documentos_hash_idx on public.documentos(hash_archivo);
create index if not exists documentos_suministro_idx on public.documentos(suministro_id);

create table if not exists public.historico (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.clientes(id) on delete restrict,
  suministro_id uuid references public.suministros(id) on delete restrict,
  expediente_id uuid references public.expedientes(id) on delete set null,
  documento_id uuid references public.documentos(id) on delete set null,
  tipo_evento text not null,
  descripcion text not null,
  fecha timestamptz not null default now(),
  origen text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.procesamientos (
  id uuid primary key default gen_random_uuid(),
  documento_id uuid not null references public.documentos(id) on delete cascade,
  parser text not null,
  parser_version text not null,
  estado text not null,
  fecha timestamptz not null default now(),
  datos_extraidos jsonb not null default '{}'::jsonb,
  errores jsonb not null default '[]'::jsonb,
  advertencias jsonb not null default '[]'::jsonb
);

-- =========================================================
-- RLS Y PRIVILEGIOS
-- =========================================================

alter table public.usuarios enable row level security;
alter table public.clientes enable row level security;
alter table public.suministros enable row level security;
alter table public.expedientes enable row level security;
alter table public.documentos enable row level security;
alter table public.historico enable row level security;
alter table public.procesamientos enable row level security;

-- El acceso anónimo queda explícitamente cerrado.
revoke all on table public.usuarios from anon;
revoke all on table public.clientes from anon;
revoke all on table public.suministros from anon;
revoke all on table public.expedientes from anon;
revoke all on table public.documentos from anon;
revoke all on table public.historico from anon;
revoke all on table public.procesamientos from anon;

-- Privilegios API para usuarios autenticados. RLS decide qué filas/acciones pasan.
grant select, update on table public.usuarios to authenticated;
grant select, insert, update on table public.clientes to authenticated;
grant select, insert, update on table public.suministros to authenticated;
grant select, insert, update on table public.expedientes to authenticated;
grant select, insert, update on table public.documentos to authenticated;
grant select, insert, update on table public.historico to authenticated;
grant select on table public.procesamientos to authenticated;

grant all on table public.usuarios to service_role;
grant all on table public.clientes to service_role;
grant all on table public.suministros to service_role;
grant all on table public.expedientes to service_role;
grant all on table public.documentos to service_role;
grant all on table public.historico to service_role;
grant all on table public.procesamientos to service_role;

-- USUARIOS: cada empleado ve su propio perfil; ADMIN puede ver y modificar todos.
drop policy if exists usuarios_select_self_or_admin on public.usuarios;
create policy usuarios_select_self_or_admin
on public.usuarios for select
to authenticated
using (
  id = (select auth.uid())
  or (select private.current_user_role()) = 'admin'
);

drop policy if exists usuarios_update_admin on public.usuarios;
create policy usuarios_update_admin
on public.usuarios for update
to authenticated
using ((select private.current_user_role()) = 'admin')
with check (
  (select private.current_user_role()) = 'admin'
  and lower(split_part(email, '@', 2)) = 'electricabt.com'
  and rol in ('admin', 'oficina', 'tecnico')
);

-- CLIENTES
drop policy if exists clientes_select_corporate on public.clientes;
create policy clientes_select_corporate
on public.clientes for select
to authenticated
using ((select private.current_user_active()));

drop policy if exists clientes_insert_office on public.clientes;
create policy clientes_insert_office
on public.clientes for insert
to authenticated
with check ((select private.current_user_role()) in ('admin', 'oficina'));

drop policy if exists clientes_update_office on public.clientes;
create policy clientes_update_office
on public.clientes for update
to authenticated
using ((select private.current_user_role()) in ('admin', 'oficina'))
with check ((select private.current_user_role()) in ('admin', 'oficina'));

-- SUMINISTROS
drop policy if exists suministros_select_corporate on public.suministros;
create policy suministros_select_corporate
on public.suministros for select
to authenticated
using ((select private.current_user_active()));

drop policy if exists suministros_insert_office on public.suministros;
create policy suministros_insert_office
on public.suministros for insert
to authenticated
with check ((select private.current_user_role()) in ('admin', 'oficina'));

drop policy if exists suministros_update_office on public.suministros;
create policy suministros_update_office
on public.suministros for update
to authenticated
using ((select private.current_user_role()) in ('admin', 'oficina'))
with check ((select private.current_user_role()) in ('admin', 'oficina'));

-- EXPEDIENTES
drop policy if exists expedientes_select_corporate on public.expedientes;
create policy expedientes_select_corporate
on public.expedientes for select
to authenticated
using ((select private.current_user_active()));

drop policy if exists expedientes_insert_office on public.expedientes;
create policy expedientes_insert_office
on public.expedientes for insert
to authenticated
with check ((select private.current_user_role()) in ('admin', 'oficina'));

drop policy if exists expedientes_update_office on public.expedientes;
create policy expedientes_update_office
on public.expedientes for update
to authenticated
using ((select private.current_user_role()) in ('admin', 'oficina'))
with check ((select private.current_user_role()) in ('admin', 'oficina'));

-- DOCUMENTOS
drop policy if exists documentos_select_corporate on public.documentos;
create policy documentos_select_corporate
on public.documentos for select
to authenticated
using ((select private.current_user_active()));

drop policy if exists documentos_insert_office on public.documentos;
create policy documentos_insert_office
on public.documentos for insert
to authenticated
with check ((select private.current_user_role()) in ('admin', 'oficina'));

drop policy if exists documentos_update_office on public.documentos;
create policy documentos_update_office
on public.documentos for update
to authenticated
using ((select private.current_user_role()) in ('admin', 'oficina'))
with check ((select private.current_user_role()) in ('admin', 'oficina'));

-- HISTÓRICO
drop policy if exists historico_select_corporate on public.historico;
create policy historico_select_corporate
on public.historico for select
to authenticated
using ((select private.current_user_active()));

drop policy if exists historico_insert_office on public.historico;
create policy historico_insert_office
on public.historico for insert
to authenticated
with check ((select private.current_user_role()) in ('admin', 'oficina'));

drop policy if exists historico_update_office on public.historico;
create policy historico_update_office
on public.historico for update
to authenticated
using ((select private.current_user_role()) in ('admin', 'oficina'))
with check ((select private.current_user_role()) in ('admin', 'oficina'));

-- PROCESAMIENTOS: lectura corporativa. Escritura reservada al backend/parser.
drop policy if exists procesamientos_select_corporate on public.procesamientos;
create policy procesamientos_select_corporate
on public.procesamientos for select
to authenticated
using ((select private.current_user_active()));

-- No se conceden DELETE a usuarios autenticados en V0.1.
-- El borrado funcional se resolverá con estados/activo para conservar trazabilidad.
