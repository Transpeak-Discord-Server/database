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
CREATE INDEX IF NOT EXISTS transpeak.index_user_id ON transpeak.user (id);
CREATE INDEX IF NOT EXISTS transpeak.index_user_message_count ON transpeak.user(message_count);

CREATE TABLE IF NOT EXISTS transpeak.watchlist (
    user_id BIGINT,
    description TEXT,

    CONSTRAINT watchlist_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,

    CONSTRAINT watchlist_pk PRIMARY KEY (user_id)
);
CREATE INDEX IF NOT EXISTS transpeak.index_watchlist_user ON transpeak.watchlist(user_id);

CREATE TABLE IF NOT EXISTS transpeak.special_considerations (
    user_id BIGINT,
    description TEXT,

    CONSTRAINT watchlist_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,

    CONSTRAINT special_considerations_pk PRIMARY KEY (user_id)
);

CREATE TABLE IF NOT EXISTS transpeak.names (
    user_id BIGINT,
    name TEXT,
    timestamp TIMESTAMPTZ,

    CONSTRAINT name_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS index_names_user ON transpeak.names (user_id);

CREATE TABLE IF NOT EXISTS transpeak.user_role (
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,

    CONSTRAINT id_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE,

    CONSTRAINT user_role_pk PRIMARY KEY (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS transpeak.message_count_week (
    user_id BIGINT NOT NULL,
    week BIGINT NOT NULL,
    count INT NOT NULL DEFAULT 0,

    CONSTRAINT count_week_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE,

    CONSTRAINT msg_count_week_pk PRIMARY KEY (user_id, week)
);
CREATE INDEX IF NOT EXISTS transpeak.index_msg_count_week_user ON transpeak.message_count_week (user_id);
CREATE INDEX IF NOT EXISTS transpeak.index_msg_count_week_week ON transpeak.message_count_week (week);

CREATE TABLE IF NOT EXISTS transpeak.warn (
    warn_id INTEGER GENERATED ALWAYS AS IDENTITY,
    user_id BIGINT NOT NULL,
    reason TEXT NOT NULL,
    issuer_id BIGINT NOT NULL,
    warn_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT warn_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,

    CONSTRAINT warn_issuer_fk FOREIGN KEY (issuer_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,

    CONSTRAINT warn_pk PRIMARY KEY (warn_id)
);
CREATE INDEX IF NOT EXISTS transpeak.index_warn_user ON transpeak.warn (user_id);

CREATE TABLE IF NOT EXISTS transpeak.staff_warn (
    warn_id INTEGER GENERATED ALWAYS AS IDENTITY,
    user_id BIGINT NOT NULL,
    reason TEXT NOT NULL,
    issuer_id BIGINT NOT NULL,
    warn_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT staff_warn_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,

    CONSTRAINT staff_warn_issuer_fk FOREIGN KEY (issuer_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,

    CONSTRAINT staff_warn_pk PRIMARY KEY (warn_id)
);
CREATE INDEX IF NOT EXISTS transpeak.index_staff_warn_user ON transpeak.staff_warn (user_id);

CREATE TYPE transpeak.ban_type AS ENUM ('permanent', 'temporary');

CREATE TABLE IF NOT EXISTS transpeak.ban (
    ban_id INTEGER GENERATED ALWAYS AS IDENTITY,
    user_id BIGINT NOT NULL,
    reason TEXT NOT NULL,
    issuer_id BIGINT NOT NULL,
    ban_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ban_type ban_type NOT NULL DEFAULT 'permanent',

    CONSTRAINT ban_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,

    CONSTRAINT ban_issuer_fk FOREIGN KEY (issuer_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,

    CONSTRAINT ban_pk PRIMARY KEY (ban_id)
);
CREATE INDEX IF NOT EXISTS transpeak.index_ban_user ON transpeak.ban (user_id);

CREATE TABLE IF NOT EXISTS transpeak.optin_ban (
    user_id BIGINT,
    channel_id BIGINT,

    CONSTRAINT optin_ban_pk PRIMARY KEY (user_id, channel_id)
);
CREATE INDEX IF NOT EXISTS transpeak.index_optin_ban_user ON transpeak.optin_ban (user_id);

CREATE TYPE transpeak.event_type AS ENUM ('reminder', 'staff_reminder', 'temp_ban_expiry');

CREATE TABLE IF NOT EXISTS transpeak.event (
    event_id INTEGER GENERATED ALWAYS AS IDENTITY,
    fire_time TIMESTAMPTZ NOT NULL,
    type event_type NOT NULL,
    data JSON NOT NULL,

    CONSTRAINT event_pk PRIMARY KEY (event_id)
);
CREATE INDEX IF NOT EXISTS transpeak.index_event_timestamp ON transpeak.event (fire_time);

CREATE TABLE IF NOT EXISTS transpeak.bottom_pinned_messages (
    channel_id BIGINT,
    message_id BIGINT NOT NULL,

    CONSTRAINT bottom_pinned_messages_pk PRIMARY KEY (channel_id)
);
CREATE INDEX IF NOT EXISTS transpeak.index_bottom_pinned_messages_channel ON transpeak.bottom_pinned_messages (channel_id);

CREATE TABLE IF NOT EXISTS transpeak.dm_reminders (
    user_id INTEGER NOT NULL,
    message_id INTEGER NOT NULL,

    CONSTRAINT dm_reminders_user_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE,

    CONSTRAINT dm_reminders_pk PRIMARY KEY (user_id, message_id)
);
CREATE INDEX IF NOT EXISTS transpeak.index_dm_reminders_user ON transpeak.dm_reminders (user_id);

CREATE TABLE IF NOT EXISTS transpeak.help (
    command TEXT,
    category TEXT,
    "user" TEXT,
    format TEXT,
    description TEXT,
    level TEXT,

    CONSTRAINT help_pk PRIMARY KEY (command)
);
CREATE INDEX IF NOT EXISTS transpeak.index_help_command ON transpeak.help (command);

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