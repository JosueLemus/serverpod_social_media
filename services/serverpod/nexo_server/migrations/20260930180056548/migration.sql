BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "post" (
    "id" bigserial PRIMARY KEY,
    "authorId" uuid NOT NULL,
    "body" text NOT NULL,
    "tags" json NOT NULL,
    "visibility" text NOT NULL,
    "allowComments" boolean NOT NULL DEFAULT true,
    "likeCount" bigint NOT NULL DEFAULT 0,
    "commentCount" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "editedAt" timestamp without time zone,
    "deletedAt" timestamp without time zone,
    "deletedBy" uuid
);

-- Indexes
CREATE INDEX "post_feed_idx" ON "post" USING btree ("createdAt", "id");
CREATE INDEX "post_author_idx" ON "post" USING btree ("authorId", "createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "post_media" (
    "id" bigserial PRIMARY KEY,
    "postId" bigint NOT NULL,
    "kind" text NOT NULL,
    "storageKey" text NOT NULL,
    "contentType" text NOT NULL,
    "position" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "post_media_storage_key_idx" ON "post_media" USING btree ("storageKey");
CREATE INDEX "post_media_post_idx" ON "post_media" USING btree ("postId", "position");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "post_media"
    ADD CONSTRAINT "post_media_fk_0"
    FOREIGN KEY("postId")
    REFERENCES "post"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR nexo
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('nexo', '20260930180056548', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260930180056548', "timestamp" = now();

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
