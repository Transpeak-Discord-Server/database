ALTER TABLE transpeak.optin_ban ALTER COLUMN channel_id TYPE TEXT;
ALTER TABLE transpeak.optin_ban RENAME COLUMN channel_id TO channel_name;