PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS usuarios (
  id TEXT PRIMARY KEY NOT NULL,
  email TEXT NOT NULL COLLATE NOCASE UNIQUE,
  nombre TEXT,
  rol TEXT NOT NULL DEFAULT 'tecnico' CHECK (rol IN ('admin','oficina','tecnico')),
  activo INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0,1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS clientes (
  id TEXT PRIMARY KEY NOT NULL,
  nombre TEXT NOT NULL,
  nombre_fiscal TEXT,
  cif_nif TEXT,
  telefono TEXT,
  email TEXT,
  activo INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0,1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS suministros (
  id TEXT PRIMARY KEY NOT NULL,
  cliente_id TEXT NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
  cups TEXT COLLATE NOCASE UNIQUE,
  nombre TEXT,
  direccion TEXT,
  codigo_postal TEXT,
  municipio TEXT,
  provincia TEXT,
  activo INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0,1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS expedientes (
  id TEXT PRIMARY KEY NOT NULL,
  cliente_id TEXT NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
  suministro_id TEXT REFERENCES suministros(id) ON DELETE RESTRICT,
  tipo TEXT NOT NULL,
  titulo TEXT NOT NULL,
  estado TEXT NOT NULL DEFAULT 'abierto',
  fecha_apertura TEXT NOT NULL DEFAULT CURRENT_DATE,
  fecha_cierre TEXT,
  observaciones TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS documentos (
  id TEXT PRIMARY KEY NOT NULL,
  cliente_id TEXT NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
  suministro_id TEXT REFERENCES suministros(id) ON DELETE RESTRICT,
  expediente_id TEXT REFERENCES expedientes(id) ON DELETE SET NULL,
  tipo TEXT NOT NULL,
  nombre_archivo TEXT NOT NULL,
  storage_provider TEXT NOT NULL DEFAULT 'onedrive',
  external_id TEXT,
  web_url TEXT,
  ruta_logica TEXT,
  fecha_documento TEXT,
  origen TEXT,
  hash_archivo TEXT,
  estado TEXT NOT NULL DEFAULT 'pendiente',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS historico (
  id TEXT PRIMARY KEY NOT NULL,
  cliente_id TEXT NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
  suministro_id TEXT REFERENCES suministros(id) ON DELETE RESTRICT,
  expediente_id TEXT REFERENCES expedientes(id) ON DELETE SET NULL,
  documento_id TEXT REFERENCES documentos(id) ON DELETE SET NULL,
  tipo_evento TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  fecha TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  origen TEXT,
  metadata TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS procesamientos (
  id TEXT PRIMARY KEY NOT NULL,
  documento_id TEXT NOT NULL REFERENCES documentos(id) ON DELETE CASCADE,
  parser TEXT NOT NULL,
  parser_version TEXT NOT NULL,
  estado TEXT NOT NULL,
  fecha TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  datos_extraidos TEXT NOT NULL DEFAULT '{}',
  errores TEXT NOT NULL DEFAULT '[]',
  advertencias TEXT NOT NULL DEFAULT '[]'
);

CREATE INDEX IF NOT EXISTS suministros_cliente_idx ON suministros(cliente_id);
CREATE INDEX IF NOT EXISTS expedientes_cliente_idx ON expedientes(cliente_id);
CREATE INDEX IF NOT EXISTS expedientes_suministro_idx ON expedientes(suministro_id);
CREATE INDEX IF NOT EXISTS documentos_hash_idx ON documentos(hash_archivo);
CREATE INDEX IF NOT EXISTS documentos_suministro_idx ON documentos(suministro_id);
CREATE INDEX IF NOT EXISTS documentos_external_id_idx ON documentos(external_id);
CREATE INDEX IF NOT EXISTS historico_suministro_idx ON historico(suministro_id);
CREATE INDEX IF NOT EXISTS historico_fecha_idx ON historico(fecha DESC);
