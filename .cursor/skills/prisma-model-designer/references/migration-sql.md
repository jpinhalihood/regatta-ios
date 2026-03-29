# Migration SQL Reference

## PostgreSQL

```sql
-- Table creation pattern
CREATE TABLE IF NOT EXISTS "User" (
  "id"        TEXT NOT NULL,
  "email"     TEXT NOT NULL,
  "name"      TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- Unique constraint
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- Foreign key
ALTER TABLE "Post" ADD CONSTRAINT "Post_authorId_fkey"
  FOREIGN KEY ("authorId") REFERENCES "User"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

-- Compound index
CREATE INDEX "Post_authorId_createdAt_idx" ON "Post"("authorId", "createdAt");

-- Enum (PostgreSQL native)
CREATE TYPE "Role" AS ENUM ('USER', 'ADMIN', 'MODERATOR');
ALTER TABLE "User" ADD COLUMN "role" "Role" NOT NULL DEFAULT 'USER';
```

## MySQL

```sql
CREATE TABLE `User` (
  `id`        VARCHAR(191) NOT NULL,
  `email`     VARCHAR(191) NOT NULL,
  `name`      VARCHAR(191),
  `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `User_email_key` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Enum in MySQL
`role` ENUM('USER', 'ADMIN', 'MODERATOR') NOT NULL DEFAULT 'USER'

-- Full-text index
ALTER TABLE `Post` ADD FULLTEXT INDEX `Post_title_content_idx` (`title`, `content`);
```

## SQLite

```sql
CREATE TABLE IF NOT EXISTS "User" (
  "id"        TEXT NOT NULL PRIMARY KEY,
  "email"     TEXT NOT NULL,
  "name"      TEXT,
  "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" DATETIME NOT NULL
);

CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- Note: SQLite doesn't support ALTER TABLE ADD CONSTRAINT for FKs after creation
-- FKs must be in CREATE TABLE, and PRAGMA foreign_keys = ON; must be set
```

## Drop / Rollback Patterns

```sql
-- Drop table safely
DROP TABLE IF EXISTS "PostTag";
DROP TABLE IF EXISTS "Post"; -- dependents first

-- Drop column (PostgreSQL / MySQL)
ALTER TABLE "User" DROP COLUMN "oldField";

-- Drop enum (PostgreSQL)
DROP TYPE IF EXISTS "Role";
```
