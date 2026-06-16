import 'dotenv/config';
import bcrypt from 'bcryptjs';
import { prisma } from '../src/lib/prisma.js';
import {
  AREAS,
  USERS,
  CITIZEN_PROFILES,
  VULNERABLE_HOUSEHOLDS,
  RESCUE_TEAMS,
  FLOOD_WARNINGS,
  RESCUE_REQUESTS,
  RESCUE_MISSIONS,
  MISSION_STATUS_LOGS,
  SAFE_ZONES,
  RESCUE_ROUTES,
  SMS_LOGS,
  DAMAGE_REPORTS,
  ACTIVITY_LOGS,
  NOTIFICATIONS,
} from '../src/data/mockData.js';

const PROJECT_ID = 'project-rescuevn-app';
const PROJECT_CODE = 'RESCUEVN_APP';

function toDate(value) {
  return value ? new Date(value) : undefined;
}

function mapEmergencyType(text = '') {
  const value = text.toLowerCase();
  if (value.includes('cấp cứu') || value.includes('y tế') || value.includes('bệnh')) return 'MEDICAL';
  if (value.includes('cháy')) return 'FIRE';
  if (value.includes('tai nạn')) return 'TRAFFIC_ACCIDENT';
  if (value.includes('sạt lở')) return 'LANDSLIDE';
  if (value.includes('mất tích') || value.includes('lạc')) return 'MISSING_PERSON';
  if (value.includes('cô lập')) return 'ISOLATED';
  if (value.includes('sơ tán') || value.includes('di tản')) return 'EVACUATION';
  if (value.includes('thực') || value.includes('nước')) return 'FOOD_WATER';
  if (value.includes('ngập') || value.includes('lũ')) return 'FLOOD';
  return 'OTHER';
}

function mapMissionStatus(status) {
  const map = {
    ASSIGNED: 'DISPATCHED',
    ACCEPTED: 'ACCEPTED',
    MOVING: 'MOVING',
    NEAR_VICTIM: 'MOVING',
    ARRIVED_CONFIRMED: 'ARRIVED',
    RESCUING: 'RESCUING',
    RESCUED: 'COMPLETED',
    TRANSFERRED_SAFEZONE: 'COMPLETED',
    NEED_SUPPORT: 'NEED_SUPPORT',
    CANCELLED: 'CANCELLED',
  };
  return map[status] || 'CREATED';
}

function mapRouteStatus(status) {
  if (status === 'FLOODED') return 'BLOCKED';
  if (status === 'NORMAL') return 'OPEN';
  return ['OPEN', 'CAUTION', 'BLOCKED', 'CLOSED'].includes(status) ? status : 'CAUTION';
}

function mapDamageStatus(status) {
  if (status === 'CONFIRMED') return 'VERIFIED';
  return ['PENDING', 'VERIFIED', 'REJECTED', 'RESOLVED'].includes(status) ? status : 'PENDING';
}

function mapRiskLevel(value, fallback = 'MEDIUM') {
  if (['LOW', 'MEDIUM', 'HIGH', 'EMERGENCY'].includes(value)) return value;
  if (Number(value) >= 3) return 'EMERGENCY';
  if (Number(value) === 2) return 'HIGH';
  if (Number(value) === 1) return 'MEDIUM';
  return fallback;
}

function seedPasswordFor(role) {
  if (role === 'ADMIN' || role === 'SUPER_ADMIN' || role === 'DISPATCHER') return 'admin123';
  if (role === 'RESCUE_LEADER' || role === 'RESCUE_MEMBER') return 'rescue123';
  return 'citizen123';
}

async function clearDatabase() {
  await prisma.auditLog.deleteMany();
  await prisma.equipmentAsset.deleteMany();
  await prisma.activityLog.deleteMany();
  await prisma.smsLog.deleteMany();
  await prisma.notification.deleteMany();
  await prisma.vulnerableHousehold.deleteMany();
  await prisma.damageReport.deleteMany();
  await prisma.rescueRoute.deleteMany();
  await prisma.safeZone.deleteMany();
  await prisma.alertDelivery.deleteMany();
  await prisma.alert.deleteMany();
  await prisma.missionStatusLog.deleteMany();
  await prisma.rescueMission.deleteMany();
  await prisma.requestStatusLog.deleteMany();
  await prisma.rescueRequest.deleteMany();
  await prisma.rescueTeamMember.deleteMany();
  await prisma.rescueTeam.deleteMany();
  await prisma.citizenProfile.deleteMany();
  await prisma.user.deleteMany();
  await prisma.administrativeUnit.deleteMany();
  await prisma.appProject.deleteMany();
}

async function main() {
  await clearDatabase();

  await prisma.appProject.create({
    data: {
      id: PROJECT_ID,
      code: PROJECT_CODE,
      name: 'Ứng dụng cứu hộ Việt Nam',
      type: 'MOBILE_APP',
      description: 'Cơ sở dữ liệu độc lập cho app cứu hộ toàn quốc, tách khỏi hệ thống web cũ.',
    },
  });

  await prisma.administrativeUnit.createMany({
    data: AREAS.map(area => ({
      id: area.id,
      projectId: PROJECT_ID,
      code: area.id,
      name: area.current_name || area.old_name,
      level: 'PROVINCE',
      riskLevel: area.risk_level || 'LOW',
      latitude: area.latitude,
      longitude: area.longitude,
      metadata: {
        displayName: area.old_name,
        areaType: area.area_type,
        parentName: area.parent_name,
        provinceName: area.province_name,
      },
    })),
  });

  await prisma.user.createMany({
    data: USERS.map(user => ({
      id: user.id,
      projectId: PROJECT_ID,
      fullName: user.full_name,
      phone: user.phone,
      email: user.email,
      passwordHash: bcrypt.hashSync(user.password_hash || seedPasswordFor(user.role), 12),
      role: user.role,
      status: user.status,
      avatar: user.avatar,
      createdAt: toDate(user.created_at),
    })),
    skipDuplicates: true,
  });

  await prisma.citizenProfile.createMany({
    data: CITIZEN_PROFILES.map(profile => ({
      id: profile.id,
      projectId: PROJECT_ID,
      userId: profile.user_id,
      areaId: profile.area_id,
      addressDetail: `${profile.village_name || ''}${profile.address_detail ? `, ${profile.address_detail}` : ''}`.replace(/^, /, ''),
      householdSize: profile.household_size || 1,
      elderlyCount: profile.elderly_count || 0,
      childrenCount: profile.children_count || 0,
      disabledCount: profile.disabled_count || 0,
      medicalNotes: profile.medical_notes,
      latitude: profile.latitude,
      longitude: profile.longitude,
      createdAt: toDate(profile.created_at),
    })),
  });

  await prisma.rescueTeam.createMany({
    data: RESCUE_TEAMS.map(team => ({
      id: team.id,
      projectId: PROJECT_ID,
      areaId: team.area_id,
      name: team.team_name,
      phone: team.phone,
      leaderId: team.leader_id,
      status: team.status,
      vehicleType: team.vehicle_type,
      memberCount: team.member_count || 0,
      latitude: team.latitude,
      longitude: team.longitude,
      notes: team.note,
      createdAt: toDate(team.created_at),
    })),
  });

  await prisma.rescueTeamMember.createMany({
    data: RESCUE_TEAMS.flatMap(team => {
      const members = Array.isArray(team.members) ? team.members : [];
      const leader = team.leader_id ? [team.leader_id] : [];
      return [...new Set([...leader, ...members])].map(userId => ({
        teamId: team.id,
        userId,
        position: userId === team.leader_id ? 'Đội trưởng' : 'Thành viên',
      }));
    }),
    skipDuplicates: true,
  });

  await prisma.alert.createMany({
    data: FLOOD_WARNINGS.map(alert => ({
      id: alert.id,
      projectId: PROJECT_ID,
      areaId: alert.area_id,
      title: alert.title,
      content: alert.content,
      type: mapEmergencyType(`${alert.title} ${alert.content}`),
      level: alert.level,
      status: alert.status,
      startTime: toDate(alert.start_time),
      endTime: toDate(alert.end_time),
      createdById: alert.created_by,
      metadata: {
        legacyCollection: 'floodWarnings',
        areaName: alert.area_name,
        smsSent: Boolean(alert.sms_sent),
        smsCount: alert.sms_count || 0,
      },
      createdAt: toDate(alert.created_at),
    })),
  });

  await prisma.rescueRequest.createMany({
    data: RESCUE_REQUESTS.map(request => ({
      id: request.id,
      projectId: PROJECT_ID,
      requestCode: request.id.toUpperCase(),
      source: request.citizen_id ? 'MOBILE_APP' : 'SOS_PUBLIC',
      emergencyType: mapEmergencyType(request.description),
      emergencyLevel: request.emergency_level || 'HIGH',
      status: request.status,
      fullName: request.full_name,
      phone: request.phone,
      areaId: request.area_id,
      areaName: request.area_name,
      addressDetail: request.address_detail,
      description: request.description,
      numberOfPeople: request.number_of_people || 1,
      hasElderly: Boolean(request.has_elderly),
      hasChildren: Boolean(request.has_children),
      hasDisabled: Boolean(request.has_disabled),
      hasMedicalCase: Boolean(request.has_medical_case),
      latitude: request.latitude,
      longitude: request.longitude,
      createdByUserId: request.citizen_id,
      assignedTeamId: request.assigned_team_id,
      acceptedAt: toDate(request.accepted_at),
      completedAt: toDate(request.completed_at),
      createdAt: toDate(request.created_at),
    })),
  });

  await prisma.rescueMission.createMany({
    data: RESCUE_MISSIONS.map(mission => ({
      id: mission.id,
      projectId: PROJECT_ID,
      requestId: mission.rescue_request_id,
      teamId: mission.rescue_team_id,
      status: mapMissionStatus(mission.status),
      startedAt: toDate(mission.started_at),
      completedAt: toDate(mission.completed_at),
      latestLatitude: mission.current_rescuer_latitude,
      latestLongitude: mission.current_rescuer_longitude,
      notes: mission.completion_note,
      createdAt: toDate(mission.created_at),
    })),
  });

  await prisma.missionStatusLog.createMany({
    data: MISSION_STATUS_LOGS.map(log => ({
      id: log.id,
      missionId: log.mission_id,
      oldStatus: log.old_status ? mapMissionStatus(log.old_status) : undefined,
      newStatus: mapMissionStatus(log.new_status),
      changedById: log.changed_by_user_id,
      note: log.note,
      createdAt: toDate(log.created_at),
    })),
  });

  await prisma.safeZone.createMany({
    data: SAFE_ZONES.map(zone => ({
      id: zone.id,
      projectId: PROJECT_ID,
      areaId: zone.area_id,
      name: zone.name,
      address: zone.address,
      latitude: zone.latitude,
      longitude: zone.longitude,
      capacity: zone.capacity || 0,
      currentPeople: zone.current_people || 0,
      contactPerson: zone.contact_person,
      contactPhone: zone.contact_phone,
      status: zone.status,
      createdAt: toDate(zone.created_at),
    })),
  });

  await prisma.rescueRoute.createMany({
    data: RESCUE_ROUTES.map(route => ({
      id: route.id,
      projectId: PROJECT_ID,
      areaId: route.area_id,
      name: route.name,
      startPoint: route.start_point,
      endPoint: route.end_point,
      status: mapRouteStatus(route.status),
      notes: route.note,
      createdAt: toDate(route.created_at),
    })),
  });

  await prisma.vulnerableHousehold.createMany({
    data: VULNERABLE_HOUSEHOLDS.map(household => ({
      id: household.id,
      projectId: PROJECT_ID,
      profileId: household.citizen_profile_id,
      areaId: household.area_id,
      householdName: household.household_name,
      address: household.address,
      priorityLevel: mapRiskLevel(household.priority_level),
      peopleCount: household.people_count || 1,
      elderlyCount: household.elderly_count || 0,
      childrenCount: household.children_count || 0,
      disabledCount: household.disabled_count || 0,
      medicalNotes: household.medical_notes,
      latitude: household.latitude,
      longitude: household.longitude,
      createdAt: toDate(household.created_at),
    })),
  });

  await prisma.damageReport.createMany({
    data: DAMAGE_REPORTS.map(report => ({
      id: report.id,
      projectId: PROJECT_ID,
      areaId: report.area_id,
      reporterId: report.reporter_id,
      title: `${report.damage_type} - ${report.area_name}`,
      description: report.description,
      damageType: report.damage_type,
      severity: report.severity || 'MEDIUM',
      status: mapDamageStatus(report.status),
      imageUrls: report.image_url ? [report.image_url] : undefined,
      createdAt: toDate(report.created_at),
    })),
  });

  await prisma.smsLog.createMany({
    data: SMS_LOGS.map(log => ({
      id: log.id,
      projectId: PROJECT_ID,
      alertId: log.related_warning_id,
      recipient: log.phone,
      phone: log.phone,
      message: log.message,
      status: log.status,
      provider: log.provider,
      sentAt: toDate(log.sent_at),
    })),
  });

  await prisma.notification.createMany({
    data: NOTIFICATIONS.map(notification => ({
      id: notification.id,
      projectId: PROJECT_ID,
      userId: notification.user_id,
      title: notification.title,
      message: notification.message,
      type: notification.type,
      isRead: Boolean(notification.is_read),
      createdAt: toDate(notification.created_at),
    })),
  });

  await prisma.activityLog.createMany({
    data: ACTIVITY_LOGS.map(log => ({
      id: log.id,
      projectId: PROJECT_ID,
      userId: log.user_id,
      action: log.action,
      targetType: log.table_name === 'flood_warnings' ? 'alerts' : log.table_name,
      targetId: log.record_id,
      note: log.note,
      createdAt: toDate(log.created_at),
    })),
  });

  console.log(`Prisma seed completed for project ${PROJECT_CODE}.`);
}

main()
  .catch(error => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
