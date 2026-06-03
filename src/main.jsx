import { Component, StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'

console.info('FloodGuard client boot 2026-06-03-a')

class AppErrorBoundary extends Component {
  constructor(props) {
    super(props)
    this.state = { error: null }
  }

  static getDerivedStateFromError(error) {
    return { error }
  }

  componentDidCatch(error, info) {
    console.error('Application render error:', error, info)
  }

  render() {
    if (this.state.error) {
      return (
        <div style={{ fontFamily: 'Arial, sans-serif', padding: 32, color: '#991b1b' }}>
          <h1 style={{ fontSize: 24, marginBottom: 12 }}>Ứng dụng gặp lỗi khi khởi động</h1>
          <p>Vui lòng mở Console hoặc Render logs để xem chi tiết lỗi.</p>
          <pre style={{ whiteSpace: 'pre-wrap', marginTop: 16 }}>
            {this.state.error?.message || String(this.state.error)}
          </pre>
        </div>
      )
    }

    return this.props.children
  }
}

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <AppErrorBoundary>
      <App />
    </AppErrorBoundary>
  </StrictMode>,
)
