BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "live_participant" (
    "id" bigserial PRIMARY KEY,
    "showId" bigint NOT NULL,
    "userId" uuid NOT NULL,
    "role" text NOT NULL,
    "onStage" boolean NOT NULL DEFAULT false,
    "handRaisedAt" timestamp without time zone,
    "micMuted" boolean NOT NULL DEFAULT false,
    "cameraOn" boolean NOT NULL DEFAULT false,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "live_participant_unique_idx" ON "live_participant" USING btree ("showId", "userId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "live_participant"
    ADD CONSTRAINT "live_participant_fk_0"
    FOREIGN KEY("showId")
    REFERENCES "live_show"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR nexo
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('nexo', '20261013023420971-live-stage', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013023420971-live-stage', "timestamp" = now();

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
