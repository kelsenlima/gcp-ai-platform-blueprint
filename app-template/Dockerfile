FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 PORT=8080
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# With a home directory: gunicorn writes to $HOME (without it, it logs "Control server error").
RUN useradd --uid 10001 --create-home app
USER app

# No HEALTHCHECK: Cloud Run ignores it. Probes are configured on the service (/api/health).
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
