# Mapas_topograficos

Variante de [qgis-informes](https://github.com/Rebazar98/qgis-informes) para generar **planos topográficos** de una parcela a partir de su referencia catastral, con QGIS headless en Docker.

La referencia catastral se pasa al proyecto QGIS como variable de entorno (`REFCAT`) y el atlas del proyecto QGIS topográfico (`Topo.qgz`) se exporta a imagen.

## Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/health` | Estado y configuración activa |
| GET | `/render?refcat=&debug=0` | Devuelve el plano en PNG (con `debug=1`, JSON con la salida de QGIS) |

## Ejecución

```bash
docker build -t mapas-topograficos .
docker run -p 8080:8080 mapas-topograficos
```

Incluye control de tiempo máximo de renderizado (timeout) y modo depuración.

## Stack

Python · FastAPI · QGIS (`qgis_process`) · Docker
