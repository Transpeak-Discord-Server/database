-- noinspection SqlResolveForFile @ object-type/"event_type"
-- noinspection SqlResolveForFile @ object-type/"ban_type"
-- noinspection SqlResolveForFile @ object-type/"warn_type"
-- noinspection SqlResolveForFile @ object-type/"user_level"

CREATE SCHEMA IF NOT EXISTS transpeak;

CREATE TABLE IF NOT EXISTS transpeak.user (
    id BIGINT,
    message_count INT NOT NULL DEFAULT 0,
    under_18 BOOL NOT NULL DEFAULT FALSE,
    reg_banned BOOL NOT NULL DEFAULT FALSE,
    bio TEXT,
    last_seen TIMESTAMPTZ,
    last_message TEXT,

    CONSTRAINT user_pk PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS index_user_message_count ON transpeak.user(message_count);

CREATE TABLE IF NOT EXISTS transpeak.watchlist (
    user_id BIGINT,
    description TEXT,

    CONSTRAINT watchlist_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

    CONSTRAINT watchlist_pk PRIMARY KEY (user_id)
);

CREATE TABLE IF NOT EXISTS transpeak.vc_watch (
    user_id BIGINT,
    reason TEXT,

    CONSTRAINT vc_watch_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

    CONSTRAINT vc_watch_pk PRIMARY KEY (user_id)
);

CREATE TABLE IF NOT EXISTS transpeak.special_considerations (
    user_id BIGINT,
    description TEXT,

    CONSTRAINT watchlist_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

    CONSTRAINT special_considerations_pk PRIMARY KEY (user_id)
);

CREATE TABLE IF NOT EXISTS transpeak.names (
    name_occurrence_id INTEGER GENERATED ALWAYS AS IDENTITY,
    user_id BIGINT NOT NULL,
    name TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,

    CONSTRAINT name_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE,

    CONSTRAINT name_pk PRIMARY KEY (name_occurrence_id)
);
CREATE INDEX IF NOT EXISTS index_names_user ON transpeak.names (user_id);

CREATE TABLE IF NOT EXISTS transpeak.user_role (
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,

    CONSTRAINT id_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE,

    CONSTRAINT user_role_pk PRIMARY KEY (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS transpeak.message_count_week (
    user_id BIGINT NOT NULL,
    week BIGINT NOT NULL,
    count INT NOT NULL DEFAULT 0,

    CONSTRAINT count_week_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE,

    CONSTRAINT msg_count_week_pk PRIMARY KEY (user_id, week)
);
CREATE INDEX IF NOT EXISTS index_msg_count_week_week ON transpeak.message_count_week (week);

DO $$ BEGIN
    IF to_regtype('transpeak.warn_type') IS NULL THEN
        CREATE TYPE transpeak.warn_type AS ENUM ('hard', 'soft', 'staff');
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS transpeak.warn (
    warn_id INTEGER GENERATED ALWAYS AS IDENTITY,
    user_id BIGINT NOT NULL,
    reason TEXT NOT NULL,
    issuer_id BIGINT NOT NULL,
    warn_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    warn_type transpeak.warn_type NOT NULL DEFAULT 'hard',

    CONSTRAINT warn_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

    CONSTRAINT warn_issuer_fk FOREIGN KEY (issuer_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

    CONSTRAINT warn_pk PRIMARY KEY (warn_id)
);
CREATE INDEX IF NOT EXISTS index_warn_user ON transpeak.warn (user_id);

DO $$ BEGIN
    IF to_regtype('transpeak.ban_type') IS NULL THEN
        CREATE TYPE transpeak.ban_type AS ENUM ('permanent', 'temporary', 'vc', 'vc_soft');
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS transpeak.ban (
    ban_id INTEGER GENERATED ALWAYS AS IDENTITY,
    user_id BIGINT NOT NULL,
    reason TEXT NOT NULL,
    issuer_id BIGINT NOT NULL,
    ban_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ban_type transpeak.ban_type NOT NULL DEFAULT 'permanent',

    CONSTRAINT ban_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

    CONSTRAINT ban_issuer_fk FOREIGN KEY (issuer_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

    CONSTRAINT ban_pk PRIMARY KEY (ban_id)
);
CREATE INDEX IF NOT EXISTS index_ban_user ON transpeak.ban (user_id);

CREATE TABLE IF NOT EXISTS transpeak.optin_ban (
    user_id BIGINT,
    channel_id BIGINT,

    CONSTRAINT optin_ban_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

    CONSTRAINT optin_ban_pk PRIMARY KEY (user_id, channel_id)
);

CREATE TABLE IF NOT EXISTS transpeak.image_restricted (
    user_id BIGINT NOT NULL,

    CONSTRAINT image_restricted_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user(id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

    CONSTRAINT image_restricted_pk PRIMARY KEY (user_id)
);

DO $$ BEGIN
    IF to_regtype('transpeak.event_type') IS NULL THEN
       CREATE TYPE transpeak.event_type AS ENUM ('reminder', 'staff_reminder', 'temp_ban_expiry');
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS transpeak.event (
    event_id INTEGER GENERATED ALWAYS AS IDENTITY,
    fire_time TIMESTAMPTZ NOT NULL,
    type transpeak.event_type NOT NULL,
    data JSON NOT NULL,

    CONSTRAINT event_pk PRIMARY KEY (event_id)
);
CREATE INDEX IF NOT EXISTS index_event_timestamp ON transpeak.event (fire_time);

CREATE TABLE IF NOT EXISTS transpeak.bottom_pinned_message (
    channel_id BIGINT,
    message_id BIGINT NOT NULL,

    CONSTRAINT bottom_pinned_messages_pk PRIMARY KEY (channel_id)
);

CREATE TABLE IF NOT EXISTS transpeak.dm_reminder (
    user_id BIGINT NOT NULL,
    message_id BIGINT NOT NULL,

    CONSTRAINT dm_reminders_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE,

    CONSTRAINT dm_reminders_pk PRIMARY KEY (user_id, message_id)
);

DO $$ BEGIN
    IF to_regtype('transpeak.user_level') IS NULL THEN
       CREATE TYPE transpeak.user_level AS ENUM ('user', 'helper', 'staff');
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS transpeak.help (
    command TEXT,
    category TEXT,
    format TEXT,
    description TEXT,
    level transpeak.user_level,

    CONSTRAINT help_pk PRIMARY KEY (command)
);

CREATE TABLE IF NOT EXISTS transpeak.glossary (
    word TEXT,
    definition TEXT,

    CONSTRAINT glossary_pk PRIMARY KEY (word)
);
CREATE INDEX IF NOT EXISTS index_glossary_word ON transpeak.glossary(LOWER(word));

CREATE TABLE IF NOT EXISTS transpeak.glossary_aliases (
    word TEXT,
    alias TEXT,

    CONSTRAINT glossary_alias_word_fk FOREIGN KEY (word)
    REFERENCES transpeak.glossary (word) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE,

    CONSTRAINT glossary_alias_pk PRIMARY KEY (word, alias)
);
CREATE INDEX IF NOT EXISTS index_glossary_alias_alias ON transpeak.glossary_aliases(LOWER(alias));
CREATE INDEX IF NOT EXISTS index_glossary_alias_word ON transpeak.glossary_aliases(LOWER(word));

CREATE TABLE IF NOT EXISTS transpeak.stars (
    message_id BIGINT NOT NULL,
    staff_board BOOL NOT NULL DEFAULT FALSE,
    count INT NOT NULL DEFAULT 1,
    deleted BOOL NOT NULL DEFAULT FALSE,
    board_message_id BIGINT DEFAULT NULL,
    author_id BIGINT NOT NULL,

    CONSTRAINT stars_author_id_fk FOREIGN KEY (author_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE,

    CONSTRAINT stars_pk PRIMARY KEY (message_id, staff_board)
);
CREATE INDEX IF NOT EXISTS index_stars_author ON transpeak.stars(author_id);

CREATE TABLE IF NOT EXISTS transpeak.command_log (
    user_id BIGINT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    command TEXT NOT NULL,
    args TEXT,

    CONSTRAINT command_user_id_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE,

    CONSTRAINT command_log_pk PRIMARY KEY (user_id, timestamp)
);

CREATE TABLE IF NOT EXISTS transpeak.registration_status_log (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    status BOOL NOT NULL,
    user_id BIGINT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT reg_log_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

    CONSTRAINT reg_log_pk PRIMARY KEY (id)
);