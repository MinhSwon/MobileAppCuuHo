import { useData } from '../../contexts/DataContext';
import { Droplets, AlertTriangle, CheckCircle } from 'lucide-react';

export default function Dams() {
  const { dams } = useData();

  const STATUS_INFO = {
    NORMAL: { label: '✅ Bình thường', color: '#10b981', bg: '#f0fdf4' },
    CAUTION: { label: '⚠️ Cảnh báo', color: '#f59e0b', bg: '#fffbeb' },
    EMERGENCY: { label: '🚨 Khẩn cấp', color: '#ef4444', bg: '#fef2f2' },
  };

  return (
    <div className="page-container">
      <div className="page-header">
        <div><h1 className="page-title">Đập / Hồ chứa</h1><p className="page-subtitle">Theo dõi mực nước và trạng thái an toàn</p></div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(380px, 1fr))', gap: '1.25rem' }}>
        {dams.map(dam => {
          const info = STATUS_INFO[dam.status] || STATUS_INFO.NORMAL;
          const pct = dam.current_volume_percent;
          const levelPct = ((dam.current_level_m - 0) / (dam.emergency_level_m - 0)) * 100;

          return (
            <div key={dam.id} className="card">
              <div style={{ padding: '1rem', borderBottom: '1px solid #f1f5f9', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <div style={{ fontWeight: 700, fontSize: '0.95rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Droplets size={18} color="#3b82f6" /> {dam.name}
                  </div>
                  <div style={{ fontSize: '0.72rem', color: '#64748b', marginTop: 4 }}>📍 {dam.area_name}</div>
                </div>
                <span style={{ background: info.bg, color: info.color, borderRadius: 8, padding: '3px 10px', fontSize: '0.75rem', fontWeight: 700 }}>{info.label}</span>
              </div>

              <div style={{ padding: '1.25rem' }}>
                {/* Water level visual */}
                <div style={{ marginBottom: '1.25rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', marginBottom: '0.5rem' }}>
                    <span style={{ color: '#64748b' }}>Mực nước hiện tại</span>
                    <span style={{ fontWeight: 800, fontSize: '1.1rem', color: info.color }}>{dam.current_level_m}m</span>
                  </div>
                  <div style={{ height: 16, background: '#f1f5f9', borderRadius: 8, position: 'relative', overflow: 'hidden' }}>
                    <div style={{ height: '100%', width: `${Math.min(levelPct, 100)}%`, background: `linear-gradient(90deg, #3b82f6, ${pct >= 90 ? '#ef4444' : pct >= 75 ? '#f59e0b' : '#3b82f6'})`, borderRadius: 8, transition: 'width 0.5s' }} />
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.68rem', color: '#94a3b8', marginTop: 4 }}>
                    <span>0m</span>
                    <span style={{ color: '#f59e0b' }}>⚠️ {dam.warning_level_m}m</span>
                    <span style={{ color: '#ef4444' }}>🚨 {dam.emergency_level_m}m</span>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: '0.75rem', marginBottom: '1rem' }}>
                  <div style={{ background: '#f8fafc', borderRadius: 8, padding: '0.625rem', textAlign: 'center' }}>
                    <div style={{ fontSize: '0.65rem', color: '#94a3b8', marginBottom: 2 }}>Mức cảnh báo</div>
                    <div style={{ fontWeight: 700, color: '#f59e0b' }}>{dam.warning_level_m}m</div>
                  </div>
                  <div style={{ background: '#f8fafc', borderRadius: 8, padding: '0.625rem', textAlign: 'center' }}>
                    <div style={{ fontSize: '0.65rem', color: '#94a3b8', marginBottom: 2 }}>Mức khẩn cấp</div>
                    <div style={{ fontWeight: 700, color: '#ef4444' }}>{dam.emergency_level_m}m</div>
                  </div>
                  <div style={{ background: '#f8fafc', borderRadius: 8, padding: '0.625rem', textAlign: 'center' }}>
                    <div style={{ fontSize: '0.65rem', color: '#94a3b8', marginBottom: 2 }}>Đã dùng</div>
                    <div style={{ fontWeight: 700, color: pct >= 90 ? '#ef4444' : '#374151' }}>{pct}%</div>
                  </div>
                </div>

                {dam.note && (
                  <div style={{ background: '#fffbeb', border: '1px solid #fde68a', borderRadius: 8, padding: '0.625rem', fontSize: '0.75rem', color: '#854d0e' }}>
                    📝 {dam.note}
                  </div>
                )}

                <div style={{ marginTop: '0.875rem', fontSize: '0.68rem', color: '#94a3b8' }}>
                  🕐 Cập nhật: {new Date(dam.last_updated).toLocaleString('vi-VN')}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
