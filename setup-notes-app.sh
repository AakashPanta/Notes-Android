#!/bin/bash
set -euo pipefail

# ============================================================
# Production Notes App Generator
# Next.js 14 + NextAuth v4 + Prisma + PostgreSQL + Docker + CI
# ============================================================

APP_NAME="production-notes-app"

echo "🚀 Generating $APP_NAME..."

mkdir -p \
  components \
  lib \
  pages/api/auth \
  pages/api/notes \
  pages/note \
  prisma \
  public \
  styles \
  tests \
  types \
  .github/workflows

# ============================================================
# README
# ============================================================

cat > README.md << 'EOF'
# Production Notes App

A production-oriented notes application built with **Next.js 14 Pages Router**, **NextAuth v4**, **Prisma**, and **PostgreSQL**.

## Features

- Email magic-link authentication
- Optional GitHub OAuth
- Database-backed sessions with Prisma Adapter
- Rich-text notes with React Quill
- Note tags
- Pinned notes
- Archived notes
- Revision history
- PostgreSQL full-text search
- Optional PostgreSQL GIN search index
- Offline-aware service worker shell caching
- Dockerized local development
- TypeScript
- ESLint
- Jest
- GitHub Actions CI

## Quick Start With Docker

```bash
cp .env.example .env
docker compose up --build
```

Open:

```text
http://localhost:3000
```

## Local Development

```bash
cp .env.example .env
npm install
npx prisma db push
npm run db:search-index
npm run dev
```

Open:

```text
http://localhost:3000
```

## Required Environment Variables

```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/notesdb?schema=public"
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="replace-with-a-strong-secret"
EMAIL_SERVER="smtp://user:pass@smtp.example.com:587"
EMAIL_FROM="Notes App <no-reply@example.com>"
```

## Optional GitHub OAuth

```env
GITHUB_ID=""
GITHUB_SECRET=""
```

## Production Notes

- Use HTTPS in production.
- Use a strong `NEXTAUTH_SECRET`.
- Use a real SMTP provider for email magic links.
- Use managed PostgreSQL or a properly backed-up PostgreSQL server.
- Run Prisma migrations in production instead of `db push`.
- Add API rate limiting before public deployment.
- Add database backups.
- Add monitoring and error tracking for production use.
EOF

# ============================================================
# package.json
# ============================================================

cat > package.json << 'EOF'
{
  "name": "production-notes-app",
  "version": "1.0.0",
  "private": true,
  "description": "Production-oriented notes app built with Next.js, NextAuth, Prisma, and PostgreSQL.",
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "prisma generate && next build",
    "start": "next start -p 3000",
    "lint": "eslint --ext .ts,.tsx pages components lib tests",
    "typecheck": "tsc --noEmit",
    "format": "prettier --write .",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "db:push": "prisma db push",
    "db:search-index": "node prisma/create-search-index.js",
    "seed": "ts-node --compiler-options '{\"module\":\"CommonJS\"}' prisma/seed.ts",
    "test": "jest --runInBand --passWithNoTests"
  },
  "dependencies": {
    "@next-auth/prisma-adapter": "^1.0.7",
    "@prisma/client": "^5.22.0",
    "axios": "^1.7.9",
    "next": "^14.2.0",
    "next-auth": "^4.24.11",
    "nodemailer": "^6.9.16",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-quill": "^2.0.0",
    "swr": "^2.3.0"
  },
  "devDependencies": {
    "@types/jest": "^29.5.14",
    "@types/node": "^20.17.0",
    "@types/nodemailer": "^6.4.17",
    "@types/react": "^18.3.12",
    "@types/react-dom": "^18.3.1",
    "@typescript-eslint/eslint-plugin": "^7.18.0",
    "@typescript-eslint/parser": "^7.18.0",
    "eslint": "^8.57.1",
    "eslint-config-next": "^14.2.0",
    "jest": "^29.7.0",
    "prettier": "^3.3.3",
    "prisma": "^5.22.0",
    "ts-jest": "^29.2.5",
    "ts-node": "^10.9.2",
    "typescript": "^5.6.3"
  }
}
EOF

# ============================================================
# Environment example
# ============================================================

cat > .env.example << 'EOF'
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/notesdb?schema=public"
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="replace-with-a-strong-secret"
EMAIL_SERVER="smtp://user:pass@smtp.example.com:587"
EMAIL_FROM="Notes App <no-reply@example.com>"
GITHUB_ID=""
GITHUB_SECRET=""
EOF

# ============================================================
# TypeScript config
# ============================================================

cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": false,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ]
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", "types/**/*.d.ts"],
  "exclude": ["node_modules"]
}
EOF

cat > next-env.d.ts << 'EOF'
/// <reference types="next" />
/// <reference types="next/image-types/global" />
EOF

# ============================================================
# ESLint / Jest
# ============================================================

cat > .eslintrc.json << 'EOF'
{
  "extends": ["next/core-web-vitals"],
  "rules": {
    "@next/next/no-html-link-for-pages": "off"
  }
}
EOF

cat > jest.config.js << 'EOF'
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  testMatch: ["**/tests/**/*.test.ts"],
  moduleNameMapper: {
    "^@/(.*)$": "<rootDir>/$1"
  }
};
EOF

# ============================================================
# Prisma schema
# ============================================================

cat > prisma/schema.prisma << 'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum ShareRole {
  VIEWER
  EDITOR
}

model User {
  id             String       @id @default(cuid())
  name           String?
  email          String?      @unique
  emailVerified  DateTime?
  image          String?

  accounts       Account[]
  sessions       Session[]
  notes          Note[]       @relation("UserNotes")
  notebooks      Notebook[]
  tags           Tag[]
  sharedNotes    SharedNote[] @relation("SharedWithUser")

  createdAt      DateTime     @default(now())
  updatedAt      DateTime     @updatedAt
}

model Account {
  id                 String  @id @default(cuid())
  userId             String
  type               String
  provider           String
  providerAccountId  String
  refresh_token      String? @db.Text
  access_token       String? @db.Text
  expires_at         Int?
  token_type         String?
  scope              String?
  id_token           String? @db.Text
  session_state      String?

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerAccountId])
  @@index([userId])
}

model Session {
  id            String   @id @default(cuid())
  sessionToken  String   @unique
  userId        String
  expires       DateTime

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
}

model VerificationToken {
  identifier String
  token      String   @unique
  expires    DateTime

  @@unique([identifier, token])
}

model Notebook {
  id        String   @id @default(cuid())
  title     String
  ownerId   String
  owner     User     @relation(fields: [ownerId], references: [id], onDelete: Cascade)
  notes     Note[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@unique([ownerId, title])
  @@index([ownerId])
}

model Tag {
  id        String   @id @default(cuid())
  name      String
  ownerId   String
  owner     User     @relation(fields: [ownerId], references: [id], onDelete: Cascade)
  notes     Note[]   @relation("NoteTags")
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@unique([ownerId, name])
  @@index([ownerId])
}

model Note {
  id           String        @id @default(cuid())
  title        String
  content      String        @db.Text
  plainText    String        @db.Text
  authorId     String
  author       User          @relation("UserNotes", fields: [authorId], references: [id], onDelete: Cascade)
  notebookId   String?
  notebook     Notebook?     @relation(fields: [notebookId], references: [id], onDelete: SetNull)
  tags         Tag[]         @relation("NoteTags")
  isPinned     Boolean       @default(false)
  isArchived   Boolean       @default(false)
  isEncrypted  Boolean       @default(false)
  versionCount Int           @default(0)
  versions     NoteVersion[]
  shared       SharedNote[]
  createdAt    DateTime      @default(now())
  updatedAt    DateTime      @updatedAt

  @@index([authorId])
  @@index([notebookId])
  @@index([isArchived])
  @@index([isPinned])
  @@index([updatedAt])
}

model NoteVersion {
  id        String   @id @default(cuid())
  noteId    String
  note      Note     @relation(fields: [noteId], references: [id], onDelete: Cascade)
  content   String   @db.Text
  diff      String?  @db.Text
  authorId  String?
  createdAt DateTime @default(now())

  @@index([noteId])
  @@index([createdAt])
}

model SharedNote {
  id               String    @id @default(cuid())
  noteId           String
  note             Note      @relation(fields: [noteId], references: [id], onDelete: Cascade)
  sharedWithEmail  String?
  sharedWithUserId String?
  sharedWithUser   User?     @relation("SharedWithUser", fields: [sharedWithUserId], references: [id], onDelete: Cascade)
  role             ShareRole @default(VIEWER)
  expiresAt        DateTime?
  passwordHash     String?
  createdAt        DateTime  @default(now())

  @@index([noteId])
  @@index([sharedWithEmail])
  @@index([sharedWithUserId])
}
EOF

# ============================================================
# Prisma helper scripts
# ============================================================

cat > prisma/create-search-index.js << 'EOF'
const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

async function main() {
  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS note_search_idx
    ON "Note"
    USING GIN (
      to_tsvector('english', coalesce("title", '') || ' ' || coalesce("plainText", ''))
    );
  `);

  console.log("PostgreSQL full-text search index is ready.");
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
EOF

cat > prisma/seed.ts << 'EOF'
import { prisma } from "../lib/prisma";

async function main() {
  const user = await prisma.user.upsert({
    where: { email: "demo@example.com" },
    update: {},
    create: {
      email: "demo@example.com",
      name: "Demo User"
    }
  });

  await prisma.note.create({
    data: {
      title: "Welcome to Production Notes",
      content: "<p>This is your first production-ready note.</p>",
      plainText: "This is your first production-ready note.",
      authorId: user.id,
      versions: {
        create: {
          content: "<p>This is your first production-ready note.</p>",
          authorId: user.id
        }
      }
    }
  });

  console.log(`Seeded ${user.email}`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
EOF

# ============================================================
# Library files
# ============================================================

cat > lib/prisma.ts << 'EOF'
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as {
  prisma?: PrismaClient;
};

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["query", "error", "warn"] : ["error"]
  });

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}
EOF

cat > lib/text.ts << 'EOF'
export function stripHtml(input: string): string {
  return input
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, " ")
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function normalizeTags(input: unknown): string[] {
  if (!Array.isArray(input)) return [];

  return Array.from(
    new Set(
      input
        .map((tag) => String(tag).trim().toLowerCase())
        .filter((tag) => tag.length > 0 && tag.length <= 40)
    )
  ).slice(0, 20);
}
EOF

# ============================================================
# NextAuth type extension
# ============================================================

cat > types/next-auth.d.ts << 'EOF'
import { DefaultSession } from "next-auth";

declare module "next-auth" {
  interface Session {
    user?: {
      id: string;
    } & DefaultSession["user"];
  }
}
EOF

# ============================================================
# NextAuth API
# ============================================================

cat > pages/api/auth/[...nextauth].ts << 'EOF'
import NextAuth, { type NextAuthOptions } from "next-auth";
import EmailProvider from "next-auth/providers/email";
import GitHubProvider from "next-auth/providers/github";
import { PrismaAdapter } from "@next-auth/prisma-adapter";
import { prisma } from "../../../lib/prisma";

const providers: NextAuthOptions["providers"] = [];

if (process.env.EMAIL_SERVER && process.env.EMAIL_FROM) {
  providers.push(
    EmailProvider({
      server: process.env.EMAIL_SERVER,
      from: process.env.EMAIL_FROM
    })
  );
}

if (process.env.GITHUB_ID && process.env.GITHUB_SECRET) {
  providers.push(
    GitHubProvider({
      clientId: process.env.GITHUB_ID,
      clientSecret: process.env.GITHUB_SECRET
    })
  );
}

export const authOptions: NextAuthOptions = {
  adapter: PrismaAdapter(prisma),
  providers,
  secret: process.env.NEXTAUTH_SECRET,
  session: {
    strategy: "database",
    maxAge: 30 * 24 * 60 * 60
  },
  pages: {
    signIn: "/"
  },
  callbacks: {
    async session({ session, user }) {
      if (session.user && user) {
        session.user.id = user.id;
      }

      return session;
    }
  },
  theme: {
    colorScheme: "auto",
    brandColor: "#111827"
  }
};

export default NextAuth(authOptions);
EOF

# ============================================================
# Notes API - list/create
# ============================================================

cat > pages/api/notes/index.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from "next";
import { getServerSession } from "next-auth/next";
import { authOptions } from "../auth/[...nextauth]";
import { prisma } from "../../../lib/prisma";
import { normalizeTags, stripHtml } from "../../../lib/text";

async function getCurrentUser(req: NextApiRequest, res: NextApiResponse) {
  const session = await getServerSession(req, res, authOptions);
  const email = session?.user?.email;

  if (!email) return null;

  return prisma.user.findUnique({ where: { email } });
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const user = await getCurrentUser(req, res);

  if (!user) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  if (req.method === "GET") {
    const { q, tag, notebook, archived } = req.query;
    const include = { tags: true, notebook: true };

    if (q && String(q).trim()) {
      const search = String(q).trim();

      const rows = await prisma.$queryRaw<{ id: string }[]>`
        SELECT "id"
        FROM "Note"
        WHERE "authorId" = ${user.id}
          AND "isArchived" = ${archived === "true"}
          AND to_tsvector('english', coalesce("title", '') || ' ' || coalesce("plainText", ''))
              @@ plainto_tsquery('english', ${search})
        ORDER BY "updatedAt" DESC
        LIMIT 200
      `;

      const ids = rows.map((row) => row.id);
      const order = new Map(ids.map((id, index) => [id, index]));

      const notes = await prisma.note.findMany({
        where: {
          id: { in: ids },
          authorId: user.id
        },
        include
      });

      notes.sort((a, b) => (order.get(a.id) ?? 0) - (order.get(b.id) ?? 0));

      return res.status(200).json(notes);
    }

    const notes = await prisma.note.findMany({
      where: {
        authorId: user.id,
        isArchived: archived === "true",
        ...(notebook ? { notebookId: String(notebook) } : {}),
        ...(tag
          ? {
              tags: {
                some: {
                  ownerId: user.id,
                  name: String(tag).toLowerCase()
                }
              }
            }
          : {})
      },
      orderBy: [{ isPinned: "desc" }, { updatedAt: "desc" }],
      take: 200,
      include
    });

    return res.status(200).json(notes);
  }

  if (req.method === "POST") {
    const title =
      typeof req.body.title === "string" && req.body.title.trim()
        ? req.body.title.trim()
        : "Untitled";

    const content = typeof req.body.content === "string" ? req.body.content : "";
    const notebookId = typeof req.body.notebookId === "string" ? req.body.notebookId : undefined;
    const tags = normalizeTags(req.body.tags);
    const plainText = stripHtml(content);

    if (notebookId) {
      const notebook = await prisma.notebook.findFirst({
        where: {
          id: notebookId,
          ownerId: user.id
        },
        select: {
          id: true
        }
      });

      if (!notebook) {
        return res.status(400).json({ error: "Invalid notebook" });
      }
    }

    const note = await prisma.note.create({
      data: {
        title,
        content,
        plainText,
        authorId: user.id,
        notebookId,
        isEncrypted: Boolean(req.body.isEncrypted),
        tags: {
          connectOrCreate: tags.map((name) => ({
            where: {
              ownerId_name: {
                ownerId: user.id,
                name
              }
            },
            create: {
              ownerId: user.id,
              name
            }
          }))
        },
        versions: {
          create: {
            content,
            authorId: user.id
          }
        }
      },
      include: {
        tags: true,
        notebook: true
      }
    });

    return res.status(201).json(note);
  }

  res.setHeader("Allow", "GET, POST");
  return res.status(405).json({ error: "Method not allowed" });
}
EOF

# ============================================================
# Notes API - read/update/delete
# ============================================================

cat > pages/api/notes/[id].ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from "next";
import { getServerSession } from "next-auth/next";
import { authOptions } from "../auth/[...nextauth]";
import { prisma } from "../../../lib/prisma";
import { normalizeTags, stripHtml } from "../../../lib/text";

async function getCurrentUser(req: NextApiRequest, res: NextApiResponse) {
  const session = await getServerSession(req, res, authOptions);
  const email = session?.user?.email;

  if (!email) return null;

  return prisma.user.findUnique({ where: { email } });
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const user = await getCurrentUser(req, res);

  if (!user) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const id = String(req.query.id || "");

  if (!id) {
    return res.status(400).json({ error: "Missing note id" });
  }

  if (req.method === "GET") {
    const note = await prisma.note.findFirs
