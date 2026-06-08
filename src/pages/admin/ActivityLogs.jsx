import { useData } from '../../contexts/DataContext';
import { Activity } from 'lucide-react';

const ACTION_ICONS = {
  'Tạo cảnh báo khẩn cấp': '🔔',
  'Cập nhật cảnh báo': '✏️',
  'Công bố cảnh báo': '📢',
  'Gửi SMS cảnh báo': '📱',
  'Gửi yêu cầu cứu hộ': '🆘',
  'Phân công đội cứu hộ': '👥',
  'Tự động xác định NEAR_VICTIM': '🤖',
  'Xác nhận tiếp cận nạn nhân': '🤝',
  'Cứu hộ thành công': '🎉',
  'Đăng nhập': '🔑',
};

const SOURCE_COLORS = {
  SYSTEM: '#6366f1',
  ADMIN: '#3b82f6',
  RESCUE_TEAM: '#10b981',
  CITIZEN: '#f59e0b',
};

export default function ActivityLogs() {
  const { activityLogs } = useData();

  const sorted = [...activityLogs].sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

  return (
    <div className="page-container">
      <div className="page-header">
        <div><h1 className="page-title">Nhật ký hoạt động</h1><p className="page-subtitle">Toàn bộ hành động được ghi lại trong hệ thống</p></div>
        <span style={{ background: '#f1f5f9', borderRadius: 8, padding: '0.375rem 0.875rem', fontSize: '0.82rem', color: '#374151' }}>
          📋 {activityLogs.length} bản ghi
        </span>
      </div>

      <div className="card">
        <div style={{ display: 'flex', flexDirection: 'column' }}>
          {sorted.map((log, i) => (
            <div key={log.id} style={{
              padding: '0.875rem 1.25rem',
              borderBottom: i < sorted.length - 1 ? '1px solid #f8fafc' : 'none',
              display: 'flex', alignItems: 'flex-start', gap: '0.875rem',
              background: i % 2 === 0 ? 'white' : '#fafafa',
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: '50%', flexShrink: 0,
                background: log.user_name === 'SYSTEM' ? '#ede9fe' : '#eff6ff',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: '1rem',
              }}>
                {ACTION_ICONS[log.action] || '📝'}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', gap: '0.625rem', alignItems: 'center', marginBottom: 4, flexWrap: 'wrap' }}>
                  <span style={{ fontWeight: 700, fontSize: '0.82rem', color: '#0f172a' }}>{log.action}</span>
                  {log.user_name === 'SYSTEM' && (
                    <span style={{ background: '#ede9fe', color: '#7c3aed', borderRadius: '9999px', padding: '1px 8px', fontSize: '0.65rem', fontWeight: 700 }}>🤖 Hệ thống tự động</span>
                  )}
                </div>
                <div style={{ fontSize: '0.75rem', color: '#64748b', marginBottom: 4 }}>{log.note}</div>
                <div style={{ display: 'flex', gap: '0.875rem', fontSize: '0.68rem', color: '#94a3b8', flexWrap: 'wrap' }}>
                  <span>👤 {log.user_name || 'SYSTEM'}</span>
                  <span>📂 {log.table_name}</span>
                  <span>🕐 {new Date(log.created_at).toLocaleString('vi-VN')}</span>
                </div>
              </div>
            </div>
          ))}
          {sorted.length === 0 && (
            <div style={{ textAlign: 'center', padding: '3rem', color: '#94a3b8' }}>Chưa có nhật ký</div>
          )}
        </div>
      </div>
    </div>
  );
}
