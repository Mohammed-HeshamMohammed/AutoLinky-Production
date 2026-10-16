import { defineConfig } from 'vite';

export default defineConfig({
  server: {
    proxy: {
      '/v1': 'http://127.0.0.1:8080',
      '/health': 'http://127.0.0.1:8080',
      '/app': 'http://127.0.0.1:8080',
      '/download': 'http://127.0.0.1:8080',
      '/api/latest': 'http://127.0.0.1:8080',
    },
  },
});
