import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Menu, Bell, LogOut, ChevronDown } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { useData } from '../../contexts/DataContext';

export function AdminHeader({ onMenuClick }) {
  const { currentUser, logout } = useAuth();
  const { notifications, markNotificationRead, rescueRequests } = useData();
  const navigate = useNavigate();
  const [showNotifs, setShowNotifs] = useState(false);
  const [showUser, setShowUser] = useState(false);

  const unread = notifications.filter(n => !n.is_read && n.user_id === currentUser?.id);
  const sosCount = rescueRequests.filter(r => r.sos_mode && r.status === 'PENDING').length;

  return (
    <header className="header">
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.875rem' }}>
        <button
          onClick={onMenuClick}
          style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#9e9282', display: 'flex', alignItems: 'center', padding: 4 }}
        >
          <Menu size={18} />
        </button>
        {/* Breadcrumb placeholder */}
        <div style={{ fontSize: '0.72rem', color: '#b8afa5', letterSpacing: '0.04em', fontWeight: 500 }}>
          Trung tâm điều phối cứu hộ Việt Nam
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '0.625rem' }}>
        {/* SOS urgent badge */}
        {sosCount > 0 && (
          <button
            onClick={() => navigate('/admin/rescue-requests')}
            style={{
              display: 'flex', alignItems: 'center', gap: '0.375rem',
              background: '#f5e8e8', border: '1px solid #d8b0b0', borderRadius: 6,
              padding: '0.25rem 0.625rem', cursor: 'pointer',
              color: '#a04040', fontSize: '0.7rem', fontWeight: 600,
              animation: 'sosBlink 1.2s ease infinite',
            }}
          >
            🆘 {sosCount} SOS
          </button>
        )}

        {/* Notifications */}
        <div style={{ position: 'relative' }}>
          <button
            onClick={() => { setShowNotifs(!showNotifs); setShowUser(false); }}
            style={{
              position: 'relative',
              background: unread.length > 0 ? '#f5ece8' : 'none',
              border: `1px solid ${unread.length > 0 ? '#d8c0b0' : 'transparent'}`,
              borderRadius: 6, padding: '0.3rem', cursor: 'pointer',
              display: 'flex', alignItems: 'center',
              color: unread.length > 0 ? '#a07040' : '#9e9282',
            }}
          >
            <Bell size={17} />
            {unread.length > 0 && (
              <span style={{
                position: 'absolute', top: -3, right: -3,
                background: '#a04040', color: 'white', borderRadius: '50%',
                width: 14, height: 14, fontSize: '0.58rem', fontWeight: 700,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {unread.length}
              </span>
            )}
          </button>

          {showNotifs && (
            <div style={{
              position: 'absolute', right: 0, top: 'calc(100% + 8px)',
              background: 'white', border: '1px solid #e2dbd0', borderRadius: 12,
              boxShadow: '0 8px 24px rgba(42,37,32,0.12)', width: 300, zIndex: 100,
              maxHeight: 380, display: 'flex', flexDirection: 'column',
            }}>
              <div style={{ padding: '0.75rem 1rem', borderBottom: '1px solid #ede8e0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontFamily: "'Lora', serif", fontWeight: 600, fontSize: '0.82rem', color: '#2a2520' }}>Thông báo</span>
                {unread.length > 0 && (
                  <button
                    style={{ fontSize: '0.68rem', color: '#4a6fa5', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 500 }}
                    onClick={() => unread.forEach(n => markNotificationRead(n.id))}
                  >
                    Đánh dấu tất cả đã đọc
                  </button>
                )}
              </div>
              <div style={{ overflowY: 'auto', flex: 1 }}>
                {notifications.filter(n => n.user_id === currentUser?.id).slice(0, 10).map(n => (
                  <div
                    key={n.id}
                    onClick={() => markNotificationRead(n.id)}
                    style={{
                      padding: '0.7rem 1rem',
                      borderBottom: '1px solid #f5f1eb',
                      background: n.is_read ? 'white' : '#faf7f2',
                      cursor: 'pointer',
                    }}
                  >
                    <div style={{ fontSize: '0.75rem', fontWeight: 600, color: '#2a2520', marginBottom: 2 }}>{n.title}</div>
                    <div style={{ fontSize: '0.68rem', color: '#9e9282', lineHeight: 1.4 }}>{n.message}</div>
                    <div style={{ fontSize: '0.62rem', color: '#b8afa5', marginTop: 4 }}>
                      {new Date(n.created_at).toLocaleString('vi-VN')}
                    </div>
                  </div>
                ))}
                {notifications.filter(n => n.user_id === currentUser?.id).length === 0 && (
                  <div style={{ padding: '2rem', textAlign: 'center', color: '#9e9282', fontSize: '0.78rem' }}>
                    Không có thông báo
                  </div>
                )}
              </div>
            </div>
          )}
        </div>

        {/* User menu */}
        <div style={{ position: 'relative' }}>
          <button
            onClick={() => { setShowUser(!showUser); setShowNotifs(false); }}
            style={{
              display: 'flex', alignItems: 'center', gap: '0.5rem',
              background: 'none', border: '1px solid #e2dbd0',
              borderRadius: 7, padding: '0.25rem 0.625rem 0.25rem 0.375rem',
              cursor: 'pointer',
            }}
          >
            <div style={{
              width: 26, height: 26, borderRadius: '50%',
              background: '#4a6fa5', opacity: 0.85,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: '0.7rem', fontWeight: 600, color: 'white',
            }}>
              {currentUser?.full_name?.[0] || 'A'}
            </div>
            <span style={{ fontSize: '0.75rem', color: '#4a4035', fontWeight: 500, maxWidth: 100, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {currentUser?.full_name}
            </span>
            <ChevronDown size={13} color="#9e9282" />
          </button>

          {showUser && (
            <div style={{
              position: 'absolute', right: 0, top: 'calc(100% + 8px)',
              background: 'white', border: '1px solid #e2dbd0', borderRadius: 10,
              boxShadow: '0 6px 20px rgba(42,37,32,0.1)', width: 180, zIndex: 100,
            }}>
              <div style={{ padding: '0.75rem 1rem', borderBottom: '1px solid #ede8e0' }}>
                <div style={{ fontSize: '0.75rem', fontWeight: 600, color: '#2a2520' }}>{currentUser?.full_name}</div>
                <div style={{ fontSize: '0.65rem', color: '#9e9282' }}>Điều phối viên</div>
              </div>
              <button
                onClick={() => { logout(); navigate('/login'); }}
                style={{
                  width: '100%', display: 'flex', alignItems: 'center', gap: '0.5rem',
                  padding: '0.625rem 1rem', background: 'none', border: 'none', cursor: 'pointer',
                  color: '#a04040', fontSize: '0.75rem', fontWeight: 500,
                }}
              >
                <LogOut size={14} /> Đăng xuất
              </button>
            </div>
          )}
        </div>
      </div>
      <style>{`@keyframes sosBlink { 0%,100%{opacity:1} 50%{opacity:0.6} }`}</style>
    </header>
  );
}

export function RescueHeader({ onMenuClick }) {
  const { currentUser, logout } = useAuth();
  const navigate = useNavigate();
  return (
    <header className="header" style={{ borderBottom: '2px solid #d5e8da' }}>
      <button onClick={onMenuClick} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#9e9282' }}>
        <Menu size={18} />
      </button>
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.625rem' }}>
        <div style={{ width: 28, height: 28, borderRadius: '50%', background: '#3a6b4a', opacity: 0.85, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.72rem', fontWeight: 600, color: 'white' }}>
          {currentUser?.full_name?.[0] || 'R'}
        </div>
        <span style={{ fontSize: '0.78rem', fontWeight: 500, color: '#2a2520' }}>{currentUser?.full_name}</span>
        <button onClick={() => { logout(); navigate('/login'); }} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#9e9282', marginLeft: 4 }}>
          <LogOut size={15} />
        </button>
      </div>
    </header>
  );
}

export function CitizenHeader({ onMenuClick }) {
  const { currentUser, logout } = useAuth();
  const navigate = useNavigate();
  return (
    <header className="header" style={{ borderBottom: '2px solid #d0dced' }}>
      <button onClick={onMenuClick} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#9e9282' }}>
        <Menu size={18} />
      </button>
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.625rem' }}>
        <div style={{ width: 28, height: 28, borderRadius: '50%', background: '#4a6fa5', opacity: 0.85, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.72rem', fontWeight: 600, color: 'white' }}>
          {currentUser?.full_name?.[0] || 'N'}
        </div>
        <span style={{ fontSize: '0.78rem', fontWeight: 500, color: '#2a2520' }}>{currentUser?.full_name}</span>
        <button onClick={() => { logout(); navigate('/login'); }} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#9e9282', marginLeft: 4 }}>
          <LogOut size={15} />
        </button>
      </div>
    </header>
  );
}
