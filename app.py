import os
import tempfile
import subprocess
import shlex
import json
from typing import List, Tuple, Optional

from fastapi import FastAPI, Query
from fastapi.responses import FileResponse, JSONResponse

app = FastAPI(title="QGIS Imágenes por refcat - Nuevo proyecto")

# Config desde variables de entorno (Railway) o por defecto
QGIS_PROJECT = os.getenv("QGIS_PROJECT", "/app/proyecto.qgz")
QGIS_LAYOUT  = os.getenv("QGIS_LAYOUT",  "Plano_urbanistico_parcela")
QGIS_ALGO    = os.getenv("QGIS_ALGO",    "native:atlaslayouttoimage")

def run_proc(
    cmd: List[str],
    extra_env: Optional[dict] = None,
    stdin_text: Optional[str] = None,
    timeout: int = 120,
) -> Tuple[int, str, str]:
    env = os.environ.copy()
    env.setdefault("QT_QPA_PLATFORM", "offscreen")
    env.setdefault("XDG_RUNTIME_DIR", "/tmp/runtime-root")
    os.makedirs(env["XDG_RUNTIME_DIR"], exist_ok=True)

    if extra_env:
        env.update(extra_env)

    try:
        p = subprocess.run(
            cmd,
            input=stdin_text,
            text=True,
            capture_output=True,
            env=env,
            timeout=timeout,
        )
        return p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired as e:
        return 124, e.stdout or "", (e.stderr or "") + "\n[TIMEOUT EXPIRED]"

@app.get("/health")
def health():
    return {
        "status": "ok",
        "project": QGIS_PROJECT,
        "layout": QGIS_LAYOUT,
        "algo": QGIS_ALGO,
    }

@app.get("/render")
def render(
    refcat: str = Query(..., min_length=3),
    debug: int = Query(0, description="Si !=0, devuelve JSON de debug en vez del PNG"),
):
    if not os.path.exists(QGIS_PROJECT):
        return JSONResponse(
            status_code=500,
            content={"error": "Proyecto no encontrado", "path": QGIS_PROJECT},
        )

    outdir = tempfile.mkdtemp()

    payload = {
        "inputs": {
            "LAYOUT": QGIS_LAYOUT,
            "FOLDER": outdir,
        },
        "project_path": QGIS_PROJECT,
    }
    payload_json = json.dumps(payload)

    cmd: List[str] = [
        "xvfb-run",
        "-a",
        "qgis_process",
        "run",
        QGIS_ALGO,  # native:atlaslayouttoimage
        "-",
    ]

    extra_env = {"REFCAT": refcat}

    code, out, err = run_proc(cmd, extra_env=extra_env, stdin_text=payload_json)

    img_files = [f for f in os.listdir(outdir) if f.endswith(".png")]
    img_path = os.path.join(outdir, img_files[0]) if img_files else None

    if debug or code != 0 or not img_path or not os.path.exists(img_path):
        return JSONResponse(
            status_code=500 if code != 0 else 200,
            content={
                "refcat": refcat,
                "cmd": " ".join(shlex.quote(c) for c in cmd),
                "stdout": out,
                "stderr": err,
                "exit_code": code,
                "output_exists": bool(img_path),
                "output_size": os.path.getsize(img_path) if img_path else 0,
                "payload": payload,
            },
        )

    return FileResponse(
        img_path,
        media_type="image/png",
        filename=f"informe_{refcat}.png",
    )
