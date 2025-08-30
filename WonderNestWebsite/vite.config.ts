import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 3001,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        secure: false,
        configure: (proxy, _options) => {
          proxy.on('proxyReq', (proxyReq, req, res) => {
            // Log the request body for debugging
            if (req.method === 'POST' && req.url?.includes('/auth/parent/login')) {
              let body = ''
              req.on('data', (chunk) => {
                body += chunk.toString()
              })
              req.on('end', () => {
                console.log('Login request body:', body)
                // Don't modify the body, just log it
              })
            }
          })
        },
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