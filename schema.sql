CREATE SCHEMA IF NOT EXISTS transpeak;

CREATE TABLE IF NOT EXISTS transpeak.user (
    id BIGINT,
    message_count INT NOT NULL DEFAULT 0,
    under_18 BOOL NOT NULL DEFAULT FALSE,
    reg_banned BOOL NOT NULL DEFAULT FALSE,
    bio TEXT,
    watchlist TEXT,
    special_considerations TEXT,
    last_seen TIMESTAMPTZ,

    CONSTRAINT user_pk PRIMARY KEY (id)
);
CREATE INDEX index_user_message_count ON transpeak.user(message_count);

CREATE TABLE IF NOT EXISTS transpeak.user_role (
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,

    CONSTRAINT id_fk FOREIGN KEY (user_id)
    REFERENCES transpeak.user (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE,

    CONSTRAINT user_role_pk PRIMARY KEY (user_id, role_id)
);

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
CREATE INDEX warn_user ON transpeak.warn (user_id);

CREATE TABLE IF NOT EXISTS transpeak.ban (
    ban_id INTEGER GENERATED ALWAYS AS IDENTITY,
    user_id BIGINT NOT NULL,
    reason TEXT NOT NULL,
    issuer_id BIGINT NOT NULL,
    ban_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

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
CREATE INDEX ban_user ON transpeak.ban (user_id);

CREATE TYPE event_type AS ENUM ('reminder', 'staff_reminder', 'temp_ban_expiry');

CREATE TABLE IF NOT EXISTS event (
    event_id INTEGER GENERATED ALWAYS AS IDENTITY,
    fire_time TIMESTAMPTZ NOT NULL,
    type event_type NOT NULL,
    data JSON NOT NULL,

    CONSTRAINT event_pk PRIMARY KEY (event_id)
);
CREATE INDEX event_timestamp ON event (fire_time);