# Context: repository root. Only this backend and shared libraries are copied.
FROM node:24.22.0-bookworm-slim
ENV NODE_ENV=production HOST=0.0.0.0
WORKDIR /app
COPY App-backend/package.json App-backend/package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts --no-audit --no-fund && npm cache clean --force
COPY --chown=node:node backend-v2/shared ./backend-v2/shared
COPY --chown=node:node backend-v2/database ./backend-v2/database
COPY --chown=node:node App-backend ./App-backend
USER node
CMD ["node", "App-backend/index.js"]
