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
    const note = await prisma.note.findFirst({
      where: {
        id,
        authorId: user.id
      },
      include: {
        tags: true,
        notebook: true,
        versions: {
          orderBy: {
            createdAt: "desc"
          },
          take: 50
        }
      }
    });

    if (!note) {
      return res.status(404).json({ error: "Not found" });
    }

    return res.status(200).json(note);
  }

  if (req.method === "PUT") {
    const existing = await prisma.note.findFirst({
      where: {
        id,
        authorId: user.id
      }
    });

    if (!existing) {
      return res.status(404).json({ error: "Not found" });
    }

    const title =
      typeof req.body.title === "string" && req.body.title.trim()
        ? req.body.title.trim()
        : existing.title;

    const content = typeof req.body.content === "string" ? req.body.content : existing.content;
    const tags = normalizeTags(req.body.tags);
    const plainText = stripHtml(content);

    const updated = await prisma.note.update({
      where: {
        id
      },
      data: {
        title,
        content,
        plainText,
        isPinned: typeof req.body.isPinned === "boolean" ? req.body.isPinned : existing.isPinned,
        isArchived: typeof req.body.isArchived === "boolean" ? req.body.isArchived : existing.isArchived,
        isEncrypted:
          typeof req.body.isEncrypted === "boolean" ? req.body.isEncrypted : existing.isEncrypted,
        versionCount: {
          increment: 1
        },
        tags: {
          set: [],
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

    return res.status(200).json(updated);
  }

  if (req.method === "DELETE") {
    const existing = await prisma.note.findFirst({
      where: {
        id,
        authorId: user.id
      }
    });

    if (!existing) {
      return res.status(404).json({ error: "Not found" });
    }

    await prisma.note.delete({
      where: {
        id
      }
    });

    return res.status(200).json({ ok: true });
  }

  res.setHeader("Allow", "GET, PUT, DELETE");
  return res.status(405).json({ error: "Method not allowed" });
}
EOF

# ============================================================
# Editor component
# ============================================================

cat > components/Editor.tsx << 'EOF'
import dynamic from "next/dynamic";

const ReactQuill = dynamic(() => import("react-quill"), {
  ssr: false,
  loading: () => <div className="editor-loading">Loading editor...</div>
});

const modules = {
  toolbar: [
    [{ header: [1, 2, 3, false] }],
    ["bold", "italic", "underline", "strike"],
    [{ list: "ordered" }, { list: "bullet" }],
    ["blockquote", "code-block"],
    ["link"],
    ["clean"]
  ]
};

export default function Editor({
  value,
  onChange
}: {
  value: string;
  onChange: (value: string) => void;
}) {
  return <ReactQuill theme="snow" value={value} onChange={onChange} modules={modules} />;
}
EOF

# ============================================================
# Next app wrapper
# ============================================================

cat > pages/_app.tsx << 'EOF'
import type { AppProps } from "next/app";
import { useEffect } from "react";
import { SessionProvider } from "next-auth/react";
import "react-quill/dist/quill.snow.css";
import "../styles/globals.css";

export default function App({ Component, pageProps: { session, ...pageProps } }: AppProps) {
  useEffect(() => {
    if (process.env.NODE_ENV !== "production") return;
    if (!("serviceWorker" in navigator)) return;

    navigator.serviceWorker.register("/sw.js").catch((error) => {
      console.error("Service worker registration failed", error);
    });
  }, []);

  return (
    <SessionProvider session={session}>
      <Component {...pageProps} />
    </SessionProvider>
  );
}
EOF

# ============================================================
# Home page
# ============================================================

cat > pages/index.tsx << 'EOF'
import axios from "axios";
import Link from "next/link";
import { signIn, signOut, useSession } from "next-auth/react";
import { useMemo, useState } from "react";
import useSWR from "swr";

const fetcher = (url: string) => axios.get(url).then((response) => response.data);

type NoteListItem = {
  id: string;
  title: string;
  plainText: string;
  isPinned: boolean;
  updatedAt: string;
  tags: {
    id: string;
    name: string;
  }[];
};

export default function Home() {
  const { data: session, status } = useSession();
  const [q, setQ] = useState("");

  const notesUrl = useMemo(() => {
    if (!session) return null;

    const params = new URLSearchParams();

    if (q.trim()) {
      params.set("q", q.trim());
    }

    const suffix = params.toString();

    return `/api/notes${suffix ? `?${suffix}` : ""}`;
  }, [q, session]);

  const { data: notes, mutate, isLoading } = useSWR<NoteListItem[]>(notesUrl, fetcher);

  async function createNote() {
    const response = await axios.post("/api/notes", {
      title: "New note",
      content: "<p></p>",
      tags: []
    });

    await mutate();

    window.location.href = `/note/${response.data.id}`;
  }

  return (
    <main className="app-shell">
      <section className="hero-card">
        <div>
          <p className="eyebrow">Production Notes</p>
          <h1>Private, searchable, revision-safe notes.</h1>
          <p className="subtitle">
            A clean Next.js + Prisma notes app foundation with authentication, rich editing, tags,
            archive state, revision history, and CI-ready structure.
          </p>
        </div>

        <div className="auth-panel">
          {status === "loading" ? (
            <span>Checking session...</span>
          ) : session ? (
            <>
              <span className="signed-in">
                Signed in as {session.user?.email || session.user?.name}
              </span>
              <button className="secondary-button" onClick={() => signOut()}>
                Sign out
              </button>
            </>
          ) : (
            <button className="primary-button" onClick={() => signIn()}>
              Sign in
            </button>
          )}
        </div>
      </section>

      {session ? (
        <section className="notes-card">
          <div className="toolbar">
            <input
              aria-label="Search notes"
              placeholder="Search notes..."
              value={q}
              onChange={(event) => setQ(event.target.value)}
            />
            <button className="primary-button" onClick={createNote}>
              New Note
            </button>
          </div>

          {isLoading ? <p className="muted">Loading notes...</p> : null}

          <div className="notes-grid">
            {notes?.map((note) => (
              <Link key={note.id} href={`/note/${note.id}`} className="note-card">
                <div className="note-card-top">
                  <h2>{note.title}</h2>
                  {note.isPinned ? <span className="pin">Pinned</span> : null}
                </div>

                <p>{note.plainText || "No content yet."}</p>

                <div className="note-meta">
                  <span>{new Date(note.updatedAt).toLocaleString()}</span>
                  <span>{note.tags.map((tag) => tag.name).join(", ")}</span>
                </div>
              </Link>
            ))}
          </div>

          {!isLoading && notes?.length === 0 ? (
            <p className="muted">No notes found. Create your first note.</p>
          ) : null}
        </section>
      ) : (
        <section className="notes-card">
          <p className="muted">Sign in to create and manage your notes.</p>
        </section>
      )}
    </main>
  );
}
EOF

# ============================================================
# Note editor page
# ============================================================

cat > pages/note/[id].tsx << 'EOF'
import axios from "axios";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import useSWR from "swr";
import Editor from "../../components/Editor";

const fetcher = (url: string) => axios.get(url).then((response) => response.data);

type Note = {
  id: string;
  title: string;
  content: string;
  isPinned: boolean;
  isArchived: boolean;
  tags: {
    id: string;
    name: string;
  }[];
  versions: {
    id: string;
    createdAt: string;
  }[];
};

export default function NotePage() {
  const router = useRouter();
  const id = typeof router.query.id === "string" ? router.query.id : "";

  const { data: note, mutate, isLoading } = useSWR<Note>(
    id ? `/api/notes/${id}` : null,
    fetcher
  );

  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [tagText, setTagText] = useState("");
  const [isPinned, setIsPinned] = useState(false);
  const [isArchived, setIsArchived] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (!note) return;

    setTitle(note.title || "Untitled");
    setContent(note.content || "");
    setTagText(note.tags?.map((tag) => tag.name).join(", ") || "");
    setIsPinned(Boolean(note.isPinned));
    setIsArchived(Boolean(note.isArchived));
  }, [note]);

  async function save() {
    if (!id) return;

    setIsSaving(true);

    try {
      await axios.put(`/api/notes/${id}`, {
        title,
        content,
        isPinned,
        isArchived,
        tags: tagText
          .split(",")
          .map((tag) => tag.trim())
          .filter(Boolean)
      });

      await mutate();
    } finally {
      setIsSaving(false);
    }
  }

  async function remove() {
    if (!id) return;

    const confirmed = window.confirm("Delete this note permanently?");

    if (!confirmed) return;

    await axios.delete(`/api/notes/${id}`);
    await router.push("/");
  }

  if (isLoading || !note) {
    return <main className="app-shell">Loading note...</main>;
  }

  return (
    <main className="app-shell">
      <section className="editor-card">
        <div className="editor-header">
          <button className="secondary-button" onClick={() => router.push("/")}>
            Back
          </button>

          <div className="editor-actions">
            <button className="secondary-button danger" onClick={remove}>
              Delete
            </button>

            <button className="primary-button" onClick={save} disabled={isSaving}>
              {isSaving ? "Saving..." : "Save"}
            </button>
          </div>
        </div>

        <input
          className="title-input"
          aria-label="Note title"
          value={title}
          onChange={(event) => setTitle(event.target.value)}
        />

        <div className="metadata-row">
          <label>
            <input
              type="checkbox"
              checked={isPinned}
              onChange={(event) => setIsPinned(event.target.checked)}
            />
            Pinned
          </label>

          <label>
            <input
              type="checkbox"
              checked={isArchived}
              onChange={(event) => setIsArchived(event.target.checked)}
            />
            Archived
          </label>
        </div>

        <input
          className="tag-input"
          aria-label="Tags"
          placeholder="Tags, separated by commas"
          value={tagText}
          onChange={(event) => setTagText(event.target.value)}
        />

        <Editor value={content} onChange={setContent} />
      </section>

      <section className="versions-card">
        <h2>Versions</h2>

        <ul>
          {note.versions?.map((version) => (
            <li key={version.id}>{new Date(version.createdAt).toLocaleString()}</li>
          ))}
        </ul>
      </section>
    </main>
  );
}
EOF

# ============================================================
# Global styles
# ============================================================

cat > styles/globals.css << 'EOF'
:root {
  color-scheme: light dark;
  --background: #f4f5f7;
  --foreground: #111827;
  --muted: #6b7280;
  --card: rgba(255, 255, 255, 0.82);
  --border: rgba(17, 24, 39, 0.12);
  --primary: #111827;
  --primary-text: #ffffff;
  --danger: #b91c1c;
}

@media (prefers-color-scheme: dark) {
  :root {
    --background: #05070b;
    --foreground: #f9fafb;
    --muted: #9ca3af;
    --card: rgba(17, 24, 39, 0.86);
    --border: rgba(255, 255, 255, 0.12);
    --primary: #ffffff;
    --primary-text: #111827;
    --danger: #f87171;
  }
}

* {
  box-sizing: border-box;
}

html,
body {
  margin: 0;
  min-height: 100%;
  background:
    radial-gradient(circle at top left, rgba(99, 102, 241, 0.18), transparent 34rem),
    var(--background);
  color: var(--foreground);
  font-family:
    Inter,
    ui-sans-serif,
    system-ui,
    -apple-system,
    BlinkMacSystemFont,
    "Segoe UI",
    sans-serif;
}

button,
input {
  font: inherit;
}

button {
  cursor: pointer;
}

button:disabled {
  cursor: not-allowed;
  opacity: 0.65;
}

.app-shell {
  width: min(1120px, calc(100% - 32px));
  margin: 0 auto;
  padding: 32px 0;
}

.hero-card,
.notes-card,
.editor-card,
.versions-card {
  border: 1px solid var(--border);
  background: var(--card);
  box-shadow: 0 24px 80px rgba(0, 0, 0, 0.12);
  backdrop-filter: blur(16px);
  border-radius: 28px;
}

.hero-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  padding: 32px;
  margin-bottom: 24px;
}

.eyebrow {
  margin: 0 0 12px;
  color: var(--muted);
  font-size: 0.8rem;
  font-weight: 800;
  letter-spacing: 0.14em;
  text-transform: uppercase;
}

h1,
h2,
p {
  margin-top: 0;
}

h1 {
  max-width: 760px;
  margin-bottom: 12px;
  font-size: clamp(2rem, 5vw, 4.5rem);
  line-height: 0.96;
  letter-spacing: -0.06em;
}

.subtitle {
  max-width: 680px;
  color: var(--muted);
  font-size: 1.05rem;
  line-height: 1.7;
}

.auth-panel {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 12px;
  min-width: 220px;
}

.signed-in,
.muted {
  color: var(--muted);
}

.primary-button,
.secondary-button {
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 10px 16px;
  transition:
    transform 160ms ease,
    opacity 160ms ease;
}

.primary-button:hover,
.secondary-button:hover {
  transform: translateY(-1px);
}

.primary-button {
  background: var(--primary);
  color: var(--primary-text);
}

.secondary-button {
  background: transparent;
  color: var(--foreground);
}

.secondary-button.danger {
  color: var(--danger);
}

.notes-card,
.editor-card,
.versions-card {
  padding: 24px;
}

.toolbar,
.editor-header,
.editor-actions,
.metadata-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.toolbar,
.editor-header {
  justify-content: space-between;
  margin-bottom: 20px;
}

.toolbar input,
.title-input,
.tag-input {
  width: 100%;
  border: 1px solid var(--border);
  background: transparent;
  color: var(--foreground);
  border-radius: 18px;
  padding: 12px 14px;
  outline: none;
}

.toolbar input:focus,
.title-input:focus,
.tag-input:focus {
  border-color: currentColor;
}

.notes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 16px;
}

.note-card {
  display: flex;
  min-height: 180px;
  flex-direction: column;
  justify-content: space-between;
  border: 1px solid var(--border);
  border-radius: 22px;
  padding: 18px;
  color: inherit;
  text-decoration: none;
  background: rgba(255, 255, 255, 0.04);
}

.note-card-top {
  display: flex;
  justify-content: space-between;
  gap: 8px;
}

.note-card h2 {
  margin-bottom: 10px;
  font-size: 1.15rem;
}

.note-card p {
  display: -webkit-box;
  overflow: hidden;
  color: var(--muted);
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 4;
}

.note-meta {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  color: var(--muted);
  font-size: 0.8rem;
}

.pin {
  height: fit-content;
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 3px 8px;
  color: var(--muted);
  font-size: 0.72rem;
}

.editor-card {
  margin-bottom: 24px;
}

.title-input {
  margin-bottom: 16px;
  border: 0;
  border-bottom: 1px solid var(--border);
  border-radius: 0;
  padding-left: 0;
  font-size: clamp(1.8rem, 4vw, 3rem);
  font-weight: 800;
  letter-spacing: -0.04em;
}

.metadata-row {
  margin-bottom: 16px;
  color: var(--muted);
}

.metadata-row label {
  display: flex;
  align-items: center;
  gap: 8px;
}

.tag-input {
  margin-bottom: 16px;
}

.editor-loading {
  min-height: 260px;
  border: 1px solid var(--border);
  border-radius: 18px;
  padding: 24px;
  color: var(--muted);
}

.ql-toolbar.ql-snow,
.ql-container.ql-snow {
  border-color: var(--border) !important;
}

.ql-toolbar.ql-snow {
  border-top-left-radius: 18px;
  border-top-right-radius: 18px;
}

.ql-container.ql-snow {
  min-height: 360px;
  border-bottom-left-radius: 18px;
  border-bottom-right-radius: 18px;
  font-size: 1rem;
}

.ql-editor {
  min-height: 360px;
}

.versions-card ul {
  margin: 0;
  padding-left: 18px;
  color: var(--muted);
}

@media (max-width: 720px) {
  .hero-card,
  .toolbar,
  .editor-header {
    align-items: stretch;
    flex-direction: column;
  }

  .auth-panel {
    align-items: stretch;
  }

  .editor-actions {
    justify-content: space-between;
  }
}
EOF

# ============================================================
# Service worker
# ============================================================

cat > public/sw.js << 'EOF'
const CACHE_NAME = "production-notes-v1";
const SHELL_ASSETS = ["/"];

self.addEventListener("install", (event) => {
  self.skipWaiting();
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(SHELL_ASSETS)));
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key)))
      )
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return;

  const url = new URL(event.request.url);

  if (url.pathname.startsWith("/api/")) return;

  event.respondWith(
    fetch(event.request)
      .then((response) => {
        const copy = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
        return response;
      })
      .catch(() => caches.match(event.request).then((cached) => cached || caches.match("/")))
  );
});
EOF

# ============================================================
# Docker
# ============================================================

cat > docker-compose.yml << 'EOF'
services:
  db:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: notesdb
    volumes:
      - db-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d notesdb"]
      interval: 5s
      timeout: 5s
      retries: 20

  app:
    build: .
    command: sh -c "npm run db:push && npm run db:search-index && npm run dev"
    restart: unless-stopped
    volumes:
      - .:/app
      - /app/node_modules
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: "postgresql://postgres:postgres@db:5432/notesdb?schema=public"
      NEXTAUTH_URL: "http://localhost:3000"
      NEXTAUTH_SECRET: "change-this-secret-before-production"
      EMAIL_SERVER: "smtp://user:pass@smtp.example.com:587"
      EMAIL_FROM: "Notes App <no-reply@example.com>"
      GITHUB_ID: ""
      GITHUB_SECRET: ""
    depends_on:
      db:
        condition: service_healthy

volumes:
  db-data:
EOF

cat > Dockerfile << 'EOF'
FROM node:20-alpine

WORKDIR /app

COPY package.json ./
RUN npm install

COPY . .

RUN npm run prisma:generate
RUN npm run build

EXPOSE 3000

CMD ["npm", "run", "start"]
EOF

# ============================================================
# Tests
# ============================================================

cat > tests/prisma.test.ts << 'EOF'
import { prisma } from "../lib/prisma";

afterAll(async () => {
  await prisma.$disconnect();
});

describe("database smoke test", () => {
  it("connects to PostgreSQL", async () => {
    const result = await prisma.$queryRaw<{ now: Date }[]>`select now()`;
    expect(result[0]?.now).toBeDefined();
  });
});
EOF

# ============================================================
# GitHub Actions CI
# ============================================================

cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: notesdb
        ports:
          - 5432:5432
        options: >-
          --health-cmd "pg_isready -U postgres -d notesdb"
          --health-interval 5s
          --health-timeout 5s
          --health-retries 20

    env:
      DATABASE_URL: postgresql://postgres:postgres@localhost:5432/notesdb?schema=public
      NEXTAUTH_URL: http://localhost:3000
      NEXTAUTH_SECRET: ci-secret-do-not-use-in-production
      EMAIL_SERVER: smtp://user:pass@smtp.example.com:587
      EMAIL_FROM: Notes App <no-reply@example.com>

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - name: Install dependencies
        run: npm install

      - name: Generate Prisma client
        run: npx prisma generate

      - name: Push Prisma schema to test database
        run: npx prisma db push --skip-generate

      - name: Create PostgreSQL search index
        run: npm run db:search-index

      - name: Typecheck
        run: npm run typecheck

      - name: Lint
        run: npm run lint

      - name: Test
        run: npm test

      - name: Build
        run: npm run build
EOF

# ============================================================
# License
# ============================================================

cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2026 AakashPanta

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# ============================================================
# Gitignore
# ============================================================

cat > .gitignore << 'EOF'
node_modules
.env
.env.local
.next
.DS_Store
coverage
dist
*.log
EOF

# ============================================================
# Done
# ============================================================

echo ""
echo "✅ Production Notes App files created successfully."
echo ""
echo "Next steps:"
echo "1. cp .env.example .env"
echo "2. npm install"
echo "3. npx prisma generate"
echo "4. npm run dev"
echo ""
echo "Open:"
echo "http://localhost:3000"
echo ""
echo "Docker option:"
echo "docker compose up --build"
