// https://github.com/tapio/live-server
import server from 'live-server'
const { start } = server

const params = {
  port: 8080,
  host: '0.0.0.0',
  root: '../dist/web',
  open: false,
  ignore: '',
  wait: 100, // Waits for all changes, before reloading
  middleware: [
    function (_req, res, next) {
      res.setHeader('Cross-Origin-Opener-Policy', 'same-origin')
      res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp')
      next()
    }
  ]
}

start(params)
