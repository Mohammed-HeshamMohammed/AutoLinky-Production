# Context: Fetching-backend/. This backend has no sibling source dependencies.
FROM node:24.22.0-bookworm-slim AS Production
ENV NODE_ENV=production HOST=0.0.0.0
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts --no-audit --no-fund && npm cache clean --force
COPY --chown=node:node index.js app.js ./
COPY --chown=node:node lib ./lib
COPY --chown=node:node src ./src
USER node
CMD ["node", "index.js"]
