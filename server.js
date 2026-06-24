// RescueVN Express backend for Flutter mobile app.

import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import { getEmbedding, searchCollection } from './vectorDb.js';
import {
  AREAS, USERS, CITIZEN_PROFILES, VULNERABLE_HOUSEHOLDS,
  FLOOD_WARNINGS, RESCUE_REQUESTS, RESCUE_MISSIONS, MISSION_STATUS_LOGS,
  RESCUE_TEAMS, SAFE_ZONES, RESCUE_ROUTES, DAMS, SMS_LOGS,
  DAMAGE_REPORTS, ACTIVITY_LOGS, NOTIFICATIONS
} from './src/data/mockData.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 5000;
const FORCE_JSON_DB = process.env.FORCE_JSON_DB === 'true';
const DATABASE_URL = FORCE_JSON_DB ? '' : (process.env.DATABASE_URL || '');
const USE_PRISMA_DB = Boolean(DATABASE_URL);
const JWT_SECRET = process.env.JWT_SECRET || crypto.randomBytes(32).toString('base64url');
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '8h';
const IS_DEPLOYED_RUNTIME = process.env.NODE_ENV === 'production' || process.env.RENDER === 'true';
const DB_FILE = process.env.DB_FILE ? path.resolve(process.env.DB_FILE) : path.join(__dirname, 'db.json');
const DIST_DIR = path.join(__dirname, 'dist');
const allowedOrigins = (process.env.CLIENT_ORIGINS || '')
  .split(',')
  .map(origin => origin.trim())
  .filter(Boolean);
const defaultAllowedOrigins = [
  'capacitor://localhost',
  'ionic://localhost',
  'http://localhost',
  'https://localhost',
  'http://localhost:5173',
  'http://localhost:5174',
  'http://localhost:5000',
  'http://127.0.0.1:5173',
  'http://127.0.0.1:5174',
  'http://127.0.0.1:5000',
];
const corsAllowedOrigins = new Set([...defaultAllowedOrigins, ...allowedOrigins]);
const prisma = USE_PRISMA_DB ? (await import('./src/lib/prisma.js')).prisma : null;

app.disable('x-powered-by');
app.set('trust proxy', 1);

if (IS_DEPLOYED_RUNTIME && !process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET is required in production/Render');
}

if (!process.env.JWT_SECRET) {
  console.warn('JWT_SECRET is not set. Using a random development-only runtime secret.');
}

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      baseUri: ["'self'"],
      objectSrc: ["'none'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'", 'https://fonts.googleapis.com'],
      fontSrc: ["'self'", 'https://fonts.gstatic.com', 'data:'],
      imgSrc: ["'self'", 'data:', 'blob:'],
      connectSrc: ["'self'", ...Array.from(corsAllowedOrigins)],
      frameAncestors: ["'none'"],
    },
  },
  crossOriginEmbedderPolicy: false,
}));
app.use(cors({
  origin(origin, callback) {
    if (!origin || corsAllowedOrigins.has(origin)) {
      return callback(null, true);
    }

    console.warn(`CORS blocked origin: ${origin}`);
    return callback(null, false);
  },
}));
app.use(express.json({ limit: '1mb' }));

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 500,
  standardHeaders: true,
  legacyHeaders: false,
});
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Qua nhieu lan thu, vui long thu lai sau' },
});
const publicWriteLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api', apiLimiter);

// In-memory representation of our JSON database
let db = {
  areas: AREAS,
  users: USERS,
  citizenProfiles: CITIZEN_PROFILES,
  vulnerableHouseholds: VULNERABLE_HOUSEHOLDS,
  floodWarnings: FLOOD_WARNINGS,
  rescueRequests: RESCUE_REQUESTS,
  rescueMissions: RESCUE_MISSIONS,
  missionStatusLogs: MISSION_STATUS_LOGS,
  rescueTeams: RESCUE_TEAMS,
  safeZones: SAFE_ZONES,
  rescueRoutes: RESCUE_ROUTES,
  dams: DAMS,
  smsLogs: SMS_LOGS,
  damageReports: DAMAGE_REPORTS,
  activityLogs: ACTIVITY_LOGS,
  notifications: NOTIFICATIONS
};
const COLLECTION_NAMES = Object.keys(db);
const ADMIN_ROLES = ['ADMIN', 'SUPER_ADMIN'];
const RESCUE_ROLES = ['RESCUE_LEADER', 'RESCUE_MEMBER'];
const DANGEROUS_KEYS = new Set(['__proto__', 'prototype', 'constructor']);
const WARNING_FIELDS = ['title', 'content', 'level', 'status', 'area_id', 'area_name', 'start_time', 'end_time'];
const REGISTER_FIELDS = [
  'full_name', 'fullName', 'name', 'phone', 'email', 'password',
  'area_id', 'areaId', 'address_detail', 'addressDetail', 'household_size',
  'householdSize', 'elderly_count', 'elderlyCount', 'children_count',
  'childrenCount', 'disabled_count', 'disabledCount', 'medical_notes',
  'medicalNotes', 'latitude', 'longitude',
];
const RESCUE_REQUEST_PUBLIC_FIELDS = [
  'full_name', 'phone', 'area_id', 'area_name', 'address_detail', 'description', 'note',
  'number_of_people', 'emergency_level', 'latitude', 'longitude', 'has_elderly',
  'has_children', 'has_disabled', 'has_medical_case', 'sos_mode',
];
const RESCUE_REQUEST_UPDATE_FIELDS = [
  ...RESCUE_REQUEST_PUBLIC_FIELDS, 'status', 'assigned_team_id', 'assigned_team_name',
  'accepted_at', 'completed_at',
];
const TEAM_FIELDS = [
  'team_name', 'name', 'phone', 'leader_user_id', 'leader_id', 'leader_name',
  'status', 'latitude', 'longitude', 'member_count', 'memberCount', 'notes', 'area_id', 'area_name',
];
const SAFE_ZONE_FIELDS = [
  'name', 'address', 'area_id', 'area_name', 'capacity', 'current_people', 'latitude',
  'longitude', 'manager_name', 'manager_phone', 'contact_person', 'contact_phone', 'notes', 'status',
];
const ROUTE_FIELDS = [
  'name', 'from_location', 'to_location', 'area_id', 'area_name', 'distance_km',
  'estimated_minutes', 'difficulty', 'status', 'notes', 'waypoints',
];
const DAMAGE_REPORT_FIELDS = [
  'reporter_id', 'reporter_name', 'phone', 'area_id', 'area_name', 'address_detail',
  'damage_type', 'severity', 'description', 'estimated_loss', 'latitude', 'longitude', 'images',
];
const VULNERABLE_HOUSEHOLD_FIELDS = [
  'full_name', 'head_name', 'phone', 'area_id', 'area_name', 'address_detail',
  'household_size', 'elderly_count', 'children_count', 'disabled_count', 'medical_note',
  'emergency_contact_name', 'emergency_contact_phone', 'latitude', 'longitude', 'priority_level', 'notes',
];
const SMS_LOG_FIELDS = ['recipient', 'phone', 'message', 'status', 'provider', 'error', 'user_id', 'flood_warning_id', 'floodAlertId'];
const DEFAULT_PROJECT_CODE = process.env.APP_PROJECT_CODE || 'RESCUEVN_APP';
let activeProject = null;
const registeredDeviceTokens = new Map();

function toNumber(value) {
  return value === null || value === undefined ? null : Number(value);
}

function toIso(value) {
  return value ? new Date(value).toISOString() : null;
}

function mapEmergencyType(text = '') {
  const value = String(text).toLowerCase();
  if (value.includes('cáº¥p cá»©u') || value.includes('y táº¿') || value.includes('bá»‡nh')) return 'MEDICAL';
  if (value.includes('chĂ¡y')) return 'FIRE';
  if (value.includes('tai náº¡n')) return 'TRAFFIC_ACCIDENT';
  if (value.includes('sáº¡t lá»Ÿ')) return 'LANDSLIDE';
  if (value.includes('máº¥t tĂ­ch') || value.includes('láº¡c')) return 'MISSING_PERSON';
  if (value.includes('cĂ´ láº­p')) return 'ISOLATED';
  if (value.includes('sÆ¡ tĂ¡n') || value.includes('di táº£n')) return 'EVACUATION';
  if (value.includes('thá»±c') || value.includes('nÆ°á»›c')) return 'FOOD_WATER';
  if (value.includes('ngáº­p') || value.includes('lÅ©')) return 'FLOOD';
  return 'OTHER';
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
    UNREACHABLE: 'CANCELLED',
    NEED_SUPPORT: 'NEED_SUPPORT',
    CANCELLED: 'CANCELLED',
  };
  return map[status] || status || 'CREATED';
}

function missionStatusToRequestStatus(status, requestedStatus) {
  if (requestedStatus === 'UNREACHABLE') return 'UNREACHABLE';
  if (requestedStatus === 'TRANSFERRED_SAFEZONE') return 'TRANSFERRED_SAFEZONE';
  const map = {
    CREATED: 'ASSIGNED',
    DISPATCHED: 'ASSIGNED',
    ACCEPTED: 'ACCEPTED',
    MOVING: 'MOVING',
    ARRIVED: 'ARRIVED_CONFIRMED',
    RESCUING: 'RESCUING',
    COMPLETED: 'RESCUED',
    CANCELLED: 'CANCELLED',
    NEED_SUPPORT: 'NEED_SUPPORT',
  };
  return map[status] || status;
}

function seedPasswordFor(role) {
  if (role === 'ADMIN' || role === 'SUPER_ADMIN' || role === 'DISPATCHER') return process.env.SEED_ADMIN_PASSWORD || 'admin123';
  if (role === 'RESCUE_LEADER' || role === 'RESCUE_MEMBER') return process.env.SEED_RESCUE_PASSWORD || 'rescue123';
  return process.env.SEED_CITIZEN_PASSWORD || 'citizen123';
}

function areaName(area) {
  return area?.metadata?.displayName || area?.name || null;
}

function toLegacyArea(area) {
  return {
    id: area.id,
    old_name: area.metadata?.displayName || area.name,
    current_name: area.name,
    area_type: area.metadata?.areaType || area.level,
    parent_name: area.metadata?.parentName || null,
    province_name: area.metadata?.provinceName || 'Viá»‡t Nam',
    risk_level: area.riskLevel,
    latitude: toNumber(area.latitude),
    longitude: toNumber(area.longitude),
  };
}

function toLegacyUser(user) {
  return {
    id: user.id,
    full_name: user.fullName,
    phone: user.phone,
    email: user.email,
    password_hash: user.passwordHash,
    role: user.role,
    status: user.status,
    avatar: user.avatar,
    created_at: toIso(user.createdAt),
    updated_at: toIso(user.updatedAt),
  };
}

function toLegacyProfile(profile) {
  return {
    id: profile.id,
    user_id: profile.userId,
    area_id: profile.areaId,
    village_name: profile.addressDetail,
    address_detail: profile.addressDetail,
    household_size: profile.householdSize,
    elderly_count: profile.elderlyCount,
    children_count: profile.childrenCount,
    disabled_count: profile.disabledCount,
    medical_notes: profile.medicalNotes,
    latitude: toNumber(profile.latitude),
    longitude: toNumber(profile.longitude),
    created_at: toIso(profile.createdAt),
    updated_at: toIso(profile.updatedAt),
  };
}

function toLegacyHousehold(household) {
  return {
    id: household.id,
    citizen_profile_id: household.profileId,
    household_name: household.householdName,
    address: household.address,
    area_id: household.areaId,
    area_name: areaName(household.area),
    priority_level: household.priorityLevel,
    people_count: household.peopleCount,
    household_size: household.peopleCount,
    elderly_count: household.elderlyCount,
    children_count: household.childrenCount,
    disabled_count: household.disabledCount,
    medical_notes: household.medicalNotes,
    latitude: toNumber(household.latitude),
    longitude: toNumber(household.longitude),
    created_at: toIso(household.createdAt),
    updated_at: toIso(household.updatedAt),
  };
}

function toLegacyTeam(team) {
  return {
    id: team.id,
    team_name: team.name,
    name: team.name,
    area_id: team.areaId,
    area_name: areaName(team.area),
    phone: team.phone,
    leader_id: team.leaderId,
    leader_name: team.leader?.fullName || null,
    status: team.status,
    vehicle_type: team.vehicleType,
    member_count: team.memberCount,
    latitude: toNumber(team.latitude),
    longitude: toNumber(team.longitude),
    note: team.notes,
    created_at: toIso(team.createdAt),
    updated_at: toIso(team.updatedAt),
  };
}

function toLegacyWarning(alert) {
  return {
    id: alert.id,
    title: alert.title,
    content: alert.content,
    level: alert.level,
    status: alert.status,
    area_id: alert.areaId,
    area_name: areaName(alert.area) || alert.metadata?.areaName,
    start_time: toIso(alert.startTime),
    end_time: toIso(alert.endTime),
    created_by: alert.createdById,
    created_at: toIso(alert.createdAt),
    updated_at: toIso(alert.updatedAt),
    sms_sent: Boolean(alert.metadata?.smsSent),
    sms_count: alert.metadata?.smsCount || 0,
  };
}

function toLegacyRequest(request) {
  return {
    id: request.id,
    citizen_id: request.createdByUserId,
    user_id: request.createdByUserId,
    area_id: request.areaId,
    area_name: request.areaName || areaName(request.area),
    full_name: request.fullName,
    phone: request.phone,
    address_detail: request.addressDetail,
    latitude: toNumber(request.latitude),
    longitude: toNumber(request.longitude),
    number_of_people: request.numberOfPeople,
    has_children: request.hasChildren,
    has_elderly: request.hasElderly,
    has_disabled: request.hasDisabled,
    has_medical_case: request.hasMedicalCase,
    emergency_level: request.emergencyLevel,
    description: request.description,
    assigned_team_id: request.assignedTeamId,
    assigned_team_name: request.assignedTeam?.name || null,
    status: request.status,
    created_at: toIso(request.createdAt),
    accepted_at: toIso(request.acceptedAt),
    completed_at: toIso(request.completedAt),
    updated_at: toIso(request.updatedAt),
  };
}

function toLegacyMission(mission) {
  const request = mission.request;
  return {
    id: mission.id,
    rescue_request_id: mission.requestId,
    rescue_team_id: mission.teamId,
    team_name: mission.team?.name || null,
    victim_name: request?.fullName || null,
    victim_phone: request?.phone || null,
    victim_latitude: toNumber(request?.latitude),
    victim_longitude: toNumber(request?.longitude),
    victim_address: request?.addressDetail || null,
    current_rescuer_latitude: toNumber(mission.latestLatitude),
    current_rescuer_longitude: toNumber(mission.latestLongitude),
    status: missionStatusToRequestStatus(mission.status),
    assigned_at: toIso(mission.createdAt),
    started_at: toIso(mission.startedAt),
    completed_at: toIso(mission.completedAt),
    completion_note: mission.notes || '',
    area_id: request?.areaId || null,
    area_name: request?.areaName || areaName(request?.area),
    created_at: toIso(mission.createdAt),
    updated_at: toIso(mission.updatedAt),
  };
}

function toLegacyMissionLog(log) {
  return {
    id: log.id,
    mission_id: log.missionId,
    old_status: log.oldStatus ? missionStatusToRequestStatus(log.oldStatus) : null,
    new_status: missionStatusToRequestStatus(log.newStatus),
    changed_by_user_id: log.changedById,
    note: log.note,
    created_at: toIso(log.createdAt),
  };
}

function toLegacySafeZone(zone) {
  return {
    id: zone.id,
    name: zone.name,
    area_id: zone.areaId,
    area_name: areaName(zone.area),
    address: zone.address,
    latitude: toNumber(zone.latitude),
    longitude: toNumber(zone.longitude),
    capacity: zone.capacity,
    current_people: zone.currentPeople,
    contact_person: zone.contactPerson,
    contact_phone: zone.contactPhone,
    status: zone.status,
    notes: zone.notes,
    created_at: toIso(zone.createdAt),
    updated_at: toIso(zone.updatedAt),
  };
}

function toLegacyRoute(route) {
  return {
    id: route.id,
    name: route.name,
    area_id: route.areaId,
    area_name: areaName(route.area),
    start_point: route.startPoint,
    end_point: route.endPoint,
    from_location: route.startPoint,
    to_location: route.endPoint,
    distance_km: route.distanceKm ? Number(route.distanceKm) : null,
    status: route.status,
    note: route.notes,
    notes: route.notes,
    waypoints: route.routeGeo,
    created_at: toIso(route.createdAt),
    updated_at: toIso(route.updatedAt),
  };
}

function toLegacyDamage(report) {
  return {
    id: report.id,
    reporter_id: report.reporterId,
    area_id: report.areaId,
    area_name: areaName(report.area),
    title: report.title,
    damage_type: report.damageType,
    description: report.description,
    severity: report.severity,
    status: report.status,
    image_url: Array.isArray(report.imageUrls) ? report.imageUrls[0] : null,
    latitude: toNumber(report.latitude),
    longitude: toNumber(report.longitude),
    created_at: toIso(report.createdAt),
    updated_at: toIso(report.updatedAt),
  };
}

function toLegacySms(log) {
  return {
    id: log.id,
    user_id: log.userId,
    related_warning_id: log.alertId,
    recipient: log.recipient,
    phone: log.phone,
    message: log.message,
    status: log.status,
    provider: log.provider,
    error: log.error,
    sent_at: toIso(log.sentAt),
    created_at: toIso(log.createdAt),
  };
}

function toLegacyNotification(notification) {
  return {
    id: notification.id,
    user_id: notification.userId,
    title: notification.title,
    message: notification.message,
    type: notification.type,
    is_read: notification.isRead,
    related_id: notification.requestId,
    created_at: toIso(notification.createdAt),
  };
}

function toLegacyActivity(log) {
  return {
    id: log.id,
    user_id: log.userId,
    user_name: log.user?.fullName || log.actorType || null,
    action: log.action,
    table_name: log.targetType,
    record_id: log.targetId,
    note: log.note,
    created_at: toIso(log.createdAt),
  };
}

async function getActiveProject() {
  if (!prisma) return null;
  if (activeProject) return activeProject;

  activeProject = await prisma.appProject.findUnique({ where: { code: DEFAULT_PROJECT_CODE } });
  if (!activeProject) {
    activeProject = await prisma.appProject.create({
      data: {
        code: DEFAULT_PROJECT_CODE,
        name: 'á»¨ng dá»¥ng cá»©u há»™ Viá»‡t Nam',
        type: 'MOBILE_APP',
        description: 'Project máº·c Ä‘á»‹nh cho app cá»©u há»™ Ä‘á»™c láº­p.',
      },
    });
  }
  return activeProject;
}

function projectWhere(project, extra = {}) {
  return { projectId: project.id, ...extra };
}

function sanitizeObject(value) {
  if (Array.isArray(value)) {
    return value.map(sanitizeObject);
  }

  if (!value || typeof value !== 'object') {
    return typeof value === 'string' ? value.trim().slice(0, 2000) : value;
  }

  const clean = {};
  for (const [key, item] of Object.entries(value)) {
    if (!DANGEROUS_KEYS.has(key)) {
      clean[key] = sanitizeObject(item);
    }
  }
  return clean;
}

function pickAllowed(source, allowedKeys) {
  const cleanSource = sanitizeObject(source || {});
  return allowedKeys.reduce((result, key) => {
    if (Object.prototype.hasOwnProperty.call(cleanSource, key)) {
      result[key] = cleanSource[key];
    }
    return result;
  }, {});
}

function safeUser(user) {
  if (!user) return null;
  const safe = { ...user };
  delete safe.password_hash;
  delete safe.passwordHash;
  return sanitizeObject(safe);
}

function sanitizeDbForUser(user) {
  const publicDb = {
    areas: db.areas,
    floodWarnings: db.floodWarnings,
    safeZones: db.safeZones,
    dams: db.dams,
  };

  if (!user) {
    return publicDb;
  }

  const safeDb = {
    ...db,
    users: Array.isArray(db.users) ? db.users.map(safeUser) : [],
  };

  if (!ADMIN_ROLES.includes(user.role)) {
    delete safeDb.smsLogs;
    delete safeDb.activityLogs;
  }

  return sanitizeObject(safeDb);
}

function applySeedPasswords() {
  if (!Array.isArray(db.users)) return;

  const seedPasswords = {
    ADMIN: process.env.SEED_ADMIN_PASSWORD || 'admin123',
    SUPER_ADMIN: process.env.SEED_ADMIN_PASSWORD || 'admin123',
    RESCUE_LEADER: process.env.SEED_RESCUE_PASSWORD || 'rescue123',
    RESCUE_MEMBER: process.env.SEED_RESCUE_PASSWORD || 'rescue123',
    CITIZEN: process.env.SEED_CITIZEN_PASSWORD || 'citizen123',
  };

  for (const user of db.users) {
    if (user.password_hash || user.passwordHash) continue;

    const seedPassword = seedPasswords[user.role];
    if (seedPassword) {
      user.password_hash = bcrypt.hashSync(seedPassword, 12);
    } else {
      user.status = 'BLOCKED';
      console.warn(`Seed user ${user.id} is blocked because no seed password was configured.`);
    }
  }
}

function hardenLegacyPasswords() {
  if (prisma) return;
  if (!Array.isArray(db.users)) return;

  let changed = false;
  for (const user of db.users) {
    const storedPassword = String(user.password_hash || user.passwordHash || '');
    const isBcryptHash = storedPassword.startsWith('$2a$') || storedPassword.startsWith('$2b$') || storedPassword.startsWith('$2y$');
    if (storedPassword && !isBcryptHash) {
      user.password_hash = bcrypt.hashSync(storedPassword, 12);
      changed = true;
    }
  }

  if (changed) {
    saveDb();
    console.log('Legacy plaintext passwords were upgraded to bcrypt hashes.');
  }
}

function issueToken(user) {
  return jwt.sign(
    {
      sub: user.id,
      role: user.role,
      name: user.full_name || user.fullName || '',
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
}

async function findUserById(id) {
  if (prisma) {
    const project = await getActiveProject();
    const user = await prisma.user.findFirst({ where: { id, projectId: project.id } });
    return user ? toLegacyUser(user) : null;
  }
  return (Array.isArray(db.users) ? db.users : []).find(user => user.id === id);
}

async function authenticateOptional(req, res, next) {
  const authHeader = req.get('authorization') || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';

  if (!token) return next();

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    const user = await findUserById(payload.sub);
    if (user && user.status !== 'BLOCKED') {
      req.user = safeUser(user);
    }
  } catch {
    req.authError = true;
  }

  return next();
}

function requireAuth(req, res, next) {
  authenticateOptional(req, res, () => {
    if (req.user) return next();
    return res.status(401).json({ error: 'Authentication required' });
  });
}

function requireRoles(roles) {
  return (req, res, next) => {
    requireAuth(req, res, () => {
      if (roles.includes(req.user.role)) return next();
      return res.status(403).json({ error: 'Permission denied' });
    });
  };
}

async function verifyPassword(user, plainPassword) {
  const storedPassword = String(user?.password_hash || user?.passwordHash || '');
  if (!storedPassword) return false;

  if (storedPassword.startsWith('$2a$') || storedPassword.startsWith('$2b$') || storedPassword.startsWith('$2y$')) {
    return bcrypt.compare(plainPassword, storedPassword);
  }

  const isLegacyMatch = storedPassword === plainPassword;
  if (isLegacyMatch && !prisma) {
    user.password_hash = await bcrypt.hash(plainPassword, 12);
    saveDb();
  }
  return isLegacyMatch;
}

async function loadRelationalDb() {
  const project = await getActiveProject();
  const scoped = (extra = {}) => projectWhere(project, extra);

  const [
    areas,
    users,
    citizenProfiles,
    vulnerableHouseholds,
    alerts,
    rescueRequests,
    rescueMissions,
    missionStatusLogs,
    rescueTeams,
    safeZones,
    rescueRoutes,
    smsLogs,
    damageReports,
    activityLogs,
    notifications,
  ] = await Promise.all([
    prisma.administrativeUnit.findMany({ where: scoped(), orderBy: { createdAt: 'asc' } }),
    prisma.user.findMany({ where: scoped(), orderBy: { createdAt: 'asc' } }),
    prisma.citizenProfile.findMany({ where: scoped(), orderBy: { createdAt: 'asc' } }),
    prisma.vulnerableHousehold.findMany({ where: scoped(), include: { area: true }, orderBy: { createdAt: 'asc' } }),
    prisma.alert.findMany({ where: scoped(), include: { area: true }, orderBy: { createdAt: 'desc' } }),
    prisma.rescueRequest.findMany({ where: scoped(), include: { area: true, assignedTeam: true }, orderBy: { createdAt: 'desc' } }),
    prisma.rescueMission.findMany({ where: scoped(), include: { team: true, request: { include: { area: true } } }, orderBy: { createdAt: 'desc' } }),
    prisma.missionStatusLog.findMany({ where: { mission: { projectId: project.id } }, orderBy: { createdAt: 'asc' } }),
    prisma.rescueTeam.findMany({ where: scoped(), include: { area: true, leader: true }, orderBy: { createdAt: 'asc' } }),
    prisma.safeZone.findMany({ where: scoped(), include: { area: true }, orderBy: { createdAt: 'asc' } }),
    prisma.rescueRoute.findMany({ where: scoped(), include: { area: true }, orderBy: { createdAt: 'asc' } }),
    prisma.smsLog.findMany({ where: scoped(), orderBy: { createdAt: 'desc' } }),
    prisma.damageReport.findMany({ where: scoped(), include: { area: true }, orderBy: { createdAt: 'desc' } }),
    prisma.activityLog.findMany({ where: scoped(), include: { user: true }, orderBy: { createdAt: 'desc' } }),
    prisma.notification.findMany({ where: scoped(), orderBy: { createdAt: 'desc' } }),
  ]);

  return {
    areas: areas.map(toLegacyArea),
    users: users.map(toLegacyUser),
    citizenProfiles: citizenProfiles.map(toLegacyProfile),
    vulnerableHouseholds: vulnerableHouseholds.map(toLegacyHousehold),
    floodWarnings: alerts.map(toLegacyWarning),
    rescueRequests: rescueRequests.map(toLegacyRequest),
    rescueMissions: rescueMissions.map(toLegacyMission),
    missionStatusLogs: missionStatusLogs.map(toLegacyMissionLog),
    rescueTeams: rescueTeams.map(toLegacyTeam),
    safeZones: safeZones.map(toLegacySafeZone),
    rescueRoutes: rescueRoutes.map(toLegacyRoute),
    dams: DAMS,
    smsLogs: smsLogs.map(toLegacySms),
    damageReports: damageReports.map(toLegacyDamage),
    activityLogs: activityLogs.map(toLegacyActivity),
    notifications: notifications.map(toLegacyNotification),
  };
}

async function initializePostgres() {
  if (!prisma) return false;
  await getActiveProject();
  db = await loadRelationalDb();
  console.log('Database loaded from PostgreSQL relational schema');
  return true;
}

// Helper function to save DB to file
function saveDb() {
  if (prisma) {
    return;
  }

  try {
    fs.mkdirSync(path.dirname(DB_FILE), { recursive: true });
    const tempFile = `${DB_FILE}.${process.pid}.tmp`;
    fs.writeFileSync(tempFile, JSON.stringify(db, null, 2), 'utf-8');
    fs.renameSync(tempFile, DB_FILE);
  } catch (err) {
    console.error('Failed to write db.json:', err);
  }
}

applySeedPasswords();

// Initialize database: load from db.json if it exists, otherwise seed it
const usingPostgres = await initializePostgres();

if (!usingPostgres && fs.existsSync(DB_FILE)) {
  try {
    const rawData = fs.readFileSync(DB_FILE, 'utf-8');
    db = JSON.parse(rawData);
    console.log('Database loaded from db.json');
  } catch (err) {
    console.error('Error reading db.json, fallback to mock data seed:', err);
  }
} else if (!usingPostgres) {
  console.log('No db.json found. Seeding database with mock data and generating vector embeddings...');
  
  // Seed vector embeddings for initial rescue requests
  db.rescueRequests = db.rescueRequests.map(r => {
    const textToEmbed = `${r.full_name || ''} ${r.address_detail || ''} ${r.note || ''}`;
    return { ...r, vector_embedding: getEmbedding(textToEmbed) };
  });

  // Seed vector embeddings for initial warnings
  db.floodWarnings = db.floodWarnings.map(w => {
    const textToEmbed = `${w.title || ''} ${w.content || ''} ${w.area_name || ''}`;
    return { ...w, vector_embedding: getEmbedding(textToEmbed) };
  });

  // Seed vector embeddings for initial safe zones
  db.safeZones = db.safeZones.map(s => {
    const textToEmbed = `${s.name || ''} ${s.address || ''} ${s.notes || ''}`;
    return { ...s, vector_embedding: getEmbedding(textToEmbed) };
  });

  saveDb();
  console.log('Database successfully seeded and saved to db.json');
}

hardenLegacyPasswords();

// ---------------------- API ROUTES ----------------------

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    uptime: process.uptime(),
    database: prisma ? 'postgresql-relational' : 'json-file',
    projectCode: prisma ? DEFAULT_PROJECT_CODE : null,
    dbFile: prisma ? null : DB_FILE,
    timestamp: new Date().toISOString()
  });
});

app.get('/api/readiness', async (req, res) => {
  try {
    if (prisma) {
      const project = await getActiveProject();
      await prisma.user.count({ where: { projectId: project.id } });
      return res.json({
        status: 'ready',
        database: 'postgresql-relational',
        projectCode: project.code,
        timestamp: new Date().toISOString(),
      });
    }

    const required = ['areas', 'users', 'rescueRequests', 'rescueTeams', 'safeZones'];
    const missing = required.filter(key => !Array.isArray(db[key]));
    if (missing.length > 0) {
      return res.status(503).json({
        status: 'not_ready',
        database: 'json-file',
        missing,
        timestamp: new Date().toISOString(),
      });
    }

    return res.json({
      status: 'ready',
      database: 'json-file',
      dbFile: DB_FILE,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    console.error('Readiness check failed:', err);
    return res.status(503).json({
      status: 'not_ready',
      message: 'Database is not ready',
      timestamp: new Date().toISOString(),
    });
  }
});

// 1. GET ALL DATABASE STATE (Sync on page load)
app.get('/api/db', authenticateOptional, async (req, res) => {
  if (req.authError) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
  if (prisma) {
    db = await loadRelationalDb();
  }
  res.json(sanitizeDbForUser(req.user));
});

// 2. AUTH LOGIN
app.post('/api/auth/login', authLimiter, async (req, res) => {
  try {
    const normalize = value => (typeof value === 'string' ? value.trim() : '');
    const { emailOrPhone, password } = req.body || {};
    const credential = normalize(emailOrPhone).toLowerCase();
    const plainPassword = normalize(password);

    if (!credential || !plainPassword) {
      return res.status(400).json({
        success: false,
        message: 'Vui long nhap email/so dien thoai va mat khau'
      });
    }

    const users = prisma
      ? (await prisma.user.findMany({ where: { projectId: (await getActiveProject()).id } })).map(toLegacyUser)
      : (Array.isArray(db.users) ? db.users : []);
    if (users.length === 0) {
      console.error('Login failed: users collection is empty or invalid');
      return res.status(503).json({
        success: false,
        message: 'Du lieu nguoi dung chua san sang, vui long thu lai'
      });
    }

    const user = users.find(u => {
      const email = normalize(u?.email).toLowerCase();
      const phone = normalize(u?.phone);
      return email === credential || phone === credential;
    });

    if (!user || user.status === 'BLOCKED' || !(await verifyPassword(user, plainPassword))) {
      return res.status(401).json({
        success: false,
        message: 'Sai tai khoan hoac mat khau'
      });
    }

    const profiles = prisma
      ? (await prisma.citizenProfile.findMany({ where: { projectId: (await getActiveProject()).id } })).map(toLegacyProfile)
      : (Array.isArray(db.citizenProfiles) ? db.citizenProfiles : []);
    const profile = profiles.find(p => p.user_id === user.id);
    const userForClient = safeUser(user);
    const token = issueToken(user);

    return res.json({ success: true, user: userForClient, profile: profile || null, token });
  } catch (err) {
    console.error('Login route failed:', err);
    return res.status(500).json({
      success: false,
      message: 'May chu dang loi dang nhap, vui long thu lai'
    });
  }
});

app.post('/api/auth/register', publicWriteLimiter, async (req, res) => {
  try {
    const data = pickAllowed(req.body, REGISTER_FIELDS);
    const normalize = value => (typeof value === 'string' ? value.trim() : '');
    const fullName = normalize(data.full_name || data.fullName || data.name);
    const phone = normalize(data.phone);
    const email = normalize(data.email).toLowerCase();
    const password = normalize(data.password);
    const addressDetail = normalize(data.address_detail || data.addressDetail);
    const areaId = normalize(data.area_id || data.areaId) || null;
    const householdSize = Math.max(1, Number(data.household_size || data.householdSize || 1));

    if (!fullName || !phone || !password) {
      return res.status(400).json({
        success: false,
        message: 'Vui long nhap ho ten, so dien thoai va mat khau'
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Mat khau can toi thieu 6 ky tu'
      });
    }

    const passwordHash = await bcrypt.hash(password, 12);

    if (prisma) {
      const project = await getActiveProject();
      const existing = await prisma.user.findFirst({
        where: {
          projectId: project.id,
          OR: [
            { phone },
            ...(email ? [{ email }] : []),
          ],
        },
      });

      if (existing) {
        return res.status(409).json({
          success: false,
          message: 'So dien thoai hoac email da duoc dang ky'
        });
      }

      const user = await prisma.user.create({
        data: {
          projectId: project.id,
          fullName,
          phone,
          email: email || null,
          passwordHash,
          role: 'CITIZEN',
          status: 'ACTIVE',
        },
      });

      const profile = await prisma.citizenProfile.create({
        data: {
          projectId: project.id,
          userId: user.id,
          areaId,
          addressDetail: addressDetail || null,
          householdSize,
          elderlyCount: Number(data.elderly_count || data.elderlyCount || 0),
          childrenCount: Number(data.children_count || data.childrenCount || 0),
          disabledCount: Number(data.disabled_count || data.disabledCount || 0),
          medicalNotes: normalize(data.medical_notes || data.medicalNotes) || null,
          latitude: data.latitude ?? null,
          longitude: data.longitude ?? null,
        },
      });

      const legacyUser = toLegacyUser(user);
      const userForClient = safeUser(legacyUser);
      const token = issueToken(legacyUser);
      return res.status(201).json({
        success: true,
        user: userForClient,
        profile: toLegacyProfile(profile),
        token,
      });
    }

    const users = Array.isArray(db.users) ? db.users : [];
    const exists = users.some(user => {
      const samePhone = normalize(user.phone) === phone;
      const sameEmail = email && normalize(user.email).toLowerCase() === email;
      return samePhone || sameEmail;
    });

    if (exists) {
      return res.status(409).json({
        success: false,
        message: 'So dien thoai hoac email da duoc dang ky'
      });
    }

    const now = new Date().toISOString();
    const user = {
      id: `user-${Date.now()}`,
      full_name: fullName,
      phone,
      email: email || null,
      password_hash: passwordHash,
      role: 'CITIZEN',
      status: 'ACTIVE',
      avatar: null,
      created_at: now,
      updated_at: now,
    };
    const profile = {
      id: `profile-${Date.now()}`,
      user_id: user.id,
      area_id: areaId,
      village_name: addressDetail,
      address_detail: addressDetail,
      household_size: householdSize,
      elderly_count: Number(data.elderly_count || data.elderlyCount || 0),
      children_count: Number(data.children_count || data.childrenCount || 0),
      disabled_count: Number(data.disabled_count || data.disabledCount || 0),
      medical_notes: normalize(data.medical_notes || data.medicalNotes),
      latitude: data.latitude ?? null,
      longitude: data.longitude ?? null,
      created_at: now,
      updated_at: now,
    };

    db.users.unshift(user);
    db.citizenProfiles.unshift(profile);
    saveDb();

    const userForClient = safeUser(user);
    const token = issueToken(user);
    return res.status(201).json({ success: true, user: userForClient, profile, token });
  } catch (err) {
    console.error('Register route failed:', err);
    return res.status(500).json({
      success: false,
      message: 'May chu dang loi dang ky, vui long thu lai'
    });
  }
});

app.use('/api/auth/login-legacy', (req, res) => {
  res.status(410).json({ success: false, message: 'Legacy login endpoint has been disabled' });
});

// 3. SEMANTIC VECTOR SEARCH
app.get('/api/search', requireRoles([...ADMIN_ROLES, ...RESCUE_ROLES]), async (req, res) => {
  const { q, type } = req.query;
  if (!q) {
    return res.status(400).json({ error: 'Query parameter "q" is required' });
  }
  if (prisma) {
    db = await loadRelationalDb();
  }

  let collection;
  let extractTextFn;

  if (type === 'requests') {
    collection = db.rescueRequests;
    extractTextFn = (item) => `${item.full_name || ''} ${item.address_detail || ''} ${item.note || ''}`;
  } else if (type === 'warnings') {
    collection = db.floodWarnings;
    extractTextFn = (item) => `${item.title || ''} ${item.content || ''} ${item.area_name || ''}`;
  } else if (type === 'safezones') {
    collection = db.safeZones;
    extractTextFn = (item) => `${item.name || ''} ${item.address || ''} ${item.notes || ''}`;
  } else {
    return res.status(400).json({ error: 'Invalid or missing "type" parameter. Must be "requests", "warnings", or "safezones"' });
  }

  const results = searchCollection(collection, q, extractTextFn);
  res.json(results);
});

// 4. FLOOD WARNINGS CRUD
app.post('/api/warnings', requireRoles(ADMIN_ROLES), async (req, res) => {
  const data = pickAllowed(req.body, WARNING_FIELDS);
  if (prisma) {
    const project = await getActiveProject();
    const alert = await prisma.alert.create({
      data: {
        id: `fw-${Date.now()}`,
        projectId: project.id,
        areaId: data.area_id || null,
        title: data.title || '',
        content: data.content || '',
        type: mapEmergencyType(`${data.title || ''} ${data.content || ''}`),
        level: data.level || 'MEDIUM',
        status: data.status || 'DRAFT',
        startTime: data.start_time ? new Date(data.start_time) : null,
        endTime: data.end_time ? new Date(data.end_time) : null,
        createdById: req.user?.id || null,
        metadata: { areaName: data.area_name, smsSent: false, smsCount: 0 },
      },
      include: { area: true },
    });
    return res.status(201).json(toLegacyWarning(alert));
  }
  const textToEmbed = `${data.title || ''} ${data.content || ''} ${data.area_name || ''}`;
  const warning = {
    id: `fw-${Date.now()}`,
    ...data,
    vector_embedding: getEmbedding(textToEmbed),
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    sms_sent: false,
    sms_count: 0
  };
  db.floodWarnings.unshift(warning);
  saveDb();
  res.status(201).json(warning);
});

app.put('/api/warnings/:id', requireRoles(ADMIN_ROLES), async (req, res) => {
  const { id } = req.params;
  if (prisma) {
    const existing = await prisma.alert.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ error: 'Warning not found' });
    const data = pickAllowed(req.body, WARNING_FIELDS);
    const alert = await prisma.alert.update({
      where: { id },
      data: {
        title: data.title ?? undefined,
        content: data.content ?? undefined,
        type: data.title || data.content ? mapEmergencyType(`${data.title || existing.title} ${data.content || existing.content}`) : undefined,
        level: data.level ?? undefined,
        status: data.status ?? undefined,
        areaId: data.area_id ?? undefined,
        startTime: data.start_time ? new Date(data.start_time) : undefined,
        endTime: data.end_time ? new Date(data.end_time) : undefined,
        metadata: { ...(existing.metadata || {}), areaName: data.area_name ?? existing.metadata?.areaName },
      },
      include: { area: true },
    });
    return res.json(toLegacyWarning(alert));
  }
  const idx = db.floodWarnings.findIndex(w => w.id === id);
  if (idx === -1) return res.status(404).json({ error: 'Warning not found' });

  const updatedData = { ...db.floodWarnings[idx], ...pickAllowed(req.body, WARNING_FIELDS), updated_at: new Date().toISOString() };
  const textToEmbed = `${updatedData.title || ''} ${updatedData.content || ''} ${updatedData.area_name || ''}`;
  updatedData.vector_embedding = getEmbedding(textToEmbed);

  db.floodWarnings[idx] = updatedData;
  saveDb();
  res.json(updatedData);
});

app.delete('/api/warnings/:id', requireRoles(ADMIN_ROLES), async (req, res) => {
  const { id } = req.params;
  if (prisma) {
    await prisma.alert.deleteMany({ where: { id, projectId: (await getActiveProject()).id } });
    return res.json({ success: true });
  }
  db.floodWarnings = db.floodWarnings.filter(w => w.id !== id);
  saveDb();
  res.json({ success: true });
});

// 5. RESCUE REQUESTS & MISSIONS
app.post('/api/rescue-requests', publicWriteLimiter, authenticateOptional, async (req, res) => {
  const data = pickAllowed(req.body, RESCUE_REQUEST_PUBLIC_FIELDS);
  if (prisma) {
    const project = await getActiveProject();
    const request = await prisma.rescueRequest.create({
      data: {
        id: `rr-${Date.now()}`,
        projectId: project.id,
        requestCode: `RR-${Date.now()}`,
        source: req.user ? 'MOBILE_APP' : (data.sos_mode ? 'SOS_PUBLIC' : 'MOBILE_APP'),
        emergencyType: mapEmergencyType(`${data.description || ''} ${data.note || ''}`),
        emergencyLevel: data.emergency_level || 'HIGH',
        status: 'PENDING',
        fullName: data.full_name || 'NgÆ°á»i dĂ¹ng SOS',
        phone: data.phone || null,
        areaId: data.area_id || null,
        areaName: data.area_name || null,
        addressDetail: data.address_detail || null,
        description: data.description || data.note || null,
        numberOfPeople: Number(data.number_of_people || 1),
        hasElderly: Boolean(data.has_elderly),
        hasChildren: Boolean(data.has_children),
        hasDisabled: Boolean(data.has_disabled),
        hasMedicalCase: Boolean(data.has_medical_case),
        latitude: data.latitude ?? null,
        longitude: data.longitude ?? null,
        createdByUserId: req.user?.id || null,
      },
      include: { area: true, assignedTeam: true },
    });
    return res.status(201).json(toLegacyRequest(request));
  }
  if (req.user) {
    data.user_id = req.user.id;
  }
  const textToEmbed = `${data.full_name || ''} ${data.address_detail || ''} ${data.note || ''}`;
  const request = {
    id: `rr-${Date.now()}`,
    ...data,
    source: req.user ? 'MOBILE_APP' : (data.sos_mode ? 'SOS_PUBLIC' : 'MOBILE_APP'),
    vector_embedding: getEmbedding(textToEmbed),
    status: 'PENDING',
    assigned_team_id: null,
    assigned_team_name: null,
    created_at: new Date().toISOString(),
    accepted_at: null,
    completed_at: null
  };
  db.rescueRequests.unshift(request);
  saveDb();
  res.status(201).json(request);
});

app.put('/api/rescue-requests/:id', requireRoles([...ADMIN_ROLES, ...RESCUE_ROLES]), async (req, res) => {
  const { id } = req.params;
  if (prisma) {
    const existing = await prisma.rescueRequest.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ error: 'Request not found' });
    const data = pickAllowed(req.body, RESCUE_REQUEST_UPDATE_FIELDS);
    const request = await prisma.rescueRequest.update({
      where: { id },
      data: {
        fullName: data.full_name ?? undefined,
        phone: data.phone ?? undefined,
        areaId: data.area_id ?? undefined,
        areaName: data.area_name ?? undefined,
        addressDetail: data.address_detail ?? undefined,
        description: data.description ?? data.note ?? undefined,
        numberOfPeople: data.number_of_people === undefined ? undefined : Number(data.number_of_people),
        emergencyLevel: data.emergency_level ?? undefined,
        status: data.status ?? undefined,
        assignedTeamId: data.assigned_team_id ?? undefined,
        acceptedAt: data.accepted_at ? new Date(data.accepted_at) : undefined,
        completedAt: data.completed_at ? new Date(data.completed_at) : undefined,
        latitude: data.latitude ?? undefined,
        longitude: data.longitude ?? undefined,
        hasElderly: data.has_elderly ?? undefined,
        hasChildren: data.has_children ?? undefined,
        hasDisabled: data.has_disabled ?? undefined,
        hasMedicalCase: data.has_medical_case ?? undefined,
      },
      include: { area: true, assignedTeam: true },
    });
    return res.json(toLegacyRequest(request));
  }
  const idx = db.rescueRequests.findIndex(r => r.id === id);
  if (idx === -1) return res.status(404).json({ error: 'Request not found' });

  db.rescueRequests[idx] = { ...db.rescueRequests[idx], ...pickAllowed(req.body, RESCUE_REQUEST_UPDATE_FIELDS) };
  saveDb();
  res.json(db.rescueRequests[idx]);
});

app.post('/api/rescue-requests/:id/assign', requireRoles(ADMIN_ROLES), async (req, res) => {
  const { id } = req.params;
  const { teamId, teamName } = pickAllowed(req.body, ['teamId', 'teamName']);
  const currentUser = req.user;
  if (prisma) {
    const project = await getActiveProject();
    const existing = await prisma.rescueRequest.findFirst({ where: { id, projectId: project.id } });
    if (!existing) return res.status(404).json({ error: 'Request not found' });

    const [request, mission] = await prisma.$transaction(async tx => {
      const updatedRequest = await tx.rescueRequest.update({
        where: { id },
        data: {
          status: 'ASSIGNED',
          assignedTeamId: teamId,
          acceptedAt: new Date(),
        },
        include: { area: true, assignedTeam: true },
      });
      const createdMission = await tx.rescueMission.create({
        data: {
          id: `rm-${Date.now()}`,
          projectId: project.id,
          requestId: id,
          teamId,
          status: 'DISPATCHED',
        },
        include: { team: true, request: { include: { area: true } } },
      });
      await tx.activityLog.create({
        data: {
          projectId: project.id,
          userId: currentUser?.id || null,
          action: 'PhĂ¢n cĂ´ng Ä‘á»™i cá»©u há»™',
          targetType: 'rescue_requests',
          targetId: id,
          note: `PhĂ¢n cĂ´ng ${teamName || updatedRequest.assignedTeam?.name || teamId}`,
        },
      });
      if (updatedRequest.assignedTeam?.leaderId) {
        await tx.notification.create({
          data: {
            projectId: project.id,
            userId: updatedRequest.assignedTeam.leaderId,
            requestId: id,
            title: 'Nhiá»‡m vá»¥ má»›i!',
            message: `Báº¡n Ä‘Æ°á»£c phĂ¢n cĂ´ng cá»©u há»™ ${updatedRequest.fullName}`,
            type: 'MISSION_ASSIGNED',
          },
        });
      }
      return [updatedRequest, createdMission];
    });

    return res.json({ success: true, request: toLegacyRequest(request), mission: toLegacyMission(mission) });
  }
  
  const reqIdx = db.rescueRequests.findIndex(r => r.id === id);
  if (reqIdx === -1) return res.status(404).json({ error: 'Request not found' });

  const request = db.rescueRequests[reqIdx];
  request.status = 'ASSIGNED';
  request.assigned_team_id = teamId;
  request.assigned_team_name = teamName;
  request.accepted_at = new Date().toISOString();

  // Create corresponding mission
  const mission = {
    id: `rm-${Date.now()}`,
    rescue_request_id: id,
    rescue_team_id: teamId,
    team_name: teamName,
    victim_name: request.full_name,
    victim_phone: request.phone,
    victim_latitude: request.latitude,
    victim_longitude: request.longitude,
    victim_address: request.address_detail,
    current_rescuer_latitude: null,
    current_rescuer_longitude: null,
    checkin_radius_meters: 100,
    max_gps_accuracy_meters: 50,
    min_stay_seconds: 60,
    status: 'ASSIGNED',
    assigned_at: new Date().toISOString(),
    accepted_at: null,
    started_at: null,
    auto_arrival_detected: false,
    auto_arrival_time: null,
    auto_arrival_distance_meters: null,
    manual_arrival_confirmed: false,
    manual_arrival_time: null,
    manual_arrival_by: null,
    rescued_people_count: null,
    destination_safe_zone_id: null,
    completed_at: null,
    completion_note: '',
    area_id: request.area_id,
    area_name: request.area_name,
    created_at: new Date().toISOString()
  };
  
  db.rescueMissions.unshift(mission);

  // Add activity log
  const log = {
    id: `al-${Date.now()}`,
    user_id: currentUser?.id || null,
    user_name: currentUser?.full_name || 'Há»‡ thá»‘ng',
    action: 'PhĂ¢n cĂ´ng Ä‘á»™i cá»©u há»™',
    table_name: 'rescue_requests',
    record_id: id,
    note: `PhĂ¢n cĂ´ng ${teamName}`,
    created_at: new Date().toISOString()
  };
  db.activityLogs.unshift(log);

  // Add notification for team
  const notif = {
    id: `notif-${Date.now()}`,
    user_id: 'user-rescue-1', // Default lead
    title: 'Nhiá»‡m vá»¥ má»›i!',
    message: `Báº¡n Ä‘Æ°á»£c phĂ¢n cĂ´ng cá»©u há»™ ${request.full_name}`,
    type: 'MISSION_ASSIGNED',
    is_read: false,
    created_at: new Date().toISOString(),
    related_id: mission.id
  };
  db.notifications.unshift(notif);

  saveDb();
  res.json({ success: true, request, mission });
});

// 6. UPDATE MISSION STATUS (and link request status)
app.post('/api/missions/:id/status', requireRoles([...ADMIN_ROLES, ...RESCUE_ROLES]), async (req, res) => {
  const { id } = req.params;
  const { newStatus, extraData, changedByType, note } = pickAllowed(req.body, ['newStatus', 'extraData', 'changedByType', 'note']);
  const changedByUser = req.user;
  if (prisma) {
    const mission = await prisma.rescueMission.findUnique({ where: { id }, include: { request: true } });
    if (!mission) return res.status(404).json({ error: 'Mission not found' });
    const missionStatus = mapMissionStatus(newStatus);
    const requestStatus = missionStatusToRequestStatus(missionStatus, newStatus);
    const updated = await prisma.$transaction(async tx => {
      const updatedMission = await tx.rescueMission.update({
        where: { id },
        data: {
          status: missionStatus,
          latestLatitude: extraData?.current_rescuer_latitude ?? extraData?.latitude ?? undefined,
          latestLongitude: extraData?.current_rescuer_longitude ?? extraData?.longitude ?? undefined,
          completedAt: ['COMPLETED', 'CANCELLED'].includes(missionStatus) ? new Date() : undefined,
          notes: note ?? undefined,
        },
        include: { team: true, request: { include: { area: true } } },
      });
      await tx.missionStatusLog.create({
        data: {
          missionId: id,
          oldStatus: mission.status,
          newStatus: missionStatus,
          changedById: changedByUser?.id || null,
          note: note || `Cáº­p nháº­t tráº¡ng thĂ¡i sang ${requestStatus}`,
          latitude: extraData?.latitude ?? null,
          longitude: extraData?.longitude ?? null,
        },
      });
      await tx.rescueRequest.update({
        where: { id: mission.requestId },
        data: {
          status: requestStatus,
          completedAt: ['RESCUED', 'TRANSFERRED_SAFEZONE', 'CANCELLED'].includes(requestStatus) ? new Date() : undefined,
        },
      });
      return updatedMission;
    });
    return res.json({ success: true, mission: toLegacyMission(updated) });
  }

  const missionIdx = db.rescueMissions.findIndex(m => m.id === id);
  if (missionIdx === -1) return res.status(404).json({ error: 'Mission not found' });

  const mission = db.rescueMissions[missionIdx];
  const oldStatus = mission.status;

  // Update mission
  db.rescueMissions[missionIdx] = { ...mission, status: newStatus, ...sanitizeObject(extraData) };

  // Log status change
  const logEntry = {
    id: `msl-${Date.now()}`,
    mission_id: id,
    old_status: oldStatus,
    new_status: newStatus,
    changed_by_type: changedByType || 'RESCUE_TEAM',
    changed_by_user_id: changedByUser?.id || null,
    note: note || `Cáº­p nháº­t tráº¡ng thĂ¡i sang ${newStatus}`,
    created_at: new Date().toISOString()
  };
  db.missionStatusLogs.push(logEntry);

  // Update request status
  const reqIdx = db.rescueRequests.findIndex(r => r.id === mission.rescue_request_id);
  if (reqIdx !== -1) {
    db.rescueRequests[reqIdx].status = newStatus;
    if (newStatus === 'RESCUED' || newStatus === 'TRANSFERRED_SAFEZONE') {
      db.rescueRequests[reqIdx].completed_at = new Date().toISOString();
    }
  }

  saveDb();
  res.json({ success: true, mission: db.rescueMissions[missionIdx] });
});

// 7. RESCUE TEAMS CRUD
app.post('/api/teams', requireRoles(ADMIN_ROLES), async (req, res) => {
  const data = pickAllowed(req.body, TEAM_FIELDS);
  if (prisma) {
    const team = await prisma.rescueTeam.create({
      data: {
        id: `team-${Date.now()}`,
        projectId: (await getActiveProject()).id,
        areaId: data.area_id || null,
        name: data.team_name || data.name || 'Äá»™i cá»©u há»™',
        phone: data.phone || null,
        leaderId: data.leader_id || data.leader_user_id || null,
        status: data.status || 'AVAILABLE',
        memberCount: Number(data.member_count || data.memberCount || 0),
        latitude: data.latitude ?? null,
        longitude: data.longitude ?? null,
        notes: data.notes || null,
      },
      include: { area: true, leader: true },
    });
    return res.status(201).json(toLegacyTeam(team));
  }
  const team = {
    id: `team-${Date.now()}`,
    ...data,
    created_at: new Date().toISOString()
  };
  db.rescueTeams.push(team);
  saveDb();
  res.status(201).json(team);
});

app.put('/api/teams/:id', requireRoles(ADMIN_ROLES), async (req, res) => {
  const { id } = req.params;
  if (prisma) {
    const data = pickAllowed(req.body, TEAM_FIELDS);
    const existing = await prisma.rescueTeam.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ error: 'Team not found' });
    const team = await prisma.rescueTeam.update({
      where: { id },
      data: {
        areaId: data.area_id ?? undefined,
        name: data.team_name ?? data.name ?? undefined,
        phone: data.phone ?? undefined,
        leaderId: data.leader_id ?? data.leader_user_id ?? undefined,
        status: data.status ?? undefined,
        memberCount: data.member_count === undefined && data.memberCount === undefined ? undefined : Number(data.member_count ?? data.memberCount),
        latitude: data.latitude ?? undefined,
        longitude: data.longitude ?? undefined,
        notes: data.notes ?? undefined,
      },
      include: { area: true, leader: true },
    });
    return res.json(toLegacyTeam(team));
  }
  const idx = db.rescueTeams.findIndex(t => t.id === id);
  if (idx === -1) return res.status(404).json({ error: 'Team not found' });

  db.rescueTeams[idx] = { ...db.rescueTeams[idx], ...pickAllowed(req.body, TEAM_FIELDS) };
  saveDb();
  res.json(db.rescueTeams[idx]);
});

app.delete('/api/teams/:id', requireRoles(ADMIN_ROLES), async (req, res) => {
  const { id } = req.params;
  if (prisma) {
    await prisma.rescueTeam.deleteMany({ where: { id, projectId: (await getActiveProject()).id } });
    return res.json({ success: true });
  }
  db.rescueTeams = db.rescueTeams.filter(t => t.id !== id);
  saveDb();
  res.json({ success: true });
});

// 8. SAFE ZONES CRUD
app.post('/api/safe-zones', requireRoles(ADMIN_ROLES), async (req, res) => {
  const data = pickAllowed(req.body, SAFE_ZONE_FIELDS);
  if (prisma) {
    const zone = await prisma.safeZone.create({
      data: {
        id: `sz-${Date.now()}`,
        projectId: (await getActiveProject()).id,
        areaId: data.area_id || null,
        name: data.name || 'Äiá»ƒm an toĂ n',
        address: data.address || null,
        latitude: data.latitude ?? null,
        longitude: data.longitude ?? null,
        capacity: Number(data.capacity || 0),
        currentPeople: Number(data.current_people || 0),
        contactPerson: data.manager_name || data.contact_person || null,
        contactPhone: data.manager_phone || data.contact_phone || null,
        status: data.status || 'AVAILABLE',
        notes: data.notes || null,
      },
      include: { area: true },
    });
    return res.status(201).json(toLegacySafeZone(zone));
  }
  const textToEmbed = `${data.name || ''} ${data.address || ''} ${data.notes || ''}`;
  const sz = {
    id: `sz-${Date.now()}`,
    ...data,
    vector_embedding: getEmbedding(textToEmbed),
    created_at: new Date().toISOString()
  };
  db.safeZones.push(sz);
  saveDb();
  res.status(201).json(sz);
});

app.put('/api/safe-zones/:id', requireRoles(ADMIN_ROLES), async (req, res) => {
  const { id } = req.params;
  if (prisma) {
    const data = pickAllowed(req.body, SAFE_ZONE_FIELDS);
    const existing = await prisma.safeZone.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ error: 'Safe zone not found' });
    const zone = await prisma.safeZone.update({
      where: { id },
      data: {
        areaId: data.area_id ?? undefined,
        name: data.name ?? undefined,
        address: data.address ?? undefined,
        latitude: data.latitude ?? undefined,
        longitude: data.longitude ?? undefined,
        capacity: data.capacity === undefined ? undefined : Number(data.capacity),
        currentPeople: data.current_people === undefined ? undefined : Number(data.current_people),
        contactPerson: data.manager_name ?? data.contact_person ?? undefined,
        contactPhone: data.manager_phone ?? data.contact_phone ?? undefined,
        status: data.status ?? undefined,
        notes: data.notes ?? undefined,
      },
      include: { area: true },
    });
    return res.json(toLegacySafeZone(zone));
  }
  const idx = db.safeZones.findIndex(s => s.id === id);
  if (idx === -1) return res.status(404).json({ error: 'Safe zone not found' });

  const updated = { ...db.safeZones[idx], ...pickAllowed(req.body, SAFE_ZONE_FIELDS) };
  const textToEmbed = `${updated.name || ''} ${updated.address || ''} ${updated.notes || ''}`;
  updated.vector_embedding = getEmbedding(textToEmbed);

  db.safeZones[idx] = updated;
  saveDb();
  res.json(updated);
});

app.delete('/api/safe-zones/:id', requireRoles(ADMIN_ROLES), async (req, res) => {
  const { id } = req.params;
  if (prisma) {
    await prisma.safeZone.deleteMany({ where: { id, projectId: (await getActiveProject()).id } });
    return res.json({ success: true });
  }
  db.safeZones = db.safeZones.filter(s => s.id !== id);
  saveDb();
  res.json({ success: true });
});

// 9. RESCUE ROUTES CRUD
app.post('/api/routes', requireRoles(ADMIN_ROLES), async (req, res) => {
  const data = pickAllowed(req.body, ROUTE_FIELDS);
  if (prisma) {
    const route = await prisma.rescueRoute.create({
      data: {
        id: `route-${Date.now()}`,
        projectId: (await getActiveProject()).id,
        areaId: data.area_id || null,
        name: data.name || 'Tuyáº¿n cá»©u há»™',
        startPoint: data.from_location || data.start_point || null,
        endPoint: data.to_location || data.end_point || null,
        distanceKm: data.distance_km ?? null,
        status: mapRouteStatus(data.status),
        routeGeo: data.waypoints || null,
        notes: data.notes || null,
      },
      include: { area: true },
    });
    return res.status(201).json(toLegacyRoute(route));
  }
  const route = {
    id: `route-${Date.now()}`,
    ...data,
    created_at: new Date().toISOString()
  };
  db.rescueRoutes.push(route);
  saveDb();
  res.status(201).json(route);
});

app.put('/api/routes/:id', requireRoles(ADMIN_ROLES), async (req, res) => {
  const { id } = req.params;
  if (prisma) {
    const data = pickAllowed(req.body, ROUTE_FIELDS);
    const existing = await prisma.rescueRoute.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ error: 'Route not found' });
    const route = await prisma.rescueRoute.update({
      where: { id },
      data: {
        areaId: data.area_id ?? undefined,
        name: data.name ?? undefined,
        startPoint: data.from_location ?? data.start_point ?? undefined,
        endPoint: data.to_location ?? data.end_point ?? undefined,
        distanceKm: data.distance_km ?? undefined,
        status: data.status ? mapRouteStatus(data.status) : undefined,
        routeGeo: data.waypoints ?? undefined,
        notes: data.notes ?? undefined,
      },
      include: { area: true },
    });
    return res.json(toLegacyRoute(route));
  }
  const idx = db.rescueRoutes.findIndex(r => r.id === id);
  if (idx === -1) return res.status(404).json({ error: 'Route not found' });

  db.rescueRoutes[idx] = { ...db.rescueRoutes[idx], ...pickAllowed(req.body, ROUTE_FIELDS) };
  saveDb();
  res.json(db.rescueRoutes[idx]);
});

app.delete('/api/routes/:id', requireRoles(ADMIN_ROLES), async (req, res) => {
  const { id } = req.params;
  if (prisma) {
    await prisma.rescueRoute.deleteMany({ where: { id, projectId: (await getActiveProject()).id } });
    return res.json({ success: true });
  }
  db.rescueRoutes = db.rescueRoutes.filter(r => r.id !== id);
  saveDb();
  res.json({ success: true });
});

// 10. ACTIVITY LOGS, DAMAGE REPORTS, SMS LOGS & VULNERABLE HOUSEHOLDS
app.post('/api/damage-reports', requireRoles(ADMIN_ROLES), async (req, res) => {
  const data = pickAllowed(req.body, DAMAGE_REPORT_FIELDS);
  if (prisma) {
    const report = await prisma.damageReport.create({
      data: {
        id: `dr-${Date.now()}`,
        projectId: (await getActiveProject()).id,
        areaId: data.area_id || null,
        reporterId: data.reporter_id || null,
        title: `${data.damage_type || 'Thiá»‡t háº¡i'} - ${data.area_name || ''}`.trim(),
        description: data.description || null,
        damageType: data.damage_type || null,
        severity: data.severity || 'MEDIUM',
        status: 'PENDING',
        latitude: data.latitude ?? null,
        longitude: data.longitude ?? null,
        imageUrls: data.images || null,
      },
      include: { area: true },
    });
    return res.status(201).json(toLegacyDamage(report));
  }
  const dr = {
    id: `dr-${Date.now()}`,
    ...data,
    status: 'PENDING',
    created_at: new Date().toISOString()
  };
  db.damageReports.unshift(dr);
  saveDb();
  res.status(201).json(dr);
});

app.post('/api/vulnerable-households', requireRoles(ADMIN_ROLES), async (req, res) => {
  const data = pickAllowed(req.body, VULNERABLE_HOUSEHOLD_FIELDS);
  if (prisma) {
    const household = await prisma.vulnerableHousehold.create({
      data: {
        id: `vh-${Date.now()}`,
        projectId: (await getActiveProject()).id,
        areaId: data.area_id || null,
        householdName: data.full_name || data.head_name || 'Há»™ Æ°u tiĂªn',
        address: data.address_detail || null,
        priorityLevel: data.priority_level || 'MEDIUM',
        peopleCount: Number(data.household_size || 1),
        elderlyCount: Number(data.elderly_count || 0),
        childrenCount: Number(data.children_count || 0),
        disabledCount: Number(data.disabled_count || 0),
        medicalNotes: data.medical_note || null,
        latitude: data.latitude ?? null,
        longitude: data.longitude ?? null,
      },
      include: { area: true },
    });
    return res.status(201).json(toLegacyHousehold(household));
  }
  const vh = {
    id: `vh-${Date.now()}`,
    ...data,
    created_at: new Date().toISOString()
  };
  db.vulnerableHouseholds.push(vh);
  saveDb();
  res.status(201).json(vh);
});

app.put('/api/vulnerable-households/:id', requireRoles(ADMIN_ROLES), async (req, res) => {
  const { id } = req.params;
  if (prisma) {
    const data = pickAllowed(req.body, VULNERABLE_HOUSEHOLD_FIELDS);
    const existing = await prisma.vulnerableHousehold.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ error: 'Vulnerable household not found' });
    const household = await prisma.vulnerableHousehold.update({
      where: { id },
      data: {
        areaId: data.area_id ?? undefined,
        householdName: data.full_name ?? data.head_name ?? undefined,
        address: data.address_detail ?? undefined,
        priorityLevel: data.priority_level ?? undefined,
        peopleCount: data.household_size === undefined ? undefined : Number(data.household_size),
        elderlyCount: data.elderly_count === undefined ? undefined : Number(data.elderly_count),
        childrenCount: data.children_count === undefined ? undefined : Number(data.children_count),
        disabledCount: data.disabled_count === undefined ? undefined : Number(data.disabled_count),
        medicalNotes: data.medical_note ?? undefined,
        latitude: data.latitude ?? undefined,
        longitude: data.longitude ?? undefined,
      },
      include: { area: true },
    });
    return res.json(toLegacyHousehold(household));
  }
  const idx = db.vulnerableHouseholds.findIndex(v => v.id === id);
  if (idx === -1) return res.status(404).json({ error: 'Vulnerable household not found' });

  db.vulnerableHouseholds[idx] = { ...db.vulnerableHouseholds[idx], ...pickAllowed(req.body, VULNERABLE_HOUSEHOLD_FIELDS) };
  saveDb();
  res.json(db.vulnerableHouseholds[idx]);
});

app.post('/api/sms-logs', requireRoles(ADMIN_ROLES), async (req, res) => {
  const data = pickAllowed(req.body, SMS_LOG_FIELDS);
  if (prisma) {
    const log = await prisma.smsLog.create({
      data: {
        id: `sms-${Date.now()}`,
        projectId: (await getActiveProject()).id,
        userId: data.user_id || null,
        alertId: data.flood_warning_id || data.floodAlertId || null,
        recipient: data.recipient || data.phone || '',
        phone: data.phone || '',
        message: data.message || '',
        status: data.status || 'PENDING',
        provider: data.provider || null,
        error: data.error || null,
        sentAt: new Date(),
      },
    });
    return res.status(201).json(toLegacySms(log));
  }
  const log = {
    id: `sms-${Date.now()}`,
    ...data,
    sent_at: new Date().toISOString()
  };
  db.smsLogs.unshift(log);
  saveDb();
  res.status(201).json(log);
});

app.get('/api/notifications/provider-status', requireRoles(ADMIN_ROLES), (req, res) => {
  res.json({
    push: {
      configured: Boolean(process.env.FCM_SERVER_KEY || process.env.GOOGLE_APPLICATION_CREDENTIALS),
      provider: 'firebase-cloud-messaging',
    },
    sms: {
      configured: Boolean(process.env.SMS_API_KEY || process.env.ESMS_API_KEY || process.env.TWILIO_AUTH_TOKEN),
      provider: process.env.SMS_PROVIDER || 'not_configured',
    },
    registeredDeviceTokens: registeredDeviceTokens.size,
    timestamp: new Date().toISOString(),
  });
});

app.post('/api/notifications/device-token', requireAuth, (req, res) => {
  const { token, platform } = pickAllowed(req.body, ['token', 'platform']);
  if (!token || typeof token !== 'string' || token.length < 12) {
    return res.status(400).json({ success: false, message: 'Device token khong hop le' });
  }

  registeredDeviceTokens.set(`${req.user.id}:${token}`, {
    user_id: req.user.id,
    token,
    platform: platform || 'unknown',
    updated_at: new Date().toISOString(),
  });

  res.json({ success: true, persisted: !prisma, registeredDeviceTokens: registeredDeviceTokens.size });
});

app.put('/api/notifications/:id/read', requireAuth, async (req, res) => {
  const { id } = req.params;
  if (prisma) {
    const project = await getActiveProject();
    const notification = await prisma.notification.findFirst({ where: { id, projectId: project.id } });
    if (notification?.userId && notification.userId !== req.user.id && !ADMIN_ROLES.includes(req.user.role)) {
      return res.status(403).json({ error: 'Permission denied' });
    }
    if (notification) {
      await prisma.notification.update({ where: { id }, data: { isRead: true } });
    }
    return res.json({ success: true });
  }
  const idx = db.notifications.findIndex(n => n.id === id);
  if (idx !== -1) {
    const notification = db.notifications[idx];
    if (notification.user_id && notification.user_id !== req.user.id && !ADMIN_ROLES.includes(req.user.role)) {
      return res.status(403).json({ error: 'Permission denied' });
    }
    db.notifications[idx].is_read = true;
    saveDb();
  }
  res.json({ success: true });
});

// Optional static web build hosting. The Flutter mobile app only needs the API routes.
if (fs.existsSync(DIST_DIR)) {
  app.use('/static-assets', express.static(path.join(DIST_DIR, 'static-assets'), {
    index: false,
    maxAge: 0,
    setHeaders(res) {
      res.setHeader('Cache-Control', 'no-store');
    },
  }));

  app.use('/assets', express.static(path.join(DIST_DIR, 'assets'), {
    index: false,
    maxAge: 0,
    setHeaders(res) {
      res.setHeader('Cache-Control', 'no-store');
    },
  }));

  app.use(express.static(DIST_DIR, {
    index: false,
    maxAge: 0,
    setHeaders(res, filePath) {
      if (filePath.endsWith('index.html')) {
        res.setHeader('Cache-Control', 'no-store');
      }
    },
  }));

  app.use('/assets', (req, res) => {
    res.status(404).type('text/plain').send('Asset not found');
  });

  app.use('/static-assets', (req, res) => {
    res.status(404).type('text/plain').send('Static asset not found');
  });

  app.get('*', (req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    res.sendFile(path.join(DIST_DIR, 'index.html'));
  });
} else {
  console.warn('dist directory not found. Run "npm run build" before starting production server.');
}

// Listen to port
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(prisma ? `Database: PostgreSQL relational (${DEFAULT_PROJECT_CODE})` : `Database file: ${DB_FILE}`);
});
