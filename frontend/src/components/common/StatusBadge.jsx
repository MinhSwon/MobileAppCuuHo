// Status badge display labels
export const STATUS_LABELS = {
  // Mission statuses
  PENDING: 'Chờ tiếp nhận',
  ASSIGNED: 'Đã phân công',
  ACCEPTED: 'Đã nhận nhiệm vụ',
  MOVING: 'Đang di chuyển',
  NEAR_VICTIM: 'Đã đến gần',
  ARRIVED_CONFIRMED: 'Đã tiếp cận',
  RESCUING: 'Đang cứu hộ',
  RESCUED: 'Cứu thành công',
  TRANSFERRED_SAFEZONE: 'Đã đưa đến nơi an toàn',
  UNREACHABLE: 'Không liên lạc được',
  NEED_SUPPORT: 'Cần hỗ trợ thêm',
  CANCELLED: 'Đã hủy',
  // Warning statuses
  DRAFT: 'Bản nháp',
  PUBLISHED: 'Đã công bố',
  EXPIRED: 'Hết hiệu lực',
  // Warning levels
  LOW: 'Thấp',
  MEDIUM: 'Trung bình',
  HIGH: 'Cao',
  EMERGENCY: 'Khẩn cấp',
  // Team statuses
  AVAILABLE: 'Sẵn sàng',
  BUSY: 'Đang làm nhiệm vụ',
  OFFLINE: 'Không hoạt động',
  INACTIVE: 'Ngưng hoạt động',
  // Safe zone statuses
  FULL: 'Đã đầy',
  // SMS statuses
  SENT: 'Đã gửi',
  FAILED: 'Thất bại',
  // Other
  ACTIVE: 'Hoạt động',
  LOCKED: 'Đã khóa',
  CONFIRMED: 'Đã xác nhận',
  NORMAL: 'Bình thường',
  CAUTION: 'Cảnh báo',
  FLOODED: 'Bị ngập',
  OPEN: 'Thông thoáng',
  SAFE: 'An toàn',
  DANGEROUS: 'Nguy hiểm',
};

export function StatusBadge({ status, size = 'sm' }) {
  const label = STATUS_LABELS[status] || status;
  return (
    <span className={`badge badge-${status} ${size === 'xs' ? 'text-xs px-2 py-0.5' : ''}`}>
      {label}
    </span>
  );
}

export function LevelBadge({ level }) {
  const icons = {
    LOW: '🔵',
    MEDIUM: '🟡',
    HIGH: '🟠',
    EMERGENCY: '🔴',
  };
  return (
    <span className={`badge badge-${level}`}>
      {icons[level] || ''} {STATUS_LABELS[level] || level}
    </span>
  );
}

export default StatusBadge;
