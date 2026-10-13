BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "live_chat_message" ADD COLUMN "deletedAt" timestamp without time zone;
ALTER TABLE "live_chat_message" ADD COLUMN "deletedBy" uuid;
--
-- ACTION CREATE TABLE
--
CREATE TABLE "live_host_ban" (
    "id" bigserial PRIMARY KEY,
    "hostId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    "actorId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "live_host_ban_unique_idx" ON "live_host_ban" USING btree ("hostId", "userId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "live_sanction" (
    "id" bigserial PRIMARY KEY,
    "showId" bigint NOT NULL,
    "targetId" uuid NOT NULL,
    "kind" text NOT NULL,
    "until" timestamp without time zone,
    "actorId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "live_sanction_target_idx" ON "live_sanction" USING btree ("showId", "targetId");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "live_show" ADD COLUMN "pinnedMessageId" bigint;
ALTER TABLE "live_show" ADD COLUMN "highlightedMessageId" bigint;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "live_sanction"
    ADD CONSTRAINT "live_sanction_fk_0"
    FOREIGN KEY("showId")
    REFERENCES "live_show"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR nexo
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('nexo', '20261013024802932-live-moderation', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013024802932-live-moderation', "timestamp" = now();

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
