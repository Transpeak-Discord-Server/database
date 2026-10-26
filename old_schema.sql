-- ./reglog.db - done
CREATE TABLE reglog(id INTEGER PRIMARY KEY AUTOINCREMENT, status TEXT, user TEXT, timestamp TEXT);
-- ./staffwarnings.db - done
CREATE TABLE staffwarnings(id TEXT, reason TEXT, issuer_id TEXT, timestamp TEXT);
CREATE INDEX staffwarningsindexid on staffwarnings(id);
-- ./lastchance.db - unused
CREATE TABLE lastchance(id TEXT, timestamp TEXT);
-- ./vcwatch.db - done
CREATE TABLE vcwatch(id TEXT);
CREATE INDEX vcwatchindexid on vcwatch(id);
-- ./message_count.db - done
CREATE TABLE msgcount(id TEXT, count TEXT, lastmsg TEXT);
CREATE INDEX msgcountindexid on msgcount(id);
-- ./dmreminder.db - done
CREATE TABLE dmreminders(messageID TEXT, userID TEXT);
-- ./watchlist.db - done
CREATE TABLE watchlist(id TEXT, desc TEXT);
CREATE INDEX watchlistindexid on watchlist(id);
-- ./mc_registered.db - unused
CREATE TABLE registered(user_id TEXT, mc_name TEXT);
CREATE INDEX registeredindexid on registered(user_id);
-- ./bans.db - done
CREATE TABLE bans(userid TEXT, banner TEXT, timestamp TEXT, reason TEXT, type INTEGER);
CREATE INDEX userid on bans(userid);
-- ./wallets.db - unused
CREATE TABLE wallets(id TEXT, amount TEXT);
CREATE INDEX walletsindexid on wallets(id);
-- ./warns.db - done
CREATE TABLE warns(id TEXT, reason TEXT, issuer_id TEXT, timestamp TEXT);
CREATE INDEX warnsindexid on warns(id);
-- ./message_count_week.db - done
CREATE TABLE msgcount_week(id TEXT, week TEXT, count TEXT);
-- ./glossary.db - done
CREATE TABLE "glossary" (Word TEXT NULL, Definition TEXT NULL, Aliases TEXT NULL);
CREATE INDEX glossary_index ON glossary(LOWER(Word));
-- ./optinban.db - done
CREATE TABLE optinban(id TEXT, chan TEXT);
CREATE INDEX optinbanindex on optinban(id);
-- ./vcban.db - done
CREATE TABLE vcban(id TEXT, reason TEXT, issuer_id TEXT, timestamp TEXT, softban TEXT);
CREATE INDEX vcbanindex on vcban(id);
-- ./not18.db - done
CREATE TABLE not18(id TEXT);
CREATE INDEX not18indexid on not18(id);
CREATE TABLE notes(id TEXT, msg TEXT);
CREATE INDEX notesindex on notes(id);
-- ./todo.db - unused
CREATE TABLE todo(id INTEGER PRIMARY KEY AUTOINCREMENT, userid TEXT, timestamp TEXT, task TEXT, status INT, priority int default 0);
-- ./vcactivity.db - unused
CREATE TABLE activity(id TEXT, total_time, TEXT);
CREATE INDEX activityindexid on activity(id);
-- ./bios.db - done
CREATE TABLE bios(name TEXT, user_id TEXT, bio TEXT);
CREATE INDEX biosindexid on bios(user_id);
-- ./help.db - done
CREATE TABLE "help" (
        `command`       TEXT,
        `category`      TEXT,
        `user`  TEXT,
        `format`        TEXT,
        `desc`  TEXT,
        `level` TEXT
);
-- ./softwarns.db - done
CREATE TABLE warns(id TEXT, reason TEXT, issuer_id TEXT, timestamp TEXT);
CREATE INDEX warnsindexid on warns(id);
-- ./stars.db - done
CREATE TABLE stars(id TEXT);
-- ./message_count_week-backup.db - unused
CREATE TABLE msgcount_week(id TEXT, week TEXT, count TEXT);
-- ./online.db - done
CREATE TABLE online(id TEXT, lastonline TEXT);
CREATE INDEX onlineindexid on online(id);
-- ./sc.db - done
CREATE TABLE sc(id TEXT, desc TEXT);
CREATE INDEX scindexid on sc(id);
-- ./localization.db - unused
CREATE TABLE timezones(id TEXT, tz TEXT);
CREATE INDEX timezonesid on timezones(id);
-- ./names.db - done
CREATE TABLE names(id TEXT, name TEXT, timestamp TEXT);
CREATE INDEX namesindexid on names(id);
-- ./regban.db - done
CREATE TABLE regban(id TEXT);
CREATE INDEX regbanindex on regban(id);
-- ./events.db - done
CREATE TABLE events(fire_time INTEGER, type TEXT, data TEXT);
CREATE INDEX events_time_index on events(fire_time);
CREATE TABLE bottom_pinned_msgs(channel_id TEXT, message_id TEXT);
-- ./commandlog.db - done
CREATE TABLE commandlog(id TEXT, timestamp TEXT, command TEXT, commandargs TEXT);
-- ./serverstars.db - done
CREATE TABLE stars(msgid TEXT, count INT, deleted TEXT, starid TEXT, authorid TEXT);
CREATE INDEX starsindexid ON stars(msgid);
CREATE INDEX scoreindex ON stars(authorid);
-- ./ir.db - done
CREATE TABLE ir(id TEXT);
-- ./roles.db - done
CREATE TABLE roles(userid TEXT, roles TEXT);
