FROM debian:trixie-slim

# Headless Qt for QGIS
ENV QT_QPA_PLATFORM=offscreen

RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-qgis python3-pip && \
    rm -rf /var/lib/apt/lists/*

COPY ./bridge-style /tmp/bridge-style
COPY requirements.txt /tmp/

RUN python3 -m pip install --break-system-packages --disable-pip-version-check --no-cache-dir /tmp/bridge-style && \
    python3 -m pip install --break-system-packages --disable-pip-version-check --no-cache-dir --requirement=/tmp/requirements.txt && \
    rm --recursive --force /tmp/*

COPY ./app /app

WORKDIR /app

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
