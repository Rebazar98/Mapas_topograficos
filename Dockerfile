FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# QGIS y dependencias
RUN apt-get update && apt-get install -y \
    gnupg software-properties-common curl ca-certificates \
    && add-apt-repository ppa:ubuntugis/ubuntugis-unstable -y \
    && apt-get update && apt-get install -y \
       qgis qgis-server python3-qgis gdal-bin python3-pip xvfb \
       fonts-dejavu-core \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Modo offscreen para QGIS
ENV QT_QPA_PLATFORM=offscreen
ENV XDG_RUNTIME_DIR=/tmp/runtime-root
RUN mkdir -p /tmp/runtime-root && chmod 700 /tmp/runtime-root

WORKDIR /app

# ─────────────────────────────────────────────
# Descarga de capas pesadas desde el release 1.0.1 (topografia)
# Sustituye NOMBRE_DEL_REPO por el nombre REAL de tu repo
# ─────────────────────────────────────────────
RUN mkdir -p /app/data && \
    curl -L "https://github.com/Rebazar98/topografia/releases/download/1.0.1/Curvas_Nivel_DIRECTORAS_H0013.gml" \
      -o /app/data/Curvas_Nivel_DIRECTORAS_H0013.gml && \
    curl -L "https://github.com/Rebazar98/topografia/releases/download/1.0.1/Curvas_Nivel_Intermedias_H0013.gml" \
      -o /app/data/Curvas_Nivel_Intermedias_H0013.gml && \
    curl -L "https://github.com/Rebazar98/topografia/releases/download/1.0.1/Red_fluvial.gml" \
      -o /app/data/Red_fluvial.gml && \
    curl -L "https://github.com/Rebazar98/topografia/releases/download/1.0.1/T0056_edificacion_S.gml" \
      -o /app/data/T0056_edificacion_S.gml

# Proyecto QGIS y datos ligeros (van dentro del repo)
COPY proyecto.qgz       /app/proyecto.qgz
COPY capas_parcela.gpkg /app/capas_parcela.gpkg
COPY app.py             /app/app.py

# FastAPI + Uvicorn
RUN pip3 install fastapi uvicorn[standard] pydantic

ENV PORT=8080
EXPOSE 8080

CMD ["uvicorn","app:app","--host","0.0.0.0","--port","8080"]
