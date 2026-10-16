# Build from repository root: docker build -f frontend/Dockerfile .
FROM node:24.22.0-bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends git curl unzip xz-utils python3 ca-certificates && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch 3.47.7 https://github.com/flutter/flutter.git /opt/flutter && test "$(git -C /opt/flutter rev-parse HEAD)" = abaf9c523780a608bd46686fd5e53740a07077f8
ENV FLUTTER_ROOT=/opt/flutter AUTOLINKY_FLUTTER_ROOT=/opt/flutter PATH=/opt/flutter/bin:$PATH FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true
RUN flutter --version
WORKDIR /app/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
COPY ["mobile apps/shared/", "/app/mobile apps/shared/"]
ARG VITE_SITE_URL
ARG VITE_WHATSAPP_NUMBER
ARG VITE_DOWNLOAD_ENABLED=true
ARG APP_API_BASE_URL
ENV VITE_SITE_URL=$VITE_SITE_URL VITE_WHATSAPP_NUMBER=$VITE_WHATSAPP_NUMBER VITE_DOWNLOAD_ENABLED=$VITE_DOWNLOAD_ENABLED APP_API_BASE_URL=$APP_API_BASE_URL
RUN npm run check

FROM node:24.22.0-bookworm-slim AS runtime
ENV NODE_ENV=production HOST=0.0.0.0 PORT=8080
WORKDIR /app
COPY --from=build --chown=node:node /app/frontend/dist ./dist
COPY --from=build --chown=node:node /app/frontend/package.json /app/frontend/server.js ./
COPY --from=build --chown=node:node /app/frontend/api ./api
USER node
EXPOSE 8080
CMD ["node", "server.js"]
