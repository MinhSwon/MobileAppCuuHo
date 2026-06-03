// Express.js Backend with Integrated Semantic Vector Database
// For FLOODGUARD HƯƠNG KHÊ

import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

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
const DATABASE_URL = process.env.DATABASE_URL || '';
const DB_FILE = process.env.DB_FILE ? path.resolve(process.env.DB_FILE) : path.join(__dirname, 'db.json');
const DIST_DIR = path.join(__dirname, 'dist');
const allowedOrigins = (process.env.CLIENT_ORIGINS || '')
  .split(',')
  .map(origin => origin.trim())
  .filter(Boolean);
const { Pool } = pg;
const pool = DATABASE_URL
  ? new Pool({
      connectionString: DATABASE_URL,
      ssl: process.env.PGSSL === 'true' ? { rejectUnauthorized: false } : false
    })
  : null;
let writeQueue = Promise.resolve();

app.disable('x-powered-by');
app.set('trust proxy', 1);

app.use(cors({
  origin(origin, callback) {
    if (!origin || allowedOrigins.length === 0 || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(new Error(`Origin ${origin} is not allowed by CORS`));
  },
}));
app.use(express.json({ limit: '1mb' }));

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

async function initializePostgres() {
  if (!pool) return false;

  await pool.query(`
    CREATE TABLE IF NOT EXISTS app_state (
      collection TEXT PRIMARY KEY,
      data JSONB NOT NULL,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);

  for (const collection of COLLECTION_NAMES) {
    await pool.query(
      `INSERT INTO app_state (collection, data)
       VALUES ($1, $2::jsonb)
       ON CONFLICT (collection) DO NOTHING`,
      [collection, JSON.stringify(db[collection])]
    );
  }

  const result = await pool.query('SELECT collection, data FROM app_state');
  for (const row of result.rows) {
    if (COLLECTION_NAMES.includes(row.collection)) {
      db[row.collection] = row.data;
    }
  }

  console.log('Database loaded from PostgreSQL');
  return true;
}

// Helper function to save DB to file
function saveDb() {
  if (pool) {
    writeQueue = writeQueue
      .then(async () => {
        const client = await pool.connect();
        try {
          await client.query('BEGIN');
          for (const collection of COLLECTION_NAMES) {
            await client.query(
              `INSERT INTO app_state (collection, data, updated_at)
               VALUES ($1, $2::jsonb, NOW())
               ON CONFLICT (collection)
               DO UPDATE SET data = EXCLUDED.data, updated_at = NOW()`,
              [collection, JSON.stringify(db[collection])]
            );
          }
          await client.query('COMMIT');
        } catch (err) {
          await client.query('ROLLBACK');
          console.error('Failed to write PostgreSQL app_state:', err);
        } finally {
          client.release();
        }
      })
      .catch(err => {
        console.error('PostgreSQL write queue failed:', err);
      });
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

// ---------------------- API ROUTES ----------------------

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    uptime: process.uptime(),
    database: pool ? 'postgresql' : 'json-file',
    dbFile: pool ? null : DB_FILE,
    timestamp: new Date().toISOString()
  });
});

// 1. GET ALL DATABASE STATE (Sync on page load)
app.get('/api/db', (req, res) => {
  res.json(db);
});

// 2. AUTH LOGIN
app.post('/api/auth/login', (req, res) => {
  const { emailOrPhone, password } = req.body;
  const user = db.users.find(
    u => (u.email === emailOrPhone || u.phone === emailOrPhone) && u.password_hash === password
  );
  if (!user) {
    return res.status(401).json({ success: false, message: 'Sai tài khoản hoặc mật khẩu' });
  }
  const profile = db.citizenProfiles.find(p => p.user_id === user.id);
  res.json({ success: true, user, profile: profile || null });
});

// 3. SEMANTIC VECTOR SEARCH
app.get('/api/search', (req, res) => {
  const { q, type } = req.query;
  if (!q) {
    return res.status(400).json({ error: 'Query parameter "q" is required' });
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
app.post('/api/warnings', (req, res) => {
  const data = req.body;
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

app.put('/api/warnings/:id', (req, res) => {
  const { id } = req.params;
  const idx = db.floodWarnings.findIndex(w => w.id === id);
  if (idx === -1) return res.status(404).json({ error: 'Warning not found' });

  const updatedData = { ...db.floodWarnings[idx], ...req.body, updated_at: new Date().toISOString() };
  const textToEmbed = `${updatedData.title || ''} ${updatedData.content || ''} ${updatedData.area_name || ''}`;
  updatedData.vector_embedding = getEmbedding(textToEmbed);

  db.floodWarnings[idx] = updatedData;
  saveDb();
  res.json(updatedData);
});

app.delete('/api/warnings/:id', (req, res) => {
  const { id } = req.params;
  db.floodWarnings = db.floodWarnings.filter(w => w.id !== id);
  saveDb();
  res.json({ success: true });
});

// 5. RESCUE REQUESTS & MISSIONS
app.post('/api/rescue-requests', (req, res) => {
  const data = req.body;
  const textToEmbed = `${data.full_name || ''} ${data.address_detail || ''} ${data.note || ''}`;
  const request = {
    id: `rr-${Date.now()}`,
    ...data,
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

app.put('/api/rescue-requests/:id', (req, res) => {
  const { id } = req.params;
  const idx = db.rescueRequests.findIndex(r => r.id === id);
  if (idx === -1) return res.status(404).json({ error: 'Request not found' });

  db.rescueRequests[idx] = { ...db.rescueRequests[idx], ...req.body };
  saveDb();
  res.json(db.rescueRequests[idx]);
});

app.post('/api/rescue-requests/:id/assign', (req, res) => {
  const { id } = req.params;
  const { teamId, teamName, currentUser } = req.body;
  
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
    user_name: currentUser?.full_name || 'Hệ thống',
    action: 'Phân công đội cứu hộ',
    table_name: 'rescue_requests',
    record_id: id,
    note: `Phân công ${teamName}`,
    created_at: new Date().toISOString()
  };
  db.activityLogs.unshift(log);

  // Add notification for team
  const notif = {
    id: `notif-${Date.now()}`,
    user_id: 'user-rescue-1', // Default lead
    title: 'Nhiệm vụ mới!',
    message: `Bạn được phân công cứu hộ ${request.full_name}`,
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
app.post('/api/missions/:id/status', (req, res) => {
  const { id } = req.params;
  const { newStatus, extraData, changedByType, changedByUser, note } = req.body;

  const missionIdx = db.rescueMissions.findIndex(m => m.id === id);
  if (missionIdx === -1) return res.status(404).json({ error: 'Mission not found' });

  const mission = db.rescueMissions[missionIdx];
  const oldStatus = mission.status;

  // Update mission
  db.rescueMissions[missionIdx] = { ...mission, status: newStatus, ...extraData };

  // Log status change
  const logEntry = {
    id: `msl-${Date.now()}`,
    mission_id: id,
    old_status: oldStatus,
    new_status: newStatus,
    changed_by_type: changedByType || 'RESCUE_TEAM',
    changed_by_user_id: changedByUser?.id || null,
    note: note || `Cập nhật trạng thái sang ${newStatus}`,
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
app.post('/api/teams', (req, res) => {
  const team = {
    id: `team-${Date.now()}`,
    ...req.body,
    created_at: new Date().toISOString()
  };
  db.rescueTeams.push(team);
  saveDb();
  res.status(201).json(team);
});

app.put('/api/teams/:id', (req, res) => {
  const { id } = req.params;
  const idx = db.rescueTeams.findIndex(t => t.id === id);
  if (idx === -1) return res.status(404).json({ error: 'Team not found' });

  db.rescueTeams[idx] = { ...db.rescueTeams[idx], ...req.body };
  saveDb();
  res.json(db.rescueTeams[idx]);
});

app.delete('/api/teams/:id', (req, res) => {
  const { id } = req.params;
  db.rescueTeams = db.rescueTeams.filter(t => t.id !== id);
  saveDb();
  res.json({ success: true });
});

// 8. SAFE ZONES CRUD
app.post('/api/safe-zones', (req, res) => {
  const data = req.body;
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

app.put('/api/safe-zones/:id', (req, res) => {
  const { id } = req.params;
  const idx = db.safeZones.findIndex(s => s.id === id);
  if (idx === -1) return res.status(404).json({ error: 'Safe zone not found' });

  const updated = { ...db.safeZones[idx], ...req.body };
  const textToEmbed = `${updated.name || ''} ${updated.address || ''} ${updated.notes || ''}`;
  updated.vector_embedding = getEmbedding(textToEmbed);

  db.safeZones[idx] = updated;
  saveDb();
  res.json(updated);
});

app.delete('/api/safe-zones/:id', (req, res) => {
  const { id } = req.params;
  db.safeZones = db.safeZones.filter(s => s.id !== id);
  saveDb();
  res.json({ success: true });
});

// 9. RESCUE ROUTES CRUD
app.post('/api/routes', (req, res) => {
  const route = {
    id: `route-${Date.now()}`,
    ...req.body,
    created_at: new Date().toISOString()
  };
  db.rescueRoutes.push(route);
  saveDb();
  res.status(201).json(route);
});

app.put('/api/routes/:id', (req, res) => {
  const { id } = req.params;
  const idx = db.rescueRoutes.findIndex(r => r.id === id);
  if (idx === -1) return res.status(404).json({ error: 'Route not found' });

  db.rescueRoutes[idx] = { ...db.rescueRoutes[idx], ...req.body };
  saveDb();
  res.json(db.rescueRoutes[idx]);
});

app.delete('/api/routes/:id', (req, res) => {
  const { id } = req.params;
  db.rescueRoutes = db.rescueRoutes.filter(r => r.id !== id);
  saveDb();
  res.json({ success: true });
});

// 10. ACTIVITY LOGS, DAMAGE REPORTS, SMS LOGS & VULNERABLE HOUSEHOLDS
app.post('/api/damage-reports', (req, res) => {
  const dr = {
    id: `dr-${Date.now()}`,
    ...req.body,
    status: 'PENDING',
    created_at: new Date().toISOString()
  };
  db.damageReports.unshift(dr);
  saveDb();
  res.status(201).json(dr);
});

app.post('/api/vulnerable-households', (req, res) => {
  const vh = {
    id: `vh-${Date.now()}`,
    ...req.body,
    created_at: new Date().toISOString()
  };
  db.vulnerableHouseholds.push(vh);
  saveDb();
  res.status(201).json(vh);
});

app.put('/api/vulnerable-households/:id', (req, res) => {
  const { id } = req.params;
  const idx = db.vulnerableHouseholds.findIndex(v => v.id === id);
  if (idx === -1) return res.status(404).json({ error: 'Vulnerable household not found' });

  db.vulnerableHouseholds[idx] = { ...db.vulnerableHouseholds[idx], ...req.body };
  saveDb();
  res.json(db.vulnerableHouseholds[idx]);
});

app.post('/api/sms-logs', (req, res) => {
  const log = {
    id: `sms-${Date.now()}`,
    ...req.body,
    sent_at: new Date().toISOString()
  };
  db.smsLogs.unshift(log);
  saveDb();
  res.status(201).json(log);
});

app.put('/api/notifications/:id/read', (req, res) => {
  const { id } = req.params;
  const idx = db.notifications.findIndex(n => n.id === id);
  if (idx !== -1) {
    db.notifications[idx].is_read = true;
    saveDb();
  }
  res.json({ success: true });
});

// Serve the production React build from the same domain as the API.
if (fs.existsSync(DIST_DIR)) {
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
  console.log(pool ? 'Database: PostgreSQL' : `Database file: ${DB_FILE}`);
});
