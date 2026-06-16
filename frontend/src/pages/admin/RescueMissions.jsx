import { useState } from 'react';
import { useData } from '../../contexts/DataContext';
import { useToast } from '../../contexts/ToastContext';
import { useAuth } from '../../contexts/AuthContext';
import { StatusBadge, LevelBadge } from '../../components/common/StatusBadge';
import { haversineDistance, formatDistance } from '../../utils/haversine';
import { Eye, X, Clock, CheckCircle, AlertTriangle, MapPin, Activity } from 'lucide-react';
import { Link } from 'react-router-dom';

const STEP_ORDER = ['ASSIGNED', 'ACCEPTED', 'MOVING', 'NEAR_VICTIM', 'ARRIVED_CONFIRMED', 'RESCUING', 'RESCUED'];

const STEP_ICONS = {
  ASSIGNED: '📋', ACCEPTED: '✅', MOVING: '🚤', NEAR_VICTIM: '📍',
  ARRIVED_CONFIRMED: '🤝', RESCUING: '⚡', RESCUED: '🎉',
  UNREACHABLE: '📵', NEED_SUPPORT: '🆘', CANCELLED: '❌', TRANSFERRED_SAFEZONE: '🏫',
};

function MissionDetail({ mission, statusLogs, onClose, onUpdateStatus }) {
  const { rescueTeams } = useData();

  const missionLogs = statusLogs.filter(l => l.mission_id === mission.id)
    .sort((a, b) => new Date(a.created_at) - new Date(b.created_at));

  const distance = mission.current_rescuer_latitude && mission.current_rescuer_longitude
    ? haversineDistance(
        mission.current_rescuer_latitude, mission.current_rescuer_longitude,
        mission.victim_latitude, mission.victim_longitude
      )
    : null;

  return (
    <div className="modal-overlay" onClick={e => e.target === e.currentTarget && onClose()}>
      <div className="modal-box" style={{ maxWidth: 680 }}>
        <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid #f1f5f9', display: 'flex', justifyContent: 'space-between' }}>
          <div>
            <h3 style={{ fontWeight: 700, fontSize: '1rem' }}>Chi tiết nhiệm vụ cứu hộ</h3>
            <p style={{ fontSize: '0.72rem', color: '#64748b' }}>Mã: {mission.id.toUpperCase()}</p>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#94a3b8' }}><X size={20} /></button>
        </div>
        <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          {/* Status */}
          <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center', flexWrap: 'wrap' }}>
            <StatusBadge status={mission.status} />
            {mission.auto_arrival_detected && (
              <span style={{ background: '#dcfce7', color: '#15803d', borderRadius: '9999px', padding: '3px 10px', fontSize: '0.72rem', fontWeight: 600 }}>
                ✅ GPS: Đã đến gần ({mission.auto_arrival_distance_meters}m)
              </span>
            )}
          </div>

          {/* Info grid */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <div style={{ background: '#fef2f2', borderRadius: 10, padding: '1rem' }}>
              <div style={{ fontSize: '0.7rem', color: '#94a3b8', marginBottom: 4, fontWeight: 600, textTransform: 'uppercase' }}>Nạn nhân</div>
              <div style={{ fontWeight: 700, fontSize: '0.95rem', color: '#0f172a', marginBottom: 4 }}>{mission.victim_name}</div>
              <a href={`tel:${mission.victim_phone}`} style={{ color: '#dc2626', fontSize: '0.82rem', textDecoration: 'none' }}>📞 {mission.victim_phone}</a>
              <div style={{ fontSize: '0.75rem', color: '#64748b', marginTop: 4 }}>📍 {mission.victim_address}</div>
              <div style={{ fontSize: '0.7rem', color: '#94a3b8', marginTop: 4 }}>
                GPS: {mission.victim_latitude?.toFixed(6)}, {mission.victim_longitude?.toFixed(6)}
              </div>
            </div>
            <div style={{ background: '#f0fdf4', borderRadius: 10, padding: '1rem' }}>
              <div style={{ fontSize: '0.7rem', color: '#94a3b8', marginBottom: 4, fontWeight: 600, textTransform: 'uppercase' }}>Đội cứu hộ</div>
              <div style={{ fontWeight: 700, fontSize: '0.95rem', color: '#0f172a', marginBottom: 4 }}>🛡️ {mission.team_name}</div>
              <div style={{ fontSize: '0.75rem', color: '#64748b' }}>📍 {mission.area_name}</div>
              {distance !== null && (
                <div style={{ fontSize: '0.8rem', fontWeight: 700, color: distance <= 100 ? '#10b981' : '#374151', marginTop: 8 }}>
                  📏 Khoảng cách: {formatDistance(distance)}
                </div>
              )}
            </div>
          </div>

          {/* GPS Geofence status */}
          <div style={{ background: '#f8fafc', borderRadius: 10, padding: '1rem' }}>
            <div style={{ fontWeight: 600, fontSize: '0.82rem', marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Activity size={16} /> Thông số Auto Check-in GPS
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: '0.75rem' }}>
              {[
                { label: 'Bán kính geofence', value: `${mission.checkin_radius_meters}m` },
                { label: 'Độ chính xác GPS tối đa', value: `${mission.max_gps_accuracy_meters}m` },
                { label: 'Thời gian trong vùng tối thiểu', value: `${mission.min_stay_seconds}s` },
              ].map(p => (
                <div key={p.label} style={{ background: 'white', borderRadius: 8, padding: '0.625rem', textAlign: 'center', border: '1px solid #e2e8f0' }}>
                  <div style={{ fontSize: '0.65rem', color: '#94a3b8', marginBottom: 4 }}>{p.label}</div>
                  <div style={{ fontWeight: 700, color: '#374151', fontSize: '0.95rem' }}>{p.value}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Status Timeline */}
          <div>
            <div style={{ fontWeight: 600, fontSize: '0.85rem', marginBottom: '0.875rem' }}>📅 Lịch sử trạng thái</div>
            <div style={{ display: 'flex', flexDirection: 'column' }}>
              {missionLogs.map((log, i) => (
                <div key={log.id} className="timeline-item">
                  <div className={`timeline-dot status-dot-${log.changed_by_type}`} style={{
                    background: log.changed_by_type === 'SYSTEM' ? '#6366f1' :
                                log.changed_by_type === 'ADMIN' ? '#3b82f6' :
                                log.changed_by_type === 'RESCUE_TEAM' ? '#10b981' : '#f59e0b',
                    color: 'white', fontSize: '0.6rem'
                  }}>
                    {log.changed_by_type === 'SYSTEM' ? '🤖' : log.changed_by_type === 'ADMIN' ? 'A' : 'R'}
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: '0.78rem', fontWeight: 600, color: '#0f172a' }}>
                      {STEP_ICONS[log.new_status]} {log.new_status}
                      {log.changed_by_type === 'SYSTEM' && (
                        <span style={{ background: '#ede9fe', color: '#7c3aed', borderRadius: '9999px', padding: '1px 6px', fontSize: '0.62rem', marginLeft: 6 }}>Hệ thống tự động</span>
                      )}
                    </div>
                    <div style={{ fontSize: '0.72rem', color: '#64748b' }}>{log.note}</div>
                    <div style={{ fontSize: '0.65rem', color: '#94a3b8', marginTop: 2 }}>
                      {new Date(log.created_at).toLocaleString('vi-VN')}
                    </div>
                  </div>
                </div>
              ))}
              {missionLogs.length === 0 && (
                <div style={{ color: '#94a3b8', fontSize: '0.78rem', fontStyle: 'italic' }}>Chưa có lịch sử trạng thái</div>
              )}
            </div>
          </div>

          {/* Completion note */}
          {mission.completion_note && (
            <div style={{ background: '#f0fdf4', border: '1px solid #bbf7d0', borderRadius: 10, padding: '0.875rem' }}>
              <div style={{ fontWeight: 600, fontSize: '0.78rem', color: '#15803d', marginBottom: 4 }}>📝 Ghi chú kết quả</div>
              <div style={{ fontSize: '0.82rem', color: '#374151' }}>{mission.completion_note}</div>
            </div>
          )}

          {/* Timestamps */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: '0.75rem', fontSize: '0.72rem', color: '#64748b' }}>
            <div>📋 Phân công: <strong>{mission.assigned_at ? new Date(mission.assigned_at).toLocaleString('vi-VN', { dateStyle: 'short', timeStyle: 'short' }) : '—'}</strong></div>
            <div>✅ Nhận nhiệm vụ: <strong>{mission.accepted_at ? new Date(mission.accepted_at).toLocaleString('vi-VN', { dateStyle: 'short', timeStyle: 'short' }) : '—'}</strong></div>
            <div>🏁 Hoàn thành: <strong>{mission.completed_at ? new Date(mission.completed_at).toLocaleString('vi-VN', { dateStyle: 'short', timeStyle: 'short' }) : '—'}</strong></div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function RescueMissions() {
  const { rescueMissions, missionStatusLogs, updateMissionStatus } = useData();
  const { currentUser } = useAuth();
  const toast = useToast();
  const [filterStatus, setFilterStatus] = useState('');
  const [filterArea, setFilterArea] = useState('');
  const [detailMission, setDetailMission] = useState(null);

  const filtered = rescueMissions.filter(m => {
    if (filterStatus && m.status !== filterStatus) return false;
    if (filterArea && m.area_id !== filterArea) return false;
    return true;
  });

  const AREAS_FILTER = [...new Set(rescueMissions.map(m => m.area_name))];

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Nhiệm vụ cứu hộ</h1>
          <p className="page-subtitle">Theo dõi tiến trình tất cả nhiệm vụ cứu hộ</p>
        </div>
        <Link to="/admin/dispatch" className="btn btn-primary">
          <MapPin size={16} /> Mở trung tâm điều phối
        </Link>
      </div>

      {/* Summary */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(120px, 1fr))', gap: '0.75rem', marginBottom: '1.25rem' }}>
        {[
          { label: 'Đang xử lý', statuses: ['ASSIGNED','ACCEPTED','MOVING','NEAR_VICTIM','ARRIVED_CONFIRMED','RESCUING'], color: '#3b82f6' },
          { label: 'Cứu thành công', statuses: ['RESCUED','TRANSFERRED_SAFEZONE'], color: '#10b981' },
          { label: 'Không liên lạc', statuses: ['UNREACHABLE'], color: '#ef4444' },
          { label: 'Cần hỗ trợ', statuses: ['NEED_SUPPORT'], color: '#f59e0b' },
          { label: 'Tổng', statuses: null, color: '#374151' },
        ].map(s => (
          <div key={s.label} style={{ background: 'white', border: `1px solid ${s.color}20`, borderRadius: 10, padding: '0.75rem', textAlign: 'center', cursor: 'pointer' }}
            onClick={() => s.statuses ? setFilterStatus(s.statuses[0]) : setFilterStatus('')}>
            <div style={{ fontSize: '1.5rem', fontWeight: 800, color: s.color }}>
              {s.statuses ? rescueMissions.filter(m => s.statuses.includes(m.status)).length : rescueMissions.length}
            </div>
            <div style={{ fontSize: '0.68rem', color: '#64748b', marginTop: 2 }}>{s.label}</div>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="filter-bar">
        <select className="form-input form-select" style={{ width: 170 }} value={filterStatus} onChange={e => setFilterStatus(e.target.value)}>
          <option value="">Tất cả trạng thái</option>
          {['ASSIGNED','ACCEPTED','MOVING','NEAR_VICTIM','ARRIVED_CONFIRMED','RESCUING','RESCUED','UNREACHABLE','NEED_SUPPORT'].map(s => (
            <option key={s} value={s}>{s}</option>
          ))}
        </select>
        <select className="form-input form-select" style={{ width: 160 }} value={filterArea} onChange={e => setFilterArea(e.target.value)}>
          <option value="">Tất cả khu vực</option>
          {AREAS_FILTER.map(a => <option key={a} value={a}>{a}</option>)}
        </select>
      </div>

      {/* Table */}
      <div className="card">
        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã NV</th>
                <th>Nạn nhân</th>
                <th>Đội cứu hộ</th>
                <th>Khu vực</th>
                <th>Trạng thái</th>
                <th>GPS Auto</th>
                <th>Thời gian phân công</th>
                <th>Khoảng cách</th>
                <th>Hành động</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map(m => {
                const dist = m.current_rescuer_latitude
                  ? haversineDistance(m.current_rescuer_latitude, m.current_rescuer_longitude, m.victim_latitude, m.victim_longitude)
                  : null;
                return (
                  <tr key={m.id}>
                    <td style={{ fontSize: '0.7rem', color: '#94a3b8', fontFamily: 'monospace' }}>{m.id.substring(0,8)}...</td>
                    <td>
                      <div style={{ fontWeight: 600, fontSize: '0.82rem' }}>{m.victim_name}</div>
                      <div style={{ fontSize: '0.7rem', color: '#64748b' }}>{m.victim_phone}</div>
                    </td>
                    <td style={{ fontSize: '0.78rem', fontWeight: 500 }}>🛡️ {m.team_name}</td>
                    <td style={{ fontSize: '0.75rem' }}>{m.area_name}</td>
                    <td><StatusBadge status={m.status} /></td>
                    <td>
                      {m.auto_arrival_detected ? (
                        <span style={{ color: '#10b981', fontSize: '0.72rem', fontWeight: 600 }}>✅ {m.auto_arrival_distance_meters}m</span>
                      ) : (
                        <span style={{ color: '#94a3b8', fontSize: '0.72rem' }}>—</span>
                      )}
                    </td>
                    <td style={{ fontSize: '0.72rem', color: '#64748b' }}>
                      {m.assigned_at ? new Date(m.assigned_at).toLocaleString('vi-VN', { dateStyle: 'short', timeStyle: 'short' }) : '—'}
                    </td>
                    <td style={{ fontSize: '0.75rem', fontWeight: dist !== null && dist <= 100 ? 700 : 400, color: dist !== null && dist <= 100 ? '#10b981' : '#374151' }}>
                      {dist !== null ? formatDistance(dist) : '—'}
                    </td>
                    <td>
                      <button className="btn btn-ghost btn-sm" onClick={() => setDetailMission(m)}>
                        <Eye size={14} /> Chi tiết
                      </button>
                    </td>
                  </tr>
                );
              })}
              {filtered.length === 0 && (
                <tr><td colSpan={9} style={{ textAlign: 'center', padding: '2rem', color: '#94a3b8' }}>Không có nhiệm vụ nào</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {detailMission && (
        <MissionDetail
          mission={detailMission}
          statusLogs={missionStatusLogs}
          onClose={() => setDetailMission(null)}
          onUpdateStatus={updateMissionStatus}
        />
      )}
    </div>
  );
}
