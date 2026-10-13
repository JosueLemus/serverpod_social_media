BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "dm_conversation" (
    "id" bigserial PRIMARY KEY,
    "userA" uuid NOT NULL,
    "userB" uuid NOT NULL,
    "lastReadA" bigint,
    "lastReadB" bigint,
    "lastMessageId" bigint,
    "lastActivityAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "dm_conversation_pair_idx" ON "dm_conversation" USING btree ("userA", "userB");
CREATE INDEX "dm_conversation_a_idx" ON "dm_conversation" USING btree ("userA", "lastActivityAt");
CREATE INDEX "dm_conversation_b_idx" ON "dm_conversation" USING btree ("userB", "lastActivityAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "dm_message" (
    "id" bigserial PRIMARY KEY,
    "conversationId" bigint NOT NULL,
    "authorId" uuid NOT NULL,
    "body" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "dm_message_thread_idx" ON "dm_message" USING btree ("conversationId", "id");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "dm_message"
    ADD CONSTRAINT "dm_message_fk_0"
    FOREIGN KEY("conversationId")
    REFERENCES "dm_conversation"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR nexo
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('nexo', '20261013011028369-messages', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013011028369-messages', "timestamp" = now();

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
