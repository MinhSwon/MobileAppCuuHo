import { useData } from '../../contexts/DataContext';
import { LevelBadge, StatusBadge } from '../../components/common/StatusBadge';
import { Bell } from 'lucide-react';

export default function CitizenWarnings() {
  const { floodWarnings } = useData();
  const active = floodWarnings.filter(w => w.status === 'PUBLISHED');
  const expired = floodWarnings.filter(w => w.status !== 'PUBLISHED');

  return (
    <div className="page-container">
      <div className="page-header">
        <div><h1 className="page-title"><Bell size={22} color="#f59e0b" /> Cảnh báo khẩn cấp</h1><p className="page-subtitle">Thông tin cảnh báo khẩn cấp khu vực toàn quốc</p></div>
      </div>

      {active.length > 0 && (
        <section style={{ marginBottom: '2rem' }}>
          <h2 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: '0.875rem', color: '#dc2626' }}>🔴 Đang hoạt động ({active.length})</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.875rem' }}>
            {active.map(w => (
              <div key={w.id} className={`alert-banner ${w.level.toLowerCase()}`} style={{ boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', gap: '0.625rem', alignItems: 'center', marginBottom: '0.5rem', flexWrap: 'wrap' }}>
                    <LevelBadge level={w.level} />
                    <span style={{ fontWeight: 700, fontSize: '0.95rem', color: '#0f172a' }}>{w.title}</span>
                  </div>
                  <div style={{ fontSize: '0.72rem', color: '#64748b', marginBottom: '0.625rem' }}>📍 {w.area_name}</div>
                  <p style={{ fontSize: '0.85rem', color: '#374151', lineHeight: 1.6 }}>{w.content}</p>
                  <div style={{ display: 'flex', gap: '1rem', marginTop: '0.75rem', fontSize: '0.72rem', color: '#94a3b8', flexWrap: 'wrap' }}>
                    <span>🕐 Từ: {new Date(w.start_time).toLocaleString('vi-VN')}</span>
                    <span>→ {new Date(w.end_time).toLocaleString('vi-VN')}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {expired.length > 0 && (
        <section>
          <h2 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: '0.875rem', color: '#94a3b8' }}>⏱️ Đã hết hiệu lực ({expired.length})</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.625rem' }}>
            {expired.map(w => (
              <div key={w.id} className="card" style={{ padding: '1rem 1.25rem', opacity: 0.7 }}>
                <div style={{ display: 'flex', gap: '0.625rem', alignItems: 'center', flexWrap: 'wrap' }}>
                  <LevelBadge level={w.level} /><StatusBadge status={w.status} />
                  <span style={{ fontWeight: 600, fontSize: '0.85rem' }}>{w.title}</span>
                  <span style={{ fontSize: '0.72rem', color: '#94a3b8' }}>📍 {w.area_name}</span>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {active.length === 0 && expired.length === 0 && (
        <div className="card" style={{ padding: '3rem', textAlign: 'center', color: '#94a3b8' }}>
          ✅ Không có cảnh báo nào
        </div>
      )}
    </div>
  );
}
