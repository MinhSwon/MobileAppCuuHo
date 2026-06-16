import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { AdminSidebar, RescueSidebar, CitizenSidebar } from './Sidebar';
import { AdminHeader, RescueHeader, CitizenHeader } from './Header';

export function AdminLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: 'var(--bg-base)' }}>
      <AdminSidebar isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="main-content" style={{ flex: 1 }}>
        <AdminHeader onMenuClick={() => setSidebarOpen(true)} />
        <main style={{ minHeight: 'calc(100vh - 60px)' }}>
          <Outlet />
        </main>
      </div>
    </div>
  );
}

export function RescueLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: 'var(--bg-base)' }}>
      <RescueSidebar isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="main-content" style={{ flex: 1 }}>
        <RescueHeader onMenuClick={() => setSidebarOpen(true)} />
        <main style={{ minHeight: 'calc(100vh - 60px)' }}>
          <Outlet />
        </main>
      </div>
    </div>
  );
}

export function CitizenLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: 'var(--bg-base)' }}>
      <CitizenSidebar isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="main-content" style={{ flex: 1 }}>
        <CitizenHeader onMenuClick={() => setSidebarOpen(true)} />
        <main style={{ minHeight: 'calc(100vh - 60px)' }}>
          <Outlet />
        </main>
      </div>
    </div>
  );
}
