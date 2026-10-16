import { defineConfig } from 'vite';

export default defineConfig({
  server: {
    proxy: {
      '/app': 'http://127.0.0.1:8080',
      '/download': 'http://127.0.0.1:8080',
      '/api/latest': 'http://127.0.0.1:8080',
    },
  },
});
