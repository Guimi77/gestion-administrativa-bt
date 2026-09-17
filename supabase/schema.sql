-- Gestión Administrativa BT - esquema inicial V0.1
-- IMPORTANTE: no contiene datos reales ni credenciales.

create extension if not exists pgcrypto;

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

-- RLS: habilitada desde el principio. Las políticas concretas se añadirán
-- cuando definamos el modelo de usuarios y permisos.
alter table public.clientes enable row level security;
alter table public.suministros enable row level security;
alter table public.expedientes enable row level security;
alter table public.documentos enable row level security;
alter table public.historico enable row level security;
alter table public.procesamientos enable row level security;
