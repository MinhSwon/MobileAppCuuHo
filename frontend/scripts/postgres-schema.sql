-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "ProjectType" AS ENUM ('MOBILE_APP', 'NATIONAL_WEB', 'PROVINCIAL_WEB', 'PARTNER_PORTAL');

-- CreateEnum
CREATE TYPE "ProjectStatus" AS ENUM ('ACTIVE', 'INACTIVE', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('SUPER_ADMIN', 'ADMIN', 'DISPATCHER', 'RESCUE_LEADER', 'RESCUE_MEMBER', 'CITIZEN');

-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('ACTIVE', 'INACTIVE', 'BLOCKED');

-- CreateEnum
CREATE TYPE "AreaLevel" AS ENUM ('COUNTRY', 'REGION', 'PROVINCE', 'DISTRICT', 'WARD', 'CUSTOM_ZONE');

-- CreateEnum
CREATE TYPE "RiskLevel" AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'EMERGENCY');

-- CreateEnum
CREATE TYPE "EmergencyType" AS ENUM ('MEDICAL', 'FIRE', 'TRAFFIC_ACCIDENT', 'FLOOD', 'LANDSLIDE', 'MISSING_PERSON', 'ISOLATED', 'EVACUATION', 'FOOD_WATER', 'OTHER');

-- CreateEnum
CREATE TYPE "RequestSource" AS ENUM ('MOBILE_APP', 'SOS_PUBLIC', 'HOTLINE', 'ADMIN_CREATED', 'NATIONAL_WEB', 'PROVINCIAL_WEB');

-- CreateEnum
CREATE TYPE "RescueRequestStatus" AS ENUM ('PENDING', 'ASSIGNED', 'ACCEPTED', 'MOVING', 'NEAR_VICTIM', 'ARRIVED_CONFIRMED', 'RESCUING', 'RESCUED', 'TRANSFERRED_SAFEZONE', 'UNREACHABLE', 'NEED_SUPPORT', 'CANCELLED');

-- CreateEnum
CREATE TYPE "TeamStatus" AS ENUM ('AVAILABLE', 'BUSY', 'OFFLINE', 'INACTIVE');

-- CreateEnum
CREATE TYPE "MissionStatus" AS ENUM ('CREATED', 'DISPATCHED', 'ACCEPTED', 'MOVING', 'ARRIVED', 'RESCUING', 'COMPLETED', 'CANCELLED', 'NEED_SUPPORT');

-- CreateEnum
CREATE TYPE "AlertStatus" AS ENUM ('DRAFT', 'PUBLISHED', 'ACTIVE', 'EXPIRED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "DeliveryChannel" AS ENUM ('PUSH', 'SMS', 'EMAIL', 'IN_APP');

-- CreateEnum
CREATE TYPE "DeliveryStatus" AS ENUM ('PENDING', 'SENT', 'DELIVERED', 'FAILED', 'READ');

-- CreateEnum
CREATE TYPE "SafeZoneStatus" AS ENUM ('AVAILABLE', 'FULL', 'CLOSED', 'INACTIVE');

-- CreateEnum
CREATE TYPE "RouteStatus" AS ENUM ('OPEN', 'CAUTION', 'BLOCKED', 'CLOSED');

-- CreateEnum
CREATE TYPE "DamageReportStatus" AS ENUM ('PENDING', 'VERIFIED', 'REJECTED', 'RESOLVED');

-- CreateEnum
CREATE TYPE "AssetStatus" AS ENUM ('AVAILABLE', 'IN_USE', 'MAINTENANCE', 'LOST');

-- CreateTable
CREATE TABLE "app_projects" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" "ProjectType" NOT NULL DEFAULT 'MOBILE_APP',
    "status" "ProjectStatus" NOT NULL DEFAULT 'ACTIVE',
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "app_projects_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "administrative_units" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "parent_id" TEXT,
    "code" TEXT,
    "name" TEXT NOT NULL,
    "level" "AreaLevel" NOT NULL,
    "risk_level" "RiskLevel" NOT NULL DEFAULT 'LOW',
    "latitude" DECIMAL(10,7),
    "longitude" DECIMAL(10,7),
    "boundary_geo" JSONB,
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "administrative_units_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "full_name" TEXT NOT NULL,
    "phone" TEXT,
    "email" TEXT,
    "password_hash" TEXT NOT NULL,
    "role" "UserRole" NOT NULL DEFAULT 'CITIZEN',
    "status" "UserStatus" NOT NULL DEFAULT 'ACTIVE',
    "avatar" TEXT,
    "last_login_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "citizen_profiles" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "area_id" TEXT,
    "address_detail" TEXT,
    "household_size" INTEGER NOT NULL DEFAULT 1,
    "elderly_count" INTEGER NOT NULL DEFAULT 0,
    "children_count" INTEGER NOT NULL DEFAULT 0,
    "disabled_count" INTEGER NOT NULL DEFAULT 0,
    "medical_notes" TEXT,
    "latitude" DECIMAL(10,7),
    "longitude" DECIMAL(10,7),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "citizen_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rescue_teams" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "area_id" TEXT,
    "name" TEXT NOT NULL,
    "phone" TEXT,
    "leader_id" TEXT,
    "status" "TeamStatus" NOT NULL DEFAULT 'AVAILABLE',
    "vehicle_type" TEXT,
    "member_count" INTEGER NOT NULL DEFAULT 0,
    "latitude" DECIMAL(10,7),
    "longitude" DECIMAL(10,7),
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "rescue_teams_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rescue_team_members" (
    "id" TEXT NOT NULL,
    "team_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "position" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "joined_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "rescue_team_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rescue_requests" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "request_code" TEXT,
    "source" "RequestSource" NOT NULL DEFAULT 'MOBILE_APP',
    "emergency_type" "EmergencyType" NOT NULL DEFAULT 'OTHER',
    "emergency_level" "RiskLevel" NOT NULL DEFAULT 'HIGH',
    "status" "RescueRequestStatus" NOT NULL DEFAULT 'PENDING',
    "full_name" TEXT NOT NULL,
    "phone" TEXT,
    "area_id" TEXT,
    "area_name" TEXT,
    "address_detail" TEXT,
    "description" TEXT,
    "number_of_people" INTEGER NOT NULL DEFAULT 1,
    "has_elderly" BOOLEAN NOT NULL DEFAULT false,
    "has_children" BOOLEAN NOT NULL DEFAULT false,
    "has_disabled" BOOLEAN NOT NULL DEFAULT false,
    "has_medical_case" BOOLEAN NOT NULL DEFAULT false,
    "latitude" DECIMAL(10,7),
    "longitude" DECIMAL(10,7),
    "created_by_user_id" TEXT,
    "assigned_user_id" TEXT,
    "assigned_team_id" TEXT,
    "accepted_at" TIMESTAMP(3),
    "completed_at" TIMESTAMP(3),
    "cancelled_at" TIMESTAMP(3),
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "rescue_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "request_status_logs" (
    "id" TEXT NOT NULL,
    "request_id" TEXT NOT NULL,
    "old_status" "RescueRequestStatus",
    "new_status" "RescueRequestStatus" NOT NULL,
    "changed_by_id" TEXT,
    "note" TEXT,
    "extra_data" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "request_status_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rescue_missions" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "request_id" TEXT NOT NULL,
    "team_id" TEXT,
    "status" "MissionStatus" NOT NULL DEFAULT 'CREATED',
    "priority_score" INTEGER NOT NULL DEFAULT 0,
    "started_at" TIMESTAMP(3),
    "completed_at" TIMESTAMP(3),
    "latest_latitude" DECIMAL(10,7),
    "latest_longitude" DECIMAL(10,7),
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "rescue_missions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mission_status_logs" (
    "id" TEXT NOT NULL,
    "mission_id" TEXT NOT NULL,
    "old_status" "MissionStatus",
    "new_status" "MissionStatus" NOT NULL,
    "latitude" DECIMAL(10,7),
    "longitude" DECIMAL(10,7),
    "changed_by_id" TEXT,
    "note" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mission_status_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "alerts" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "area_id" TEXT,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "type" "EmergencyType" NOT NULL DEFAULT 'OTHER',
    "level" "RiskLevel" NOT NULL DEFAULT 'MEDIUM',
    "status" "AlertStatus" NOT NULL DEFAULT 'DRAFT',
    "start_time" TIMESTAMP(3),
    "end_time" TIMESTAMP(3),
    "created_by_id" TEXT,
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "alerts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "alert_deliveries" (
    "id" TEXT NOT NULL,
    "alert_id" TEXT NOT NULL,
    "channel" "DeliveryChannel" NOT NULL,
    "recipient" TEXT NOT NULL,
    "status" "DeliveryStatus" NOT NULL DEFAULT 'PENDING',
    "provider" TEXT,
    "error" TEXT,
    "sent_at" TIMESTAMP(3),
    "delivered_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "alert_deliveries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "safe_zones" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "area_id" TEXT,
    "name" TEXT NOT NULL,
    "address" TEXT,
    "latitude" DECIMAL(10,7),
    "longitude" DECIMAL(10,7),
    "capacity" INTEGER NOT NULL DEFAULT 0,
    "current_people" INTEGER NOT NULL DEFAULT 0,
    "contact_person" TEXT,
    "contact_phone" TEXT,
    "status" "SafeZoneStatus" NOT NULL DEFAULT 'AVAILABLE',
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "safe_zones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rescue_routes" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "area_id" TEXT,
    "name" TEXT NOT NULL,
    "start_point" TEXT,
    "end_point" TEXT,
    "distance_km" DECIMAL(8,2),
    "status" "RouteStatus" NOT NULL DEFAULT 'OPEN',
    "route_geo" JSONB,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "rescue_routes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "damage_reports" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "area_id" TEXT,
    "reporter_id" TEXT,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "damage_type" TEXT,
    "severity" "RiskLevel" NOT NULL DEFAULT 'MEDIUM',
    "status" "DamageReportStatus" NOT NULL DEFAULT 'PENDING',
    "latitude" DECIMAL(10,7),
    "longitude" DECIMAL(10,7),
    "image_urls" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "damage_reports_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vulnerable_households" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "profile_id" TEXT,
    "area_id" TEXT,
    "household_name" TEXT NOT NULL,
    "address" TEXT,
    "priority_level" "RiskLevel" NOT NULL DEFAULT 'MEDIUM',
    "people_count" INTEGER NOT NULL DEFAULT 1,
    "elderly_count" INTEGER NOT NULL DEFAULT 0,
    "children_count" INTEGER NOT NULL DEFAULT 0,
    "disabled_count" INTEGER NOT NULL DEFAULT 0,
    "medical_notes" TEXT,
    "latitude" DECIMAL(10,7),
    "longitude" DECIMAL(10,7),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vulnerable_households_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "user_id" TEXT,
    "request_id" TEXT,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "type" TEXT,
    "is_read" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sms_logs" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "user_id" TEXT,
    "alert_id" TEXT,
    "recipient" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "status" "DeliveryStatus" NOT NULL DEFAULT 'PENDING',
    "provider" TEXT,
    "error" TEXT,
    "sent_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sms_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "activity_logs" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "user_id" TEXT,
    "actor_type" TEXT,
    "action" TEXT NOT NULL,
    "target_type" TEXT,
    "target_id" TEXT,
    "note" TEXT,
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "activity_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "equipment_assets" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "team_id" TEXT,
    "name" TEXT NOT NULL,
    "asset_type" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "status" "AssetStatus" NOT NULL DEFAULT 'AVAILABLE',
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "equipment_assets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "user_id" TEXT,
    "action" TEXT NOT NULL,
    "table_name" TEXT,
    "record_id" TEXT,
    "before" JSONB,
    "after" JSONB,
    "ip_address" TEXT,
    "user_agent" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "app_projects_code_key" ON "app_projects"("code");

-- CreateIndex
CREATE INDEX "administrative_units_project_id_level_idx" ON "administrative_units"("project_id", "level");

-- CreateIndex
CREATE INDEX "administrative_units_parent_id_idx" ON "administrative_units"("parent_id");

-- CreateIndex
CREATE UNIQUE INDEX "administrative_units_project_id_code_key" ON "administrative_units"("project_id", "code");

-- CreateIndex
CREATE INDEX "users_project_id_role_idx" ON "users"("project_id", "role");

-- CreateIndex
CREATE INDEX "users_status_idx" ON "users"("status");

-- CreateIndex
CREATE UNIQUE INDEX "users_project_id_phone_key" ON "users"("project_id", "phone");

-- CreateIndex
CREATE UNIQUE INDEX "users_project_id_email_key" ON "users"("project_id", "email");

-- CreateIndex
CREATE UNIQUE INDEX "citizen_profiles_user_id_key" ON "citizen_profiles"("user_id");

-- CreateIndex
CREATE INDEX "citizen_profiles_project_id_area_id_idx" ON "citizen_profiles"("project_id", "area_id");

-- CreateIndex
CREATE INDEX "rescue_teams_project_id_status_idx" ON "rescue_teams"("project_id", "status");

-- CreateIndex
CREATE INDEX "rescue_teams_area_id_idx" ON "rescue_teams"("area_id");

-- CreateIndex
CREATE INDEX "rescue_team_members_user_id_idx" ON "rescue_team_members"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "rescue_team_members_team_id_user_id_key" ON "rescue_team_members"("team_id", "user_id");

-- CreateIndex
CREATE INDEX "rescue_requests_project_id_status_idx" ON "rescue_requests"("project_id", "status");

-- CreateIndex
CREATE INDEX "rescue_requests_project_id_emergency_type_idx" ON "rescue_requests"("project_id", "emergency_type");

-- CreateIndex
CREATE INDEX "rescue_requests_area_id_idx" ON "rescue_requests"("area_id");

-- CreateIndex
CREATE INDEX "rescue_requests_assigned_team_id_idx" ON "rescue_requests"("assigned_team_id");

-- CreateIndex
CREATE UNIQUE INDEX "rescue_requests_project_id_request_code_key" ON "rescue_requests"("project_id", "request_code");

-- CreateIndex
CREATE INDEX "request_status_logs_request_id_idx" ON "request_status_logs"("request_id");

-- CreateIndex
CREATE UNIQUE INDEX "rescue_missions_request_id_key" ON "rescue_missions"("request_id");

-- CreateIndex
CREATE INDEX "rescue_missions_project_id_status_idx" ON "rescue_missions"("project_id", "status");

-- CreateIndex
CREATE INDEX "rescue_missions_team_id_idx" ON "rescue_missions"("team_id");

-- CreateIndex
CREATE INDEX "mission_status_logs_mission_id_idx" ON "mission_status_logs"("mission_id");

-- CreateIndex
CREATE INDEX "alerts_project_id_status_idx" ON "alerts"("project_id", "status");

-- CreateIndex
CREATE INDEX "alerts_project_id_level_idx" ON "alerts"("project_id", "level");

-- CreateIndex
CREATE INDEX "alerts_area_id_idx" ON "alerts"("area_id");

-- CreateIndex
CREATE INDEX "alert_deliveries_alert_id_channel_idx" ON "alert_deliveries"("alert_id", "channel");

-- CreateIndex
CREATE INDEX "alert_deliveries_status_idx" ON "alert_deliveries"("status");

-- CreateIndex
CREATE INDEX "safe_zones_project_id_status_idx" ON "safe_zones"("project_id", "status");

-- CreateIndex
CREATE INDEX "safe_zones_area_id_idx" ON "safe_zones"("area_id");

-- CreateIndex
CREATE INDEX "rescue_routes_project_id_status_idx" ON "rescue_routes"("project_id", "status");

-- CreateIndex
CREATE INDEX "rescue_routes_area_id_idx" ON "rescue_routes"("area_id");

-- CreateIndex
CREATE INDEX "damage_reports_project_id_status_idx" ON "damage_reports"("project_id", "status");

-- CreateIndex
CREATE INDEX "damage_reports_area_id_idx" ON "damage_reports"("area_id");

-- CreateIndex
CREATE INDEX "vulnerable_households_project_id_priority_level_idx" ON "vulnerable_households"("project_id", "priority_level");

-- CreateIndex
CREATE INDEX "vulnerable_households_area_id_idx" ON "vulnerable_households"("area_id");

-- CreateIndex
CREATE INDEX "notifications_user_id_is_read_idx" ON "notifications"("user_id", "is_read");

-- CreateIndex
CREATE INDEX "notifications_project_id_idx" ON "notifications"("project_id");

-- CreateIndex
CREATE INDEX "sms_logs_project_id_status_idx" ON "sms_logs"("project_id", "status");

-- CreateIndex
CREATE INDEX "sms_logs_phone_idx" ON "sms_logs"("phone");

-- CreateIndex
CREATE INDEX "activity_logs_project_id_created_at_idx" ON "activity_logs"("project_id", "created_at");

-- CreateIndex
CREATE INDEX "activity_logs_target_type_target_id_idx" ON "activity_logs"("target_type", "target_id");

-- CreateIndex
CREATE INDEX "equipment_assets_project_id_asset_type_idx" ON "equipment_assets"("project_id", "asset_type");

-- CreateIndex
CREATE INDEX "equipment_assets_team_id_idx" ON "equipment_assets"("team_id");

-- CreateIndex
CREATE INDEX "audit_logs_project_id_created_at_idx" ON "audit_logs"("project_id", "created_at");

-- CreateIndex
CREATE INDEX "audit_logs_table_name_record_id_idx" ON "audit_logs"("table_name", "record_id");

-- AddForeignKey
ALTER TABLE "administrative_units" ADD CONSTRAINT "administrative_units_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "administrative_units" ADD CONSTRAINT "administrative_units_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "administrative_units"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "citizen_profiles" ADD CONSTRAINT "citizen_profiles_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "citizen_profiles" ADD CONSTRAINT "citizen_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "citizen_profiles" ADD CONSTRAINT "citizen_profiles_area_id_fkey" FOREIGN KEY ("area_id") REFERENCES "administrative_units"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rescue_teams" ADD CONSTRAINT "rescue_teams_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rescue_teams" ADD CONSTRAINT "rescue_teams_area_id_fkey" FOREIGN KEY ("area_id") REFERENCES "administrative_units"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rescue_teams" ADD CONSTRAINT "rescue_teams_leader_id_fkey" FOREIGN KEY ("leader_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rescue_team_members" ADD CONSTRAINT "rescue_team_members_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "rescue_teams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rescue_team_members" ADD CONSTRAINT "rescue_team_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rescue_requests" ADD CONSTRAINT "rescue_requests_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rescue_requests" ADD CONSTRAINT "rescue_requests_area_id_fkey" FOREIGN KEY ("area_id") REFERENCES "administrative_units"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rescue_requests" ADD CONSTRAINT "rescue_requests_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rescue_requests" ADD CONSTRAINT "rescue_requests_assigned_user_id_fkey" FOREIGN KEY ("assigned_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rescue_requests" ADD CONSTRAINT "rescue_requests_assigned_team_id_fkey" FOREIGN KEY ("assigned_team_id") REFERENCES "rescue_teams"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "request_status_logs" ADD CONSTRAINT "request_status_logs_request_id_fkey" FOREIGN KEY ("request_id") REFERENCES "rescue_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rescue_missions" ADD CONSTRAINT "rescue_missions_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rescue_missions" ADD CONSTRAINT "rescue_missions_request_id_fkey" FOREIGN KEY ("request_id") REFERENCES "rescue_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rescue_missions" ADD CONSTRAINT "rescue_missions_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "rescue_teams"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mission_status_logs" ADD CONSTRAINT "mission_status_logs_mission_id_fkey" FOREIGN KEY ("mission_id") REFERENCES "rescue_missions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alerts" ADD CONSTRAINT "alerts_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alerts" ADD CONSTRAINT "alerts_area_id_fkey" FOREIGN KEY ("area_id") REFERENCES "administrative_units"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alerts" ADD CONSTRAINT "alerts_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alert_deliveries" ADD CONSTRAINT "alert_deliveries_alert_id_fkey" FOREIGN KEY ("alert_id") REFERENCES "alerts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "safe_zones" ADD CONSTRAINT "safe_zones_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "safe_zones" ADD CONSTRAINT "safe_zones_area_id_fkey" FOREIGN KEY ("area_id") REFERENCES "administrative_units"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rescue_routes" ADD CONSTRAINT "rescue_routes_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rescue_routes" ADD CONSTRAINT "rescue_routes_area_id_fkey" FOREIGN KEY ("area_id") REFERENCES "administrative_units"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "damage_reports" ADD CONSTRAINT "damage_reports_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "damage_reports" ADD CONSTRAINT "damage_reports_area_id_fkey" FOREIGN KEY ("area_id") REFERENCES "administrative_units"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vulnerable_households" ADD CONSTRAINT "vulnerable_households_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vulnerable_households" ADD CONSTRAINT "vulnerable_households_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "citizen_profiles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vulnerable_households" ADD CONSTRAINT "vulnerable_households_area_id_fkey" FOREIGN KEY ("area_id") REFERENCES "administrative_units"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_request_id_fkey" FOREIGN KEY ("request_id") REFERENCES "rescue_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sms_logs" ADD CONSTRAINT "sms_logs_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sms_logs" ADD CONSTRAINT "sms_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sms_logs" ADD CONSTRAINT "sms_logs_alert_id_fkey" FOREIGN KEY ("alert_id") REFERENCES "alerts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity_logs" ADD CONSTRAINT "activity_logs_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity_logs" ADD CONSTRAINT "activity_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "equipment_assets" ADD CONSTRAINT "equipment_assets_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "equipment_assets" ADD CONSTRAINT "equipment_assets_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "rescue_teams"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "app_projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
