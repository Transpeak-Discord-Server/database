import dataclasses
import datetime
import os
from pathlib import Path
from typing import Literal, Sequence, _T_co

import psycopg
import sqlite3

db_files_path_env = os.getenv("SQLITE_PATH")
if db_files_path_env is None:
    print("ERROR: could not find env var SQLITE_PATH")
    exit(1)

db_files_path = Path(db_files_path_env)

postgres_url_env = os.getenv("POSTGRES_URL")
if postgres_url_env is None:
    print("ERROR: could not find env var POSTGRES_URL")
    exit(1)

postgres_url = postgres_url_env

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

def get_message_count(user_id: int) -> tuple[int, str] | None:
    connection = sqlite3.connect(db_files_path / "message_count.db")
    cursor = connection.cursor()
    cursor.execute('SELECT * FROM msgcount WHERE id = ?', (str(user_id),))
    msg_count = cursor.fetchone()
    return None if msg_count is None else (int(msg_count[1]), msg_count[2])

def get_is_under18(user_id: int) -> Literal[True] | None:
    connection = sqlite3.connect(db_files_path / "not18.db")
    cursor = connection.cursor()
    cursor.execute('SELECT * FROM not18 WHERE id = ?', (str(user_id),))
    return True if cursor.fetchone() else None

def get_is_regbanned(user_id: int) -> Literal[True] | None:
    connection = sqlite3.connect(db_files_path / "regban.db")
    cursor = connection.cursor()
    cursor.execute('SELECT * FROM regban WHERE id = ?', (str(user_id),))
    return True if cursor.fetchone() else None

def get_bio(user_id: int) -> str | None:
    connection = sqlite3.connect(db_files_path / "bios.db")
    cursor = connection.cursor()
    cursor.execute('SELECT * FROM bios WHERE user_id = ?', (str(user_id),))
    bio = cursor.fetchone()
    if bio:
        return bio[2]
    return None

def get_last_seen(user_id: int) -> datetime.datetime | None:
    connection = sqlite3.connect(db_files_path / "online.db")
    cursor = connection.cursor()
    cursor.execute('SELECT * FROM online WHERE id = ?', (str(user_id),))
    last_seen = cursor.fetchone()
    if not last_seen:
        return None
    return datetime.datetime.fromtimestamp(int(last_seen))

async def create_user_if_not_exists(user_id: int) -> None:

    connection = await psycopg.AsyncConnection.connect(postgres_url)
    async with connection.cursor() as cursor:
        await cursor.execute('SELECT * FROM transpeak.user WHERE id = ?', (user_id,))
        user_new_db = await cursor.fetchone()
    await connection.close()

    if user_new_db is not None:
        return

    user = User(user_id, 0, False, False, None, None, None)

    msg_count = get_message_count(user_id)
    if msg_count is None:
        print(f"message count for user {user_id} not found, setting to 0")
        user.message_count = 0
    else:
        user.message_count = msg_count[0]
        user.last_message = msg_count[1]

    if get_is_under18(user_id):
        user.under_18 = True

    if get_is_regbanned(user_id):
        user.reg_banned = True

    user.bio = get_bio(user_id)

    user.last_seen = get_last_seen(user_id)

    await connection.connect()
    async with connection.cursor() as cursor:
        await cursor.execute('INSERT INTO transpeak.user VALUES (?, ?, ?, ?, ?, ?, ?)', user)
