BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "investigation" (
    "id" bigserial PRIMARY KEY,
    "title" text NOT NULL,
    "notes" text,
    "eventIds" json NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "watch_zone" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "latitude" double precision NOT NULL,
    "longitude" double precision NOT NULL,
    "radiusKm" double precision NOT NULL,
    "trackedTypes" json NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "world_event" (
    "id" bigserial PRIMARY KEY,
    "externalId" text NOT NULL,
    "type" text NOT NULL,
    "title" text NOT NULL,
    "description" text,
    "latitude" double precision NOT NULL,
    "longitude" double precision NOT NULL,
    "altitude" double precision,
    "timestamp" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "source" text NOT NULL,
    "sourceUrl" text,
    "severity" double precision NOT NULL,
    "confidence" double precision,
    "country" text,
    "region" text,
    "city" text,
    "rawMetadata" text
);

-- Indexes
CREATE INDEX "external_id_idx" ON "world_event" USING btree ("externalId");
CREATE INDEX "type_idx" ON "world_event" USING btree ("type");


--
-- MIGRATION VERSION FOR worldos_system
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('worldos_system', '20261014120716141', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261014120716141', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();


COMMIT;
