BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_notification" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
    "kind" text NOT NULL,
    "actorId" uuid,
    "postId" bigint,
    "showId" bigint,
    "readAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "user_notification_feed_idx" ON "user_notification" USING btree ("userId", "createdAt");
CREATE INDEX "user_notification_unread_idx" ON "user_notification" USING btree ("userId", "readAt");


--
-- MIGRATION VERSION FOR nexo
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('nexo', '20261011205900478-notifications', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261011205900478-notifications', "timestamp" = now();

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
