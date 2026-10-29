import dataclasses
import datetime
import os
from _typeshed import SupportsLenAndGetItem
from pathlib import Path
from sqlite3 import Row
from typing import Literal, Sequence, _T_co, Mapping, Any, LiteralString, List
from typing_extensions import Buffer

import psycopg
import sqlite3

from psycopg import AsyncConnection
from psycopg.sql import SQL, Composed

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

    async def fetchone(self, query: LiteralString | SQL | bytes | Composed, params: Mapping[str, Any] | Sequence[Any] | None = None) -> Row | None:
        async with self.connection.cursor() as cursor:
            await cursor.execute(query, params)
            output = await cursor.fetchone()
        await self.connection.close()
        return output

    async def fetchall(self, query: LiteralString | SQL | bytes | Composed, params: Mapping[str, Any] | Sequence[Any] | None = None) -> List[Row]:
        async with self.connection.cursor() as cursor:
            await cursor.execute(query, params)
            output = await cursor.fetchall()
        await self.connection.close()
        return output

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

    def __getitem__(self, index: int, /) -> _T_co:
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
    return None if not last_seen else datetime.datetime.fromtimestamp(int(last_seen))

async def create_user_if_not_exists(lite_db: SQLite, pg_db: Postgres, user_id: int) -> None:

    user_new_db = await pg_db.fetchone('SELECT * FROM transpeak.user WHERE id = ?', (user_id,))

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

    await pg_db.fetchone('INSERT INTO transpeak.user VALUES (?, ?, ?, ?, ?, ?, ?)', user)


### transpeak.watchlist

async def create_watchlist_entry(lite_db: SQLite, pg_db: Postgres, user_id: int, description: str):
    await create_user_if_not_exists(lite_db, pg_db, user_id)
    await pg_db.fetchone('INSERT INTO transpeak.watchlist VALUES (?, ?)', (user_id, description))

def get_watchlist(lite_db: SQLite):
    return lite_db.fetchall("watchlist.db", 'SELECT * FROM watchlist')

async def migrate_watchlist(lite_db: SQLite, pg_db: Postgres):
    watchlist = get_watchlist(lite_db)

    for entry in watchlist:
        await create_watchlist_entry(lite_db, pg_db, int(entry[0]), entry[1])

