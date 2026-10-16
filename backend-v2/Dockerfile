FROM node:24.22.0-bookworm-slim
ENV NODE_ENV=production HOST=0.0.0.0
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --chown=node:node src ./src
COPY --chown=node:node services ./services
COPY --chown=node:node database ./database
COPY --chown=node:node scripts ./scripts
COPY --chown=node:node config ./config
USER node
CMD ["node", "services/gateway/index.js"]
