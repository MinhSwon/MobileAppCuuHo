import { useState } from 'react';
import { useToast } from '../../contexts/ToastContext';
import { Settings, Save, Shield, MapPin, MessageSquare, Droplets, Sliders, Bell } from 'lucide-react';

export default function AdminSettings() {
  const toast = useToast();
  const [activeTab, setActiveTab] = useState('system');

  // State values for system parameters
  const [systemName, setSystemName] = useState('RESCUEVN');
  const [emergencyPhone, setEmergencyPhone] = useState('0693 851 000');
  const [supportPhone1, setSupportPhone1] = useState('114');
  const [supportPhone2, setSupportPhone2] = useState('115');

  // GPS state values
  const [geofenceRadius, setGeofenceRadius] = useState(100);
  const [gpsUpdateInterval, setGpsUpdateInterval] = useState(10);
  const [gpsMinAccuracy, setGpsMinAccuracy] = useState(50);
  const [mockGpsActive, setMockGpsActive] = useState(true);

  // Emergency threshold state values
  const [thresholdLevel1, setThresholdLevel1] = useState(12.5); // Yellow warning level (m)
  const [thresholdLevel2, setThresholdLevel2] = useState(14.0); // Orange warning level (m)
  const [thresholdLevel3, setThresholdLevel3] = useState(15.5); // Red critical level (m)
  const [damAlertThreshold, setDamAlertThreshold] = useState(85); // % reservoir volume

  // SMS Gateway state values
  const [smsGateway, setSmsGateway] = useState('viettel_simulated');
  const [smsApiKey, setSmsApiKey] = useState('••••••••••••••••••••••••••••••••');
  const [smsSenderName, setSmsSenderName] = useState('RESCUEVN');
  const [autoSmsOnEmergency, setAutoSmsOnEmergency] = useState(true);

  const handleSave = (sectionName) => {
    toast.success(`Đã lưu thay đổi thành công cho mục "${sectionName}"!`);
  };

  const tabs = [
    { id: 'system', label: 'Hệ thống', icon: Settings },
    { id: 'gps', label: 'Định vị & Bản đồ', icon: MapPin },
    { id: 'flood', label: 'Ngưỡng khẩn cấp', icon: Droplets },
    { id: 'sms', label: 'SMS & Viễn thông', icon: MessageSquare },
  ];

  return (
    <div className="page-container">
      <div className="page-header" style={{ marginBottom: '2rem' }}>
        <div>
          <h1 className="page-title" style={{ display: 'flex', alignItems: 'center', gap: '0.625rem' }}>
            <Sliders size={22} color="#4a6fa5" /> Cài đặt hệ thống
          </h1>
          <p className="page-subtitle">Cấu hình các tham số hoạt động, ngưỡng cảnh báo thiên tai và định vị GPS</p>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '240px 1fr', gap: '2rem' }}>
        {/* Navigation Sidebar */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.375rem' }}>
          {tabs.map(tab => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.75rem',
                  padding: '0.75rem 1rem',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid transparent',
                  background: isActive ? 'var(--bg-subtle)' : 'transparent',
                  color: isActive ? 'var(--text-primary)' : 'var(--text-secondary)',
                  fontWeight: isActive ? 600 : 400,
                  fontSize: '0.82rem',
                  textAlign: 'left',
                  cursor: 'pointer',
                  transition: 'all 0.15s ease',
                }}
                onMouseEnter={e => {
                  if (!isActive) e.currentTarget.style.background = 'var(--bg-muted)';
                }}
                onMouseLeave={e => {
                  if (!isActive) e.currentTarget.style.background = 'transparent';
                }}
              >
                <Icon size={16} color={isActive ? 'var(--accent)' : 'var(--text-muted)'} />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* Configuration panel */}
        <div className="card" style={{ padding: '2rem' }}>
          {/* TAB 1: SYSTEM SETTINGS */}
          {activeTab === 'system' && (
            <div>
              <h2 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.15rem', fontWeight: 600, borderBottom: '1px solid var(--border-light)', paddingBottom: '0.75rem', marginBottom: '1.5rem', color: 'var(--text-primary)' }}>
                ⚙️ Cấu hình thông tin hệ thống
              </h2>
              
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem', maxWidth: '600px' }}>
                <div>
                  <label className="form-label">Tên cổng thông tin</label>
                  <input
                    type="text"
                    className="form-input"
                    value={systemName}
                    onChange={e => setSystemName(e.target.value)}
                  />
                  <p style={{ fontSize: '0.68rem', color: 'var(--text-muted)', marginTop: 4 }}>
                    Tên hiển thị chính trên đầu website và trong các thông báo hệ thống.
                  </p>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                  <div>
                    <label className="form-label">Đường dây nóng PCTT</label>
                    <input
                      type="text"
                      className="form-input"
                      value={emergencyPhone}
                      onChange={e => setEmergencyPhone(e.target.value)}
                    />
                  </div>
                  <div>
                    <label className="form-label">Điện thoại Cứu hỏa (PCCC)</label>
                    <input
                      type="text"
                      className="form-input"
                      value={supportPhone1}
                      onChange={e => setSupportPhone1(e.target.value)}
                    />
                  </div>
                </div>

                <div>
                  <label className="form-label">Cấp cứu Y tế</label>
                  <input
                    type="text"
                    className="form-input"
                    value={supportPhone2}
                    onChange={e => setSupportPhone2(e.target.value)}
                  />
                </div>

                <div style={{ padding: '1rem', background: 'var(--bg-subtle)', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-light)', display: 'flex', gap: '0.75rem', alignItems: 'flex-start' }}>
                  <Shield size={18} color="var(--accent)" style={{ flexShrink: 0, marginTop: 2 }} />
                  <div>
                    <h4 style={{ fontSize: '0.78rem', fontWeight: 600, color: 'var(--text-primary)', marginBottom: '0.25rem' }}>Bảo mật & Phân quyền</h4>
                    <p style={{ fontSize: '0.7rem', color: 'var(--text-secondary)' }}>
                      Tài khoản của bạn có quyền SUPER_ADMIN. Bạn có thể chỉnh sửa mọi thông tin, thiết lập cấu hình kết nối Viễn thông và quy trình nghiệp vụ cứu hộ.
                    </p>
                  </div>
                </div>

                <button
                  className="btn btn-primary"
                  style={{ width: 'fit-content', marginTop: '0.75rem' }}
                  onClick={() => handleSave('Hệ thống')}
                >
                  <Save size={16} /> Lưu cấu hình
                </button>
              </div>
            </div>
          )}

          {/* TAB 2: GPS SETTINGS */}
          {activeTab === 'gps' && (
            <div>
              <h2 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.15rem', fontWeight: 600, borderBottom: '1px solid var(--border-light)', paddingBottom: '0.75rem', marginBottom: '1.5rem', color: 'var(--text-primary)' }}>
                📍 Cấu hình GPS, Định vị & Geofence
              </h2>
              
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem', maxWidth: '600px' }}>
                <div>
                  <label className="form-label">Bán kính Geofence đến nạn nhân (mét)</label>
                  <input
                    type="number"
                    className="form-input"
                    value={geofenceRadius}
                    onChange={e => setGeofenceRadius(Number(e.target.value))}
                  />
                  <p style={{ fontSize: '0.68rem', color: 'var(--text-muted)', marginTop: 4 }}>
                    Khi khoảng cách GPS giữa đội cứu hộ và nạn nhân nhỏ hơn hoặc bằng trị số này, hệ thống sẽ tự động chuyển sang trạng thái <strong>NEAR_VICTIM</strong> (Gần nạn nhân).
                  </p>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                  <div>
                    <label className="form-label">Chu kỳ cập nhật vị trí (giây)</label>
                    <input
                      type="number"
                      className="form-input"
                      value={gpsUpdateInterval}
                      onChange={e => setGpsUpdateInterval(Number(e.target.value))}
                    />
                  </div>
                  <div>
                    <label className="form-label">Độ chính xác GPS tối thiểu (mét)</label>
                    <input
                      type="number"
                      className="form-input"
                      value={gpsMinAccuracy}
                      onChange={e => setGpsMinAccuracy(Number(e.target.value))}
                    />
                  </div>
                </div>

                <div style={{ border: '1px solid var(--border-light)', borderRadius: 'var(--radius-md)', padding: '1rem', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <div>
                    <h4 style={{ fontSize: '0.78rem', fontWeight: 600, color: 'var(--text-primary)' }}>Chế độ mô phỏng GPS cứu hộ</h4>
                    <p style={{ fontSize: '0.7rem', color: 'var(--text-muted)', marginTop: 2 }}>
                      Cho phép giả lập tọa độ di chuyển cứu hộ khi trình duyệt không lấy được tín hiệu định vị thực tế.
                    </p>
                  </div>
                  <input
                    type="checkbox"
                    checked={mockGpsActive}
                    onChange={e => setMockGpsActive(e.target.checked)}
                    style={{ width: 18, height: 18, cursor: 'pointer' }}
                  />
                </div>

                <button
                  className="btn btn-primary"
                  style={{ width: 'fit-content', marginTop: '0.75rem' }}
                  onClick={() => handleSave('Định vị & Bản đồ')}
                >
                  <Save size={16} /> Lưu cấu hình
                </button>
              </div>
            </div>
          )}

          {/* TAB 3: FLOOD THRESHOLDS */}
          {activeTab === 'flood' && (
            <div>
              <h2 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.15rem', fontWeight: 600, borderBottom: '1px solid var(--border-light)', paddingBottom: '0.75rem', marginBottom: '1.5rem', color: 'var(--text-primary)' }}>
                🌊 Ngưỡng cảnh báo khẩn cấp Việt Nam
              </h2>
              
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem', maxWidth: '600px' }}>
                <div style={{ padding: '0.75rem 1rem', background: 'var(--warning-light)', borderLeft: '3px solid var(--warning)', borderRadius: 'var(--radius-sm)', fontSize: '0.75rem', color: 'var(--warning)' }}>
                  ⚠️ Cấu hình mức nước báo động (m) tại các trạm đo chính thuộc huyện Việt Nam (Sông sông lớn trong khu vực).
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '0.875rem' }}>
                  <div>
                    <label className="form-label" style={{ color: '#a0731a' }}>Báo động I (m)</label>
                    <input
                      type="number"
                      step="0.1"
                      className="form-input"
                      value={thresholdLevel1}
                      onChange={e => setThresholdLevel1(Number(e.target.value))}
                    />
                  </div>
                  <div>
                    <label className="form-label" style={{ color: '#c89440' }}>Báo động II (m)</label>
                    <input
                      type="number"
                      step="0.1"
                      className="form-input"
                      value={thresholdLevel2}
                      onChange={e => setThresholdLevel2(Number(e.target.value))}
                    />
                  </div>
                  <div>
                    <label className="form-label" style={{ color: '#a04040' }}>Báo động III (m)</label>
                    <input
                      type="number"
                      step="0.1"
                      className="form-input"
                      value={thresholdLevel3}
                      onChange={e => setThresholdLevel3(Number(e.target.value))}
                    />
                  </div>
                </div>

                <div>
                  <label className="form-label">Ngưỡng xả tràn hồ chứa/đập (%)</label>
                  <input
                    type="number"
                    className="form-input"
                    value={damAlertThreshold}
                    onChange={e => setDamAlertThreshold(Number(e.target.value))}
                  />
                  <p style={{ fontSize: '0.68rem', color: 'var(--text-muted)', marginTop: 4 }}>
                    Hệ thống sẽ kích hoạt trạng thái cảnh báo tự động khi dung tích đập chứa vượt ngưỡng này.
                  </p>
                </div>

                <button
                  className="btn btn-primary"
                  style={{ width: 'fit-content', marginTop: '0.75rem' }}
                  onClick={() => handleSave('Ngưỡng khẩn cấp')}
                >
                  <Save size={16} /> Lưu cấu hình
                </button>
              </div>
            </div>
          )}

          {/* TAB 4: SMS SETTINGS */}
          {activeTab === 'sms' && (
            <div>
              <h2 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.15rem', fontWeight: 600, borderBottom: '1px solid var(--border-light)', paddingBottom: '0.75rem', marginBottom: '1.5rem', color: 'var(--text-primary)' }}>
                📱 Cấu hình SMS Gateway & Viễn thông
              </h2>
              
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem', maxWidth: '600px' }}>
                <div>
                  <label className="form-label">Chọn nhà cung cấp dịch vụ SMS</label>
                  <select
                    className="form-input form-select"
                    value={smsGateway}
                    onChange={e => setSmsGateway(e.target.value)}
                  >
                    <option value="viettel_simulated">Viettel SMS Gateway (Simulated)</option>
                    <option value="fpt_api">FPT Telecom SMS API</option>
                    <option value="vmg_brandname">VMG Brandname SMS</option>
                    <option value="esms">eSMS.vn Gateway</option>
                  </select>
                </div>

                <div>
                  <label className="form-label">Mã API Key kết nối (Bearer Token)</label>
                  <input
                    type="password"
                    className="form-input"
                    value={smsApiKey}
                    onChange={e => setSmsApiKey(e.target.value)}
                  />
                </div>

                <div>
                  <label className="form-label">Đầu số hiển thị (SMS Brandname)</label>
                  <input
                    type="text"
                    className="form-input"
                    value={smsSenderName}
                    onChange={e => setSmsSenderName(e.target.value)}
                  />
                  <p style={{ fontSize: '0.68rem', color: 'var(--text-muted)', marginTop: 4 }}>
                    Brandname đăng ký với cục Viễn thông (ví dụ: RESCUEVN hoặc TRUNGTAMCH).
                  </p>
                </div>

                <div style={{ border: '1px solid var(--border-light)', borderRadius: 'var(--radius-md)', padding: '1rem', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <div>
                    <h4 style={{ fontSize: '0.78rem', fontWeight: 600, color: 'var(--text-primary)' }}>Tự động gửi SMS khi có tin báo khẩn</h4>
                    <p style={{ fontSize: '0.7rem', color: 'var(--text-muted)', marginTop: 2 }}>
                      Gửi SMS cảnh báo tự động đến tất cả các số điện thoại trong vùng có cảnh báo đỏ ngay khi Coordinator xuất bản tin tức.
                    </p>
                  </div>
                  <input
                    type="checkbox"
                    checked={autoSmsOnEmergency}
                    onChange={e => setAutoSmsOnEmergency(e.target.checked)}
                    style={{ width: 18, height: 18, cursor: 'pointer' }}
                  />
                </div>

                <button
                  className="btn btn-primary"
                  style={{ width: 'fit-content', marginTop: '0.75rem' }}
                  onClick={() => handleSave('SMS & Viễn thông')}
                >
                  <Save size={16} /> Lưu cấu hình
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
