# Context: App-backend/. This backend has no sibling source dependencies.
FROM node:24.22.0-bookworm-slim AS Production
ENV NODE_ENV=production HOST=0.0.0.0
WORKDIR /app
COPY extractor/requirements.txt ./extractor/requirements.txt
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-venv \
    && python3 -m venv /opt/cv-parser \
    && /opt/cv-parser/bin/pip install --no-cache-dir -r extractor/requirements.txt \
    && rm -rf /var/lib/apt/lists/*
ENV PATH="/opt/cv-parser/bin:${PATH}"
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts --no-audit --no-fund && npm cache clean --force
COPY --chown=node:node index.js app.js routes.js ./
COPY --chown=node:node lib ./lib
COPY --chown=node:node src ./src
COPY --chown=node:node extractor ./extractor
USER node
CMD ["node", "index.js"]
