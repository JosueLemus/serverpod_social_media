BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "account_profile" ADD COLUMN "followerCount" bigint NOT NULL DEFAULT 0;
ALTER TABLE "account_profile" ADD COLUMN "followingCount" bigint NOT NULL DEFAULT 0;
--
-- ACTION CREATE TABLE
--
CREATE TABLE "follow" (
    "id" bigserial PRIMARY KEY,
    "followerId" uuid NOT NULL,
    "followeeId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "follow_pair_idx" ON "follow" USING btree ("followerId", "followeeId");
CREATE INDEX "follow_followee_idx" ON "follow" USING btree ("followeeId", "createdAt");
CREATE INDEX "follow_follower_idx" ON "follow" USING btree ("followerId", "createdAt");


--
-- MIGRATION VERSION FOR nexo
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('nexo', '20261011205231471-follows', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261011205231471-follows', "timestamp" = now();

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
