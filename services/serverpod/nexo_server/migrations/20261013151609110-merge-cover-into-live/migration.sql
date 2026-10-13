BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "account_profile" ADD COLUMN "coverKey" text;
ALTER TABLE "account_profile" ADD COLUMN "website" text;

--
-- MIGRATION VERSION FOR nexo
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('nexo', '20261013151609110-merge-cover-into-live', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013151609110-merge-cover-into-live', "timestamp" = now();

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
