FROM node:24-slim AS frontend-builder
WORKDIR /build
COPY package.json package-lock.json ./
RUN npm ci
COPY frontend ./frontend
COPY tsconfig.json vite.config.ts ./
RUN npm run build

FROM python:3.11-slim AS python-builder
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
COPY requirements.txt /tmp/requirements.txt
RUN python -m venv /opt/venv && /opt/venv/bin/pip install --no-cache-dir -r /tmp/requirements.txt

FROM python:3.11-slim AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PATH="/opt/venv/bin:$PATH"
WORKDIR /srv/sanket
COPY --from=python-builder /opt/venv /opt/venv
COPY app ./app
COPY --from=frontend-builder /build/app/static/dist ./app/static/dist
RUN useradd --create-home --uid 10001 sanket && chown -R sanket:sanket /srv/sanket
USER sanket
EXPOSE 8000 10000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD python -c "import urllib.request, os; p=os.getenv('PORT','8000'); urllib.request.urlopen(f'http://127.0.0.1:{p}/healthz', timeout=2)"
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]

