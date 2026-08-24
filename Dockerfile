FROM python:3.12

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd --system --no-create-home appuser
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]

# FROM python:3.12.14-slim AS builder

# WORKDIR /app

# COPY requirements.txt .

# RUN python -m venv /opt/venv && \
#     /opt/venv/bin/pip install --no-cache-dir --upgrade pip && \
#     /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# FROM python:3.12.14-slim

# ENV PYTHONDONTWRITEBYTECODE=1 \
#     PYTHONUNBUFFERED=1 \
#     PATH="/opt/venv/bin:$PATH"

# WORKDIR /app

# COPY --from=builder /opt/venv /opt/venv

# RUN useradd --system --no-create-home appuser

# COPY --chown=appuser:appuser . .

# USER appuser

# EXPOSE 8080

# HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
#     CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"

# CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]