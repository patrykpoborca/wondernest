import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        secure: false,
        // Don't buffer file uploads to preserve multipart stream
        buffer: false,
        // Preserve headers for multipart requests
        followRedirects: false,
        // Don't modify request body for uploads
        configure: (proxy, options) => {
          proxy.on('proxyReq', (proxyReq, req, res) => {
            if (req.url?.includes('/files/upload')) {
              // Don't modify Content-Length for multipart uploads
              proxyReq.setHeader('transfer-encoding', 'chunked');
            }
          });
        }
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
  resolve: {
    alias: {
      '@': '/src',
    },
  },
})