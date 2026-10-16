# Context: backend-v2/. This image contains only this backend and shared libraries.
FROM node:24.22.0-bookworm-slim
ENV NODE_ENV=production HOST=0.0.0.0
WORKDIR /app
COPY services/auth/package.json services/auth/package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts --no-audit --no-fund && npm cache clean --force
COPY --chown=node:node shared ./shared
COPY --chown=node:node database ./database
COPY --chown=node:node services/auth ./services/auth
USER node
CMD ["node", "services/auth/index.js"]
