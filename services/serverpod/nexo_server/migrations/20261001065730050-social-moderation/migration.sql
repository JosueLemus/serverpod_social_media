BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "content_report" (
    "id" bigserial PRIMARY KEY,
    "targetType" text NOT NULL,
    "targetId" bigint NOT NULL,
    "targetAuthorId" uuid NOT NULL,
    "reporterId" uuid NOT NULL,
    "reason" text NOT NULL,
    "severity" bigint NOT NULL,
    "details" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolvedAt" timestamp without time zone,
    "resolvedBy" uuid,
    "decision" text
);

-- Indexes
CREATE INDEX "content_report_target_idx" ON "content_report" USING btree ("targetType", "targetId");
CREATE INDEX "content_report_open_idx" ON "content_report" USING btree ("resolvedAt", "severity");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "post_comment" (
    "id" bigserial PRIMARY KEY,
    "postId" bigint NOT NULL,
    "authorId" uuid NOT NULL,
    "body" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deletedAt" timestamp without time zone,
    "deletedBy" uuid
);

-- Indexes
CREATE INDEX "post_comment_thread_idx" ON "post_comment" USING btree ("postId", "createdAt", "id");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "post_like" (
    "id" bigserial PRIMARY KEY,
    "postId" bigint NOT NULL,
    "userId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "post_like_user_idx" ON "post_like" USING btree ("postId", "userId");
CREATE INDEX "post_like_recent_idx" ON "post_like" USING btree ("postId", "createdAt");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "post_comment"
    ADD CONSTRAINT "post_comment_fk_0"
    FOREIGN KEY("postId")
    REFERENCES "post"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "post_like"
    ADD CONSTRAINT "post_like_fk_0"
    FOREIGN KEY("postId")
    REFERENCES "post"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR nexo
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('nexo', '20261001065730050-social-moderation', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261001065730050-social-moderation', "timestamp" = now();

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
