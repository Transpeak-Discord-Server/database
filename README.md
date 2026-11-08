# database
The database used by the Transpeak bots

### Notes for migration
**Timestamps**
- Timestamps are stored in the SQLite database as an integer number of seconds since the UNIX epoch
- Timestamps should be passed into the Postgres database as timezone-aware datetime objects

**Roles**
- A user's roles are stored in the SQLite database as a single entry where the `roles` field is a comma-separated list of the role IDs
- A user's roles will be stored in the Postgres database as individual entries for each role, following normalisation standards (atomicity)