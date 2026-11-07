"""Minimal app for the AI platform: health check, database check and Vertex AI check.

The check endpoints only answer "ok" or "failed"; error details go to Cloud Logging only.
"""
import logging
import os
import threading

from flask import Flask, jsonify

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("app")

app = Flask(__name__)

APP_ENV = os.environ.get("APP_ENV", "local")
APP_NAME = os.environ.get("K_SERVICE", "app")  # set by Cloud Run

_connector = None
_connector_lock = threading.Lock()


def _get_connector():
    global _connector
    with _connector_lock:
        if _connector is None:
            from google.cloud.sql.connector import Connector, IPTypes

            # TLS and authorization by the Cloud SQL connector; private IP via Direct VPC egress.
            _connector = Connector(ip_type=IPTypes.PRIVATE, refresh_strategy="lazy")
        return _connector


@app.get("/api/health")
def health():
    return jsonify(status="ok")


@app.get("/api/check/db")
def check_db():
    try:
        conn = _get_connector().connect(
            os.environ["DB_INSTANCE"],
            "pg8000",
            user=os.environ["DB_USER"],
            password=os.environ["DB_PASSWORD"],
            db=os.environ["DB_NAME"],
        )
        try:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            ok = cur.fetchone()[0] == 1
        finally:
            conn.close()
    except Exception:
        log.exception("db check failed")
        ok = False
    return jsonify(db="ok" if ok else "failed"), 200 if ok else 503


@app.get("/api/check/vertex")
def check_vertex():
    try:
        from google import genai
        from google.genai import types

        client = genai.Client(
            vertexai=True,
            project=os.environ["VERTEX_PROJECT"],
            location=os.environ.get("VERTEX_LOCATION", "global"),
        )
        resp = client.models.generate_content(
            model=os.environ.get("VERTEX_MODEL", "gemini-2.5-flash"),
            contents="Answer only: ok",
            # Labels split the model cost per environment and app in the billing report.
            config=types.GenerateContentConfig(labels={"environment": APP_ENV, "app": APP_NAME}),
        )
        ok = bool(resp.candidates)
    except Exception:
        log.exception("vertex check failed")
        ok = False
    return jsonify(vertex="ok" if ok else "failed"), 200 if ok else 503
