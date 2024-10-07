CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" INTEGER PRIMARY KEY, "inserted_at" TEXT);
CREATE TABLE sqlite_sequence(name,seq);
CREATE TABLE IF NOT EXISTS "rooms" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "name" TEXT NOT NULL, "topic" TEXT, "inserted_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL);
INSERT INTO schema_migrations VALUES(20241005220753,'2024-10-05T22:10:15');
