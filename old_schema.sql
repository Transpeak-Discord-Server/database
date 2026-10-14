-- ./reglog.db
CREATE TABLE reglog(id INTEGER PRIMARY KEY AUTOINCREMENT, status TEXT, user TEXT, timestamp TEXT);
-- ./staffwarnings.db
CREATE TABLE staffwarnings(id TEXT, reason TEXT, issuer_id TEXT, timestamp TEXT);
CREATE INDEX staffwarningsindexid on staffwarnings(id);
-- ./lastchance.db
CREATE TABLE lastchance(id TEXT, timestamp TEXT);
-- ./vcwatch.db
CREATE TABLE vcwatch(id TEXT);
CREATE INDEX vcwatchindexid on vcwatch(id);
-- ./message_count.db
CREATE TABLE msgcount(id TEXT, count TEXT, lastmsg TEXT);
CREATE INDEX msgcountindexid on msgcount(id);
-- ./dmreminder.db
CREATE TABLE dmreminders(messageID TEXT, userID TEXT);
-- ./watchlist.db
CREATE TABLE watchlist(id TEXT, desc TEXT);
CREATE INDEX watchlistindexid on watchlist(id);
-- ./mc_registered.db
CREATE TABLE registered(user_id TEXT, mc_name TEXT);
CREATE INDEX registeredindexid on registered(user_id);
-- ./bans.db
CREATE TABLE bans(userid TEXT, banner TEXT, timestamp TEXT, reason TEXT, type INTEGER);
CREATE INDEX userid on bans(userid);
-- ./wallets.db
CREATE TABLE wallets(id TEXT, amount TEXT);
CREATE INDEX walletsindexid on wallets(id);
-- ./warns.db
CREATE TABLE warns(id TEXT, reason TEXT, issuer_id TEXT, timestamp TEXT);
CREATE INDEX warnsindexid on warns(id);
-- ./message_count_week.db
CREATE TABLE msgcount_week(id TEXT, week TEXT, count TEXT);
-- ./glossary.db
CREATE TABLE "glossary" (Word TEXT NULL, Definition TEXT NULL, Aliases TEXT NULL);
CREATE INDEX glossary_index ON glossary(LOWER(Word));
-- ./optinban.db
CREATE TABLE optinban(id TEXT, chan TEXT);
CREATE INDEX optinbanindex on optinban(id);
-- ./vcban.db
CREATE TABLE vcban(id TEXT, reason TEXT, issuer_id TEXT, timestamp TEXT, softban TEXT);
CREATE INDEX vcbanindex on vcban(id);
-- ./not18.db
CREATE TABLE not18(id TEXT);
CREATE INDEX not18indexid on not18(id);
CREATE TABLE notes(id TEXT, msg TEXT);
CREATE INDEX notesindex on notes(id);
-- ./todo.db
CREATE TABLE todo(id INTEGER PRIMARY KEY AUTOINCREMENT, userid TEXT, timestamp TEXT, task TEXT, status INT, priority int default 0);
-- ./vcactivity.db
CREATE TABLE activity(id TEXT, total_time, TEXT);
CREATE INDEX activityindexid on activity(id);
-- ./bios.db
CREATE TABLE bios(name TEXT, user_id TEXT, bio TEXT);
CREATE INDEX biosindexid on bios(user_id);
-- ./help.db
CREATE TABLE "help" (
        `command`       TEXT,
        `category`      TEXT,
        `user`  TEXT,
        `format`        TEXT,
        `desc`  TEXT,
        `level` TEXT
);
-- ./softwarns.db
CREATE TABLE warns(id TEXT, reason TEXT, issuer_id TEXT, timestamp TEXT);
CREATE INDEX warnsindexid on warns(id);
-- ./stars.db
CREATE TABLE stars(id TEXT);
-- ./message_count_week-backup.db
CREATE TABLE msgcount_week(id TEXT, week TEXT, count TEXT);
-- ./online.db
CREATE TABLE online(id TEXT, lastonline TEXT);
CREATE INDEX onlineindexid on online(id);
-- ./sc.db
CREATE TABLE sc(id TEXT, desc TEXT);
CREATE INDEX scindexid on sc(id);
-- ./localization.db
CREATE TABLE timezones(id TEXT, tz TEXT);
CREATE INDEX timezonesid on timezones(id);
-- ./names.db
CREATE TABLE names(id TEXT, name TEXT, timestamp TEXT);
CREATE INDEX namesindexid on names(id);
-- ./regban.db
CREATE TABLE regban(id TEXT);
CREATE INDEX regbanindex on regban(id);
-- ./events.db
CREATE TABLE events(fire_time INTEGER, type TEXT, data TEXT);
CREATE INDEX events_time_index on events(fire_time);
CREATE TABLE bottom_pinned_msgs(channel_id TEXT, message_id TEXT);
-- ./commandlog.db
CREATE TABLE commandlog(id TEXT, timestamp TEXT, command TEXT, commandargs TEXT);
-- ./serverstars.db
CREATE TABLE stars(msgid TEXT, count INT, deleted TEXT, starid TEXT, authorid TEXT);
CREATE INDEX starsindexid ON stars(msgid);
CREATE INDEX scoreindex ON stars(authorid);
-- ./ir.db
CREATE TABLE ir(id TEXT);
-- ./roles.db
CREATE TABLE roles(userid TEXT, roles TEXT);
