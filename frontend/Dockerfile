# Build from repository root: docker build -f frontend/Dockerfile .
FROM node:24.22.0-bookworm-slim AS build
WORKDIR /app/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
ARG VITE_SITE_URL
ARG VITE_WHATSAPP_NUMBER
ARG VITE_DOWNLOAD_ENABLED=true
ENV VITE_SITE_URL=$VITE_SITE_URL VITE_WHATSAPP_NUMBER=$VITE_WHATSAPP_NUMBER VITE_DOWNLOAD_ENABLED=$VITE_DOWNLOAD_ENABLED
RUN npm run check

FROM node:24.22.0-bookworm-slim AS runtime
ENV NODE_ENV=production HOST=0.0.0.0 PORT=8080
WORKDIR /app
COPY --from=build --chown=node:node /app/frontend/dist ./dist
COPY --from=build --chown=node:node /app/frontend/package.json /app/frontend/server.js /app/frontend/workspace-routes.js /app/frontend/workspace-headers.js /app/frontend/public-settings.js ./
COPY --from=build --chown=node:node /app/frontend/api ./api
USER node
EXPOSE 8080
CMD ["node", "server.js"]

# Keep the existing Dokploy build target compatible with this runtime.
FROM runtime AS Production
