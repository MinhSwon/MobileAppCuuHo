# RescueVN Flutter Backend

Backend API for the Flutter mobile app. This keeps the current Express, Prisma and PostgreSQL backend so the Flutter app can call the same rescue APIs.

## Run locally

```bash
npm install
npm run db:setup
npm start
```

Health check:

```text
http://localhost:5000/api/health
```

Main API groups:

- `POST /api/auth/login`
- `GET /api/db`
- rescue requests, alerts, safe zones, missions, teams and notifications endpoints in `server.js`

## Environment

Create `.env` from `.env.example` and set:

```text
DATABASE_URL=postgresql://user:password@host:5432/rescuevn_app?schema=public
APP_PROJECT_CODE=RESCUEVN_APP
PGSSL=true
JWT_SECRET=replace-with-a-long-random-secret-at-least-32-characters
CLIENT_ORIGINS=http://localhost,capacitor://localhost,ionic://localhost
```
