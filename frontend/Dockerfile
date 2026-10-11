# Build context: frontend/ (see README for Dokploy's Dockerfile settings).
FROM node:22-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --include=dev
COPY . .

# Public React build configuration. Set these in Dokploy's Build Time Arguments.
ARG VITE_SITE_URL
ARG VITE_WHATSAPP_NUMBER
ARG VITE_DOWNLOAD_URL
ARG VITE_RELEASE_API_URL
ARG VITE_DOWNLOAD_ENABLED
ENV VITE_SITE_URL=${VITE_SITE_URL} \
    VITE_WHATSAPP_NUMBER=${VITE_WHATSAPP_NUMBER} \
    VITE_DOWNLOAD_URL=${VITE_DOWNLOAD_URL} \
    VITE_RELEASE_API_URL=${VITE_RELEASE_API_URL} \n    VITE_DOWNLOAD_ENABLED=${VITE_DOWNLOAD_ENABLED}

RUN npm run check

FROM nginx:stable-alpine AS production
COPY nginx.container.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/ /usr/share/nginx/html/
RUN nginx -t
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1
CMD ["nginx", "-g", "daemon off;"]
