# Arquitectura V0.1

## Núcleo de dominio

La aplicación se organiza alrededor de cinco entidades principales:

```text
Cliente
  |
  +-- Suministro
  |     |
  |     +-- Documento
  |     +-- Expediente
  |     +-- Histórico
  |
  +-- Contactos (futuro)
```

## Responsabilidades

### Cliente
Entidad administrativa principal. Puede disponer de uno o muchos suministros.

### Suministro
Representa un punto de suministro, normalmente identificado por CUPS. Un cliente puede tener múltiples suministros activos o históricos.

### Documento
Archivo asociado a cliente, suministro y opcionalmente expediente. Los binarios reales deberán residir en almacenamiento privado.

### Expediente
Agrupa actuaciones administrativas o técnicas relacionadas con un cliente o suministro.

### Histórico
Registro cronológico de eventos. No debe depender de textos libres sin estructura: cada evento conserva tipo, origen y relaciones.

## Procesamiento de documentos

Los parsers se tratarán como componentes externos/versionados. Cada ejecución debe guardar:

- documento origen
- nombre del parser
- versión
- estado
- datos extraídos
- errores
- advertencias

Esto permite reprocesar documentos antiguos sin perder trazabilidad.

## Integraciones

Las integraciones deben ser aditivas y desacopladas.

```text
Gestión Administrativa BT
       |
       +--> Asesor Energético
       +--> Xispa
       +--> CAD Unifilar
       +--> Odoo
```

Ningún proyecto externo debe ser necesario para el funcionamiento básico de Gestión Administrativa BT.

## Contratos versionados

Las integraciones futuras usarán objetos versionados, por ejemplo:

```json
{
  "version": "1.0",
  "source": "asesor-energetico",
  "type": "energy_invoice_analysis",
  "payload": {}
}
```

## No regresión

Antes de integrar cualquier módulo externo:

1. Ejecutar pruebas existentes.
2. Añadir pruebas específicas de la integración.
3. Verificar que clientes, suministros, documentos, expedientes e histórico siguen funcionando.
4. No publicar cambios con regresiones conocidas.
