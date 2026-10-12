BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "live_chat_message" (
    "id" bigserial PRIMARY KEY,
    "showId" bigint NOT NULL,
    "authorId" uuid NOT NULL,
    "body" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "hiddenAt" timestamp without time zone,
    "hiddenBy" uuid
);

-- Indexes
CREATE INDEX "live_chat_message_show_idx" ON "live_chat_message" USING btree ("showId", "id");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "live_show" (
    "id" bigserial PRIMARY KEY,
    "hostId" uuid NOT NULL,
    "title" text NOT NULL,
    "description" text NOT NULL DEFAULT ''::text,
    "startsAt" timestamp without time zone NOT NULL,
    "durationMinutes" bigint NOT NULL DEFAULT 60,
    "access" text NOT NULL,
    "allowQuestions" boolean NOT NULL DEFAULT true,
    "recordReplay" boolean NOT NULL DEFAULT true,
    "status" text NOT NULL,
    "startedAt" timestamp without time zone,
    "endedAt" timestamp without time zone,
    "endedBy" uuid,
    "endedByModeration" boolean NOT NULL DEFAULT false,
    "viewerPeak" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "live_show_status_idx" ON "live_show" USING btree ("status", "startsAt");
CREATE INDEX "live_show_host_idx" ON "live_show" USING btree ("hostId", "startsAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "live_show_guest" (
    "id" bigserial PRIMARY KEY,
    "showId" bigint NOT NULL,
    "userId" uuid NOT NULL,
    "status" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "live_show_guest_unique_idx" ON "live_show_guest" USING btree ("showId", "userId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "live_chat_message"
    ADD CONSTRAINT "live_chat_message_fk_0"
    FOREIGN KEY("showId")
    REFERENCES "live_show"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "live_show_guest"
    ADD CONSTRAINT "live_show_guest_fk_0"
    FOREIGN KEY("showId")
    REFERENCES "live_show"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR nexo
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('nexo', '20261011192614101-live', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261011192614101-live', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260924105404509', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105404509', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
