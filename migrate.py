import asyncio
import dataclasses
import datetime
import os
from _typeshed import SupportsLenAndGetItem
from enum import Enum
from pathlib import Path
# noinspection protected-member
from typing import Literal, Sequence, Mapping, Any, LiteralString, List
from typing_extensions import Buffer

import psycopg
import sqlite3

from psycopg import AsyncConnection
from psycopg.sql import SQL, Composed

from types import TracebackType


### DB stuff

class SQLite:

    db_files_path: Path

    def __init__(self):
        db_files_path_env = os.getenv("SQLITE_PATH")
        if db_files_path_env is None:
            print("ERROR: could not find env var SQLITE_PATH")
            exit(1)
        self.db_files_path = Path(db_files_path_env)

    def fetchone(self, db_file: Path | str, query: str, params: SupportsLenAndGetItem[str | Buffer | int | float | None | Any] | Mapping[str, str | Buffer | int | float | None | Any] = ()) -> Any:
        connection = sqlite3.connect(self.db_files_path / db_file)
        cursor = connection.cursor()
        cursor.execute(query, params)
        return cursor.fetchone()

    def fetchall(self, db_file: Path | str, query: str, params: SupportsLenAndGetItem[str | Buffer | int | float | None | Any] | Mapping[str, str | Buffer | int | float | None | Any] = ()) -> List[Any]:
        connection = sqlite3.connect(self.db_files_path / db_file)
        cursor = connection.cursor()
        cursor.execute(query, params)
        return cursor.fetchall()

class Postgres:

    postgres_url: str
    connection: AsyncConnection[tuple[Any, ...]]

    def __init__(self):
        postgres_url = os.getenv("POSTGRES_URL")
        if postgres_url is None:
            print("ERROR: could not find env var POSTGRES_URL")
            exit(1)
        self.postgres_url = postgres_url

    async def init(self) -> Postgres:
        self.connection = await psycopg.AsyncConnection.connect(self.postgres_url)
        return self

    async def fetchone(self, query: LiteralString | SQL | bytes | Composed, params: Mapping[str, Any] | Sequence[Any] | None = None) -> tuple[Any, ...] | None:
        async with self.connection.cursor() as cursor:
            await cursor.execute(query, params)
            output = await cursor.fetchone()
        await self.connection.commit()
        return output

    async def fetchall(self, query: LiteralString | SQL | bytes | Composed, params: Mapping[str, Any] | Sequence[Any] | None = None) -> List[tuple[Any, ...]]:
        async with self.connection.cursor() as cursor:
            await cursor.execute(query, params)
            output = await cursor.fetchall()
        await self.connection.commit()
        return output

    async def __aexit__(self, exc_type: type[BaseException] | None, exc_val: BaseException | None, exc_tb: TracebackType | None):
        await self.connection.commit()
        await self.connection.close()

### transpeak.user

@dataclasses.dataclass
class User(Sequence):
    id: int
    message_count: int
    under_18: bool
    reg_banned: bool
    bio: str | None
    last_seen: datetime.datetime | None
    last_message: str | None

    def __getitem__(self, index: int, /):
        return (self.id, self.message_count, self.under_18, self.reg_banned, self.bio, self.last_seen, self.last_message)[index]

    def __len__(self) -> int:
        return 7

def get_message_count(lite_db: SQLite, user_id: int) -> tuple[int, str] | None:
    msg_count = lite_db.fetchone("message_count.db", 'SELECT * FROM msgcount WHERE id = ?', (str(user_id),))
    return None if msg_count is None else (int(msg_count[1]), msg_count[2])

def get_is_under18(lite_db: SQLite, user_id: int) -> Literal[True] | None:
    return True if lite_db.fetchone("not18.db", 'SELECT * FROM not18 WHERE id = ?', (str(user_id),)) else None

def get_is_regbanned(lite_db: SQLite, user_id: int) -> Literal[True] | None:
    return True if lite_db.fetchone("regban.db", 'SELECT * FROM regban WHERE id = ?', (str(user_id),)) else None

def get_bio(lite_db: SQLite, user_id: int) -> str | None:
    bio = lite_db.fetchone("bios.db", 'SELECT * FROM bios WHERE user_id = ?', (str(user_id),))
    return None if not bio else bio[2]

def get_last_seen(lite_db: SQLite, user_id: int) -> datetime.datetime | None:
    last_seen = lite_db.fetchone("online.db", 'SELECT * FROM online WHERE id = ?', (str(user_id),))
    return None if not last_seen else datetime.datetime.fromtimestamp(int(last_seen[1]))

async def create_user_if_not_exists(lite_db: SQLite, pg_db: Postgres, user_id: int) -> None:

    user_new_db = await pg_db.fetchone('SELECT * FROM transpeak.user WHERE id = %s', (user_id,))

    if user_new_db is not None:
        return

    user = User(user_id, 0, False, False, None, None, None)

    msg_count = get_message_count(lite_db, user_id)
    if msg_count is None:
        print(f"message count for user {user_id} not found, setting to 0")
        user.message_count = 0
    else:
        user.message_count = msg_count[0]
        user.last_message = msg_count[1]

    if get_is_under18(lite_db, user_id):
        user.under_18 = True

    if get_is_regbanned(lite_db, user_id):
        user.reg_banned = True

    user.bio = get_bio(lite_db, user_id)

    user.last_seen = get_last_seen(lite_db, user_id)

    await pg_db.fetchone('INSERT INTO transpeak.user VALUES (%s, %s, %s, %s, %s, %s, %s)', user)


### transpeak.watchlist

async def create_watchlist_entry(lite_db: SQLite, pg_db: Postgres, user_id: int, description: str):
    await create_user_if_not_exists(lite_db, pg_db, user_id)
    await pg_db.fetchone('INSERT INTO transpeak.watchlist VALUES (%s, %s)', (user_id, description))

def get_watchlist(lite_db: SQLite):
    return lite_db.fetchall("watchlist.db", 'SELECT * FROM watchlist')

async def migrate_watchlist(lite_db: SQLite, pg_db: Postgres):
    watchlist = get_watchlist(lite_db)

    for entry in watchlist:
        await create_watchlist_entry(lite_db, pg_db, int(entry[0]), entry[1])

### transpeak.vc_watch

async def create_vc_watch_entry(lite_db: SQLite, pg_db: Postgres, user_id: int, reason: str | None = None):
    await create_user_if_not_exists(lite_db, pg_db, user_id)
    await pg_db.fetchone('INSERT INTO transpeak.vc_watch VALUES (%s, %s)', (user_id, reason))

def get_vc_watch(lite_db: SQLite):
    return lite_db.fetchall("vcwatch.db", "SELECT * FROM vcwatch;")

async def migrate_vc_watch(lite_db: SQLite, pg_db: Postgres):
    vc_wl = get_vc_watch(lite_db)
    for entry in vc_wl:
        await create_vc_watch_entry(lite_db, pg_db, int(entry[0]))

### transpeak.special_considerations

async def create_special_considerations_entry(lite_db: SQLite, pg_db: Postgres, user_id: int, description: str):
    await create_user_if_not_exists(lite_db, pg_db, user_id)
    await pg_db.fetchone('INSERT INTO transpeak.special_considerations VALUES (%s, %s)', (user_id, description))

def get_special_considerations(lite_db: SQLite):
    return lite_db.fetchall("sc.db", 'SELECT * FROM sc;')

async def migrate_special_considerations(lite_db: SQLite, pg_db: Postgres):
    sc_list = get_special_considerations(lite_db)
    for entry in sc_list:
        await create_special_considerations_entry(lite_db, pg_db, int(entry[0]), entry[1])

### transpeak.names

async def create_name_entry(lite_db: SQLite, pg_db: Postgres, user_id: int, name: str, timestamp: datetime.datetime):
    await create_user_if_not_exists(lite_db, pg_db, user_id)
    await pg_db.fetchone('INSERT INTO transpeak.names VALUES (%s, %s, %s)', (user_id, name, timestamp))

def get_name_list(lite_db: SQLite):
    return lite_db.fetchall("names.db", "SELECT * FROM names;")

async def migrate_names(lite_db: SQLite, pg_db: Postgres):
    name_list = get_name_list(lite_db)
    for entry in name_list:
        await create_name_entry(lite_db, pg_db, int(entry[0]), entry[1], datetime.datetime.fromtimestamp(int(entry[2])))

### transpeak.user_role

async def create_user_role_entries(lite_db: SQLite, pg_db: Postgres, user_id: int, role_list: str):
    await create_user_if_not_exists(lite_db, pg_db, user_id)
    roles = role_list.split(',')
    if roles[0] == '' and len(roles) == 1: return
    for role in roles:
        await pg_db.fetchone('INSERT INTO transpeak.user_role VALUES (%s, %s)', (user_id, int(role)))

def get_user_role_list(lite_db: SQLite):
    return lite_db.fetchall("roles.db", 'SELECT * FROM roles;')

async def migrate_user_role(lite_db: SQLite, pg_db: Postgres):
    user_role_list = get_user_role_list(lite_db)
    for entry in user_role_list:
        await create_user_role_entries(lite_db, pg_db, int(entry[0]), entry[1])

### transpeak.message_count_week

async def create_msg_count_week_entry(lite_db: SQLite, pg_db: Postgres, user_id: int, week: int, count: int):
    await create_user_if_not_exists(lite_db, pg_db, user_id)
    await pg_db.fetchone('INSERT INTO transpeak.message_count_week VALUES (%s, %s, %s)', (user_id, week, count))

def get_msg_count_week_list(lite_db: SQLite):
    return lite_db.fetchall("message_count_week.db", 'SELECT * FROM msgcount_week;')

async def migrate_msg_count_week(lite_db: SQLite, pg_db: Postgres):
    msg_count_week_list = get_msg_count_week_list(lite_db)
    for entry in msg_count_week_list:
        await create_msg_count_week_entry(lite_db, pg_db, int(entry[0]), int(entry[1]), int(entry[2]))

### transpeak.warn

# transpeak.warn_type
class WarnType(Enum):
    Soft = 'soft'
    Hard = 'hard'
    Staff = 'staff'

async def create_warn_entry(lite_db: SQLite, pg_db: Postgres, user_id: int, reason: str, issuer_id: int, timestamp: datetime.datetime, warn_type: WarnType):
    await create_user_if_not_exists(lite_db, pg_db, user_id)
    await create_user_if_not_exists(lite_db, pg_db, issuer_id)
    warn_type_str = warn_type.value
    await pg_db.fetchone('INSERT INTO transpeak.warn VALUES (%s, %s, %s, %s, %s)', (user_id, reason, issuer_id, timestamp, warn_type_str))

def get_hard_warns(lite_db: SQLite):
    return lite_db.fetchall("warns.db", 'SELECT * FROM warns;')

def get_soft_warns(lite_db: SQLite):
    return lite_db.fetchall("softwarns.db", 'SELECT * FROM warns;')

def get_staff_warns(lite_db: SQLite):
    return lite_db.fetchall("staffwarnings.db", 'SELECT * FROM staffwarnings;')

async def migrate_warns(lite_db: SQLite, pg_db: Postgres):
    hard_warn_list = get_hard_warns(lite_db)
    for entry in hard_warn_list:
        await create_warn_entry(lite_db, pg_db, int(entry[0]), entry[1], int(entry[2]), datetime.datetime.fromtimestamp(int(entry[3])), WarnType.Hard)
    soft_warn_list = get_soft_warns(lite_db)
    for entry in soft_warn_list:
        await create_warn_entry(lite_db, pg_db, int(entry[0]), entry[1], int(entry[2]), datetime.datetime.fromtimestamp(int(entry[3])), WarnType.Soft)
    staff_warn_list = get_staff_warns(lite_db)
    for entry in staff_warn_list:
        await create_warn_entry(lite_db, pg_db, int(entry[0]), entry[1], int(entry[2]), datetime.datetime.fromtimestamp(int(entry[3])), WarnType.Staff)

### transpeak.ban

# transpeak.ban_type
class BanType(Enum):
    Permanent = "permanent"
    Temporary = "temporary"
    VC = "vc"
    VCSoft = "vc_soft"

async def create_ban_entry(lite_db: SQLite, pg_db: Postgres, user_id: int, reason: str, issuer_id: int, timestamp: datetime.datetime, ban_type: BanType):
    await create_user_if_not_exists(lite_db, pg_db, user_id)
    await create_user_if_not_exists(lite_db, pg_db, issuer_id)
    await pg_db.fetchone('INSERT INTO transpeak.ban VALUES (%s, %s, %s, %s, %s, %s)', (user_id, reason, issuer_id, timestamp, ban_type.value))

def get_bans(lite_db: SQLite):
    return lite_db.fetchall('bans.db', 'SELECT * FROM bans;')

def get_vc_bans(lite_db: SQLite):
    return lite_db.fetchall('vcban.db', 'SELECT * FROM vcban;')

async def migrate_bans(lite_db: SQLite, pg_db: Postgres):
    ban_list = get_bans(lite_db)
    for entry in ban_list:
        ban_type = BanType.Temporary if entry[4] == 1 else BanType.Permanent
        await create_ban_entry(lite_db, pg_db, int(entry[0]), entry[1], int(entry[2]), datetime.datetime.fromtimestamp(int(entry[3])), ban_type)

sql_lite_db = SQLite()
postgres_db = Postgres()

asyncio.run(postgres_db.init())
asyncio.run(migrate_watchlist(sql_lite_db, postgres_db))
asyncio.run(migrate_vc_watch(sql_lite_db, postgres_db))
asyncio.run(migrate_special_considerations(sql_lite_db, postgres_db))
asyncio.run(migrate_names(sql_lite_db, postgres_db))
asyncio.run(migrate_user_role(sql_lite_db, postgres_db))
asyncio.run(migrate_msg_count_week(sql_lite_db, postgres_db))
asyncio.run(migrate_warns(sql_lite_db, postgres_db))