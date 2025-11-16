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

# 🔸 Ortofoto del NUEVO proyecto
# Sube la ortofoto a un Release del nuevo repo y cambia la URL:
RUN curl -L "https://github.com/TU_USUARIO/TU_NUEVO_REPO/releases/download/v0.1.0/ortofoto_nueva.tif" \
    -o /app/ortofoto_nueva.tif

# 🔸 Proyecto QGIS y datos vectoriales del NUEVO proyecto
# (asegúrate de que el .qgz usa rutas relativas a estos nombres)
COPY proyecto.qgz        /app/proyecto.qgz
COPY capas_parcela.gpkg  /app/capas_parcela.gpkg
COPY capas_contexto.gpkg /app/capas_contexto.gpkg
COPY app.py              /app/app.py

# FastAPI + Uvicorn
RUN pip3 install fastapi uvicorn[standard] pydantic

ENV PORT=8080
EXPOSE 8080

CMD ["uvicorn","app:app","--host","0.0.0.0","--port","8080"]
