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

## Principios

1. **Independencia entre proyectos.** Gestión Administrativa BT no depende de Xispa, CAD Unifilar, Asesor Energético ni Odoo para funcionar.
2. **No regresión.** Las integraciones futuras se añaden mediante interfaces versionadas y pruebas.
3. **Privacidad.** Este repositorio es público. Nunca se guardarán aquí documentos reales, nombres de clientes, direcciones, CUPS, teléfonos, CIF/NIF ni credenciales.
4. **Trazabilidad.** Los datos extraídos de documentos deben conservar su origen, parser y versión.
5. **Seguridad desde el diseño.** Los datos reales vivirán en almacenamiento privado y la autorización se implementará con RLS en Supabase.
6. **No inventar datos.** Los datos desconocidos o ambiguos deben quedar pendientes de revisión.

## Arquitectura prevista

```text
GitHub Pages / Web App
        |
        v
     Supabase
  + PostgreSQL
  + Auth
  + Storage privado
  + RLS
        |
        +--> Integraciones externas versionadas
             - Asesor Energético
             - Xispa
             - CAD Unifilar
             - Odoo
```

## Estado

Proyecto iniciado. La V0.1 se centra en el contrato de datos y la navegación básica antes de incorporar parsers, IA o integraciones externas.
