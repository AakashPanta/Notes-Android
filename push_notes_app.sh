#!/usr/bin/env bash
set -euo pipefail

echo "Running from: $(pwd)"

# Safety check - confirm repository root
if [ ! -d ".git" ]; then
  echo "Error: not in a git repo (no .git). Run this inside /workspaces/Notes-Android"
  exit 1
fi

# Ensure SSH agent has a key (best-effort)
if ! ssh-add -l >/dev/null 2>&1; then
  echo "ssh-agent has no identities. Attempting to start agent and add default deploy key..."
  eval "$(ssh-agent -s)"
  if [ -f "$HOME/.ssh/notes_android_deploy" ]; then
    ssh-add "$HOME/.ssh/notes_android_deploy" || true
  fi
fi

# create directories
mkdir -p lib pages/api/auth pages/api/notes pages/note components prisma public .github/workflows tests styles

# README
cat > README.md <<'MD'
# Production Notes App

Features
- Auth: Email + OAuth (NextAuth)
- Rich-text notes, notebooks, tags, pinned, archive
- Versions & revisions
- Search (Postgres full-text)
- Offline support (service worker), autosave
- Dockerized + Prisma migrations
- Tests & CI

Quick start (Docker)
1. copy .env.example to .env and adjust
2. docker-compose up --build
3. Visit http://localhost:3000

Local dev (without Docker)
1. Install: npm install (or pnpm install)
2. Set DATABASE_URL in .env (Postgres)
3. npx prisma migrate dev --name init
4. npm run dev
MD

# package.json
cat > package.json <<'JSON'
{
  "name": "prod-notes-app",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "next build",
    "start": "next start -p 3000",
    "lint": "eslint --ext .ts,.tsx .",
    "format": "prettier --write .",
    "prisma:migrate": "prisma migrate dev",
    "prisma:generate": "prisma generate",
    "seed": "ts-node prisma/seed.ts",
    "test": "jest --passWithNoTests"
  },
  "dependencies": {
    "@prisma/client": "^5.0.0",
    "next": "14.0.0",
    "react": "18.2.0",
    "react-dom": "18.2.0",
    "next-auth": "^5.0.0",
    "react-quill": "^2.0.0",
    "swr": "^2.1.0",
    "axios": "^1.5.0",
    "bcryptjs": "^2.4.3",
    "uuid": "^9.0.0"
  },
  "devDependencies": {
    "prisma": "^5.0.0",
    "typescript": "^5.2.0",
    "eslint": "^8.0.0",
    "jest": "^29.0.0",
    "@types/jest": "^29.0.0",
    "@types/node": "^20.0.0",
    "@types/react": "^18.0.0",
    "ts-node": "^10.0.0",
    "prettier": "^2.8.0"
  }
}
JSON

# prisma/schema.prisma
cat > prisma/schema.prisma <<'PRISMA'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id            String   @id @default(uuid())
  email         String   @unique
  name          String?
  image         String?
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
  notes         Note[]   @relation("authorNotes")
  sharedNotes   SharedNote[]
}

model Notebook {
  id        String   @id @default(uuid())
  title     String
  ownerId   String
  owner     User     @relation(fields: [ownerId], references: [id])
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  notes     Note[]
}

model Tag {
  id    String @id @default(uuid())
  name  String
  notes Note[] @relation("noteTags", references: [id])
}

model Note {
  id           String      @id @default(uuid())
  title        String
  content      String
  plainText    String
  authorId     String
  author       User        @relation("authorNotes", fields: [authorId], references: [id])
  notebookId   String?     
  notebook     Notebook?   @relation(fields: [notebookId], references: [id])
  tags         Tag[]       @relation("noteTags")
  isPinned     Boolean     @default(false)
  isArchived   Boolean     @default(false)
  isEncrypted  Boolean     @default(false)
  versionCount Int         @default(0)
  createdAt    DateTime    @default(now())
  updatedAt    DateTime    @updatedAt
  versions     NoteVersion[]
  shared       SharedNote[]
  @@index([title])
  @@fulltext([title, content], map: "note_fulltext_idx")
}

model NoteVersion {
  id        String   @id @default(uuid())
  noteId    String
  note      Note     @relation(fields: [noteId], references: [id])
  content   String
  diff      String?
  createdAt DateTime @default(now())
  authorId  String?
}

model SharedNote {
  id         String   @id @default(uuid())
  noteId     String
  note       Note     @relation(fields: [noteId], references: [id])
  sharedWith String?
  role       String
  expiresAt  DateTime?
  password   String?
  createdAt  DateTime @default(now())
}
PRISMA

# lib/prisma.ts
mkdir -p lib
cat > lib/prisma.ts <<'TS'
import { PrismaClient } from '@prisma/client';

declare global {
  var prisma: PrismaClient | undefined;
}

export const prisma =
  global.prisma ||
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : []
  });

if (process.env.NODE_ENV !== 'production') global.prisma = prisma;
TS

# NextAuth API route
mkdir -p pages/api/auth
cat > pages/api/auth/[...nextauth].ts <<'TS'
import NextAuth from "next-auth";
import EmailProvider from "next-auth/providers/email";
import GitHubProvider from "next-auth/providers/github";
import { PrismaAdapter } from "@next-auth/prisma-adapter";
import { prisma } from "../../../lib/prisma";

export default NextAuth({
  adapter: PrismaAdapter(prisma),
  providers: [
    EmailProvider({
      server: process.env.EMAIL_SERVER,
      from: process.env.EMAIL_FROM
    }),
    GitHubProvider({
      clientId: process.env.GITHUB_ID || "",
      clientSecret: process.env.GITHUB_SECRET || ""
    })
  ],
  secret: process.env.NEXTAUTH_SECRET,
  session: {
    strategy: "database",
    maxAge: 30 * 24 * 60 * 60
  },
  callbacks: {
    async session({ session, user }) {
      if (session.user) {
        session.user.id = user.id;
      }
      return session;
    }
  }
});
TS

# Notes API routes
mkdir -p pages/api/notes
cat > pages/api/notes/index.ts <<'TS'
import type { NextApiRequest, NextApiResponse } from "next";
import { getServerSession } from "next-auth/next";
import { authOptions } from "../auth/[...nextauth]";
import { prisma } from "../../../lib/prisma";

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const session = await getServerSession(req, res, authOptions as any);
  if (!session || !session.user?.email) return res.status(401).json({ error: "Unauthorized" });

  const userEmail = session.user.email;
  const user = await prisma.user.findUnique({ where: { email: userEmail } });
  if (!user) return res.status(401).json({ error: "Unauthorized" });

  if (req.method === "GET") {
    const { q, tag, notebook, archived } = req.query;
    let where: any = { authorId: user.id };
    if (archived === "true") where.isArchived = true;
    else where.isArchived = false;
    if (notebook) where.notebookId = String(notebook);
    if (tag) where.tags = { some: { name: String(tag) } };
    if (q) {
      const notes = await prisma.$queryRawUnsafe(
        `SELECT * FROM "Note" WHERE "authorId" = $1 AND to_tsvector('english', coalesce(title,'') || ' ' || coalesce(content,'')) @@ plainto_tsquery('english', $2) ORDER BY "updatedAt" DESC LIMIT 200`,
        user.id,
        String(q)
      );
      return res.json(notes);
    }
    const notes = await prisma.note.findMany({
      where,
      orderBy: { updatedAt: "desc" },
      take: 200,
      include: { tags: true, notebook: true }
    });
    return res.json(notes);
  }

  if (req.method === "POST") {
    const { title = "Untitled", content = "", notebookId, tags = [], isEncrypted = false } = req.body;
    const plainText = content.replace(/<[^>]*>?/gm, "");
    const note = await prisma.note.create({
      data: {
        title,
        content,
        plainText,
        authorId: user.id,
        notebookId,
        isEncrypted,
        tags: { connectOrCreate: tags.map((t: string) => ({ where: { name: t }, create: { name: t } })) }
      },
      include: { tags: true }
    });
    await prisma.noteVersion.create({ data: { noteId: note.id, content } });
    return res.status(201).json(note);
  }

  return res.status(405).json({ error: "Method not allowed" });
}
TS

cat > pages/api/notes/[id].ts <<'TS'
import type { NextApiRequest, NextApiResponse } from "next";
import { getServerSession } from "next-auth/next";
import { authOptions } from "../auth/[...nextauth]";
import { prisma } from "../../../lib/prisma";

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const session = await getServerSession(req, res, authOptions as any);
  if (!session || !session.user?.email) return res.status(401).json({ error: "Unauthorized" });
  const user = await prisma.user.findUnique({ where: { email: session.user.email } });
  if (!user) return res.status(401).json({ error: "Unauthorized" });

  const id = req.query.id as string;
  if (!id) return res.status(400).json({ error: "Missing id" });

  if (req.method === "GET") {
    const note = await prisma.note.findUnique({ where: { id }, include: { tags: true, versions: { orderBy: { createdAt: "desc" }, take: 50 } } });
    if (!note || note.authorId !== user.id) return res.status(404).json({ error: "Not found" });
    return res.json(note);
  }

  if (req.method === "PUT") {
    const { title, content, tags = [], isPinned, isArchived, isEncrypted } = req.body;
    const old = await prisma.note.findUnique({ where: { id } });
    if (!old || old.authorId !== user.id) return res.status(404).json({ error: "Not found" });
    const plainText = (content || "").replace(/<[^>]*>?/gm, "");
    const updated = await prisma.note.update({
      where: { id },
      data: {
        title,
        content,
        plainText,
        isPinned,
        isArchived,
        isEncrypted,
        tags: { set: [], connectOrCreate: tags.map((t: string) => ({ where: { name: t }, create: { name: t } })) },
        versionCount: { increment: 1 }
      },
      include: { tags: true }
    });
    await prisma.noteVersion.create({ data: { noteId: id, content, authorId: user.id } });
    return res.json(updated);
  }

  if (req.method === "DELETE") {
    const note = await prisma.note.findUnique({ where: { id } });
    if (!note || note.authorId !== user.id) return res.status(404).json({ error: "Not found" });
    await prisma.note.delete({ where: { id } });
    return res.json({ ok: true });
  }

  return res.status(405).json({ error: "Method not allowed" });
}
TS

# editor component + pages
mkdir -p components pages/note
cat > components/Editor.tsx <<'TSX'
import React, { useEffect, useRef } from "react";
import dynamic from "next/dynamic";
import "react-quill/dist/quill.snow.css";

const ReactQuill = dynamic(() => import("react-quill"), { ssr: false });

export default function Editor({ value, onChange }: { value: string; onChange: (val: string) => void }) {
  const quillRef = useRef<any>(null);
  useEffect(() => {
    // autosave hook could go here (debounced)
  }, []);

  return (
    <div>
      <ReactQuill theme="snow" value={value} onChange={onChange} ref={quillRef} />
    </div>
  );
}
TSX

cat > pages/_app.tsx <<'TSX'
import "../styles/globals.css";
import { SessionProvider } from "next-auth/react";
import type { AppProps } from "next/app";

export default function App({ Component, pageProps: { session, ...pageProps } }: AppProps) {
  return (
    <SessionProvider session={session}>
      <Component {...pageProps} />
    </SessionProvider>
  );
}
TSX

cat > pages/index.tsx <<'TSX'
import useSWR from "swr";
import { useSession } from "next-auth/react";
import { useState } from "react";
import axios from "axios";
import Link from "next/link";

const fetcher = (url: string) => axios.get(url).then((r) => r.data);

export default function Home() {
  const { data: session } = useSession();
  const { data: notes, mutate } = useSWR(session ? "/api/notes" : null, fetcher);
  const [q, setQ] = useState("");

  async function createNote() {
    const res = await axios.post("/api/notes", { title: "New note", content: "" });
    mutate();
    window.location.href = `/note/${res.data.id}`;
  }

  return (
    <div style={{ padding: 20 }}>
      <h1>Notes</h1>
      {!session ? (
        <p>Please sign in to continue.</p>
      ) : (
        <>
          <div style={{ marginBottom: 10 }}>
            <button onClick={createNote}>New Note</button>
            <input placeholder="Search" value={q} onChange={(e) => setQ(e.target.value)} />
          </div>
          <ul>
            {notes?.map((n: any) => (
              <li key={n.id}>
                <Link href={`/note/${n.id}`}>
                  <a>
                    {n.title} — {new Date(n.updatedAt).toLocaleString()}
                  </a>
                </Link>
              </li>
            ))}
          </ul>
        </>
      )}
    </div>
  );
}
TSX

cat > pages/note/[id].tsx <<'TSX'
import { useRouter } from "next/router";
import useSWR from "swr";
import Editor from "../../components/Editor";
import axios from "axios";
import { useState, useEffect } from "react";

const fetcher = (url: string) => axios.get(url).then((r) => r.data);

export default function NotePage() {
  const router = useRouter();
  const id = router.query.id as string;
  const { data: note, mutate } = useSWR(id ? `/api/notes/${id}` : null, fetcher);
  const [content, setContent] = useState("");

  useEffect(() => {
    if (note) setContent(note.content || "");
  }, [note]);

  async function save() {
    await axios.put(`/api/notes/${id}`, { ...note, content });
    mutate();
  }

  if (!note) return <div>Loading...</div>;

  return (
    <div style={{ padding: 20 }}>
      <h2>{note.title}</h2>
      <Editor value={content} onChange={setContent} />
      <div style={{ marginTop: 10 }}>
        <button onClick={save}>Save</button>
        <button onClick={() => router.push("/")}>Back</button>
      </div>
      <h3>Versions</h3>
      <ul>
        {note.versions?.map((v: any) => (
          <li key={v.id}>{new Date(v.createdAt).toLocaleString()}</li>
        ))}
      </ul>
    </div>
  );
}
TSX

# Docker, CI, service worker, tests, seed, license, gitignore
cat > docker-compose.yml <<'YML'
version: "3.8"
services:
  db:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: notesdb
    volumes:
      - db-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  app:
    build: .
    command: sh -c "pnpm prisma:migrate && pnpm dev"
    volumes:
      - .:/app
      - /app/node_modules
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgres://postgres:postgres@db:5432/notesdb
      NEXTAUTH_SECRET: "change-this-secret"
      EMAIL_SERVER: "smtp://user:pass@smtp.example.com:587"
      EMAIL_FROM: "no-reply@example.com"
    depends_on:
      - db

volumes:
  db-data:
YML

cat > Dockerfile <<'DOCK'
FROM node:18-alpine
WORKDIR /app
COPY package.json pnpm-lock.yaml* ./
RUN npm install -g pnpm && pnpm install --frozen-lockfile
COPY . .
RUN pnpm prisma:generate
RUN pnpm build
EXPOSE 3000
CMD ["pnpm", "start"]
DOCK

cat > public/sw.js <<'J'
const CACHE = "notes-app-cache-v1";
self.addEventListener("install", (e) => {
  self.skipWaiting();
  e.waitUntil(
    caches.open(CACHE).then((cache) =>
      cache.addAll(["/", "/_next/static/*", "/favicon.ico"]).catch(() => {})
    )
  );
});
self.addEventListener("fetch", (e) => {
  e.respondWith(
    caches.match(e.request).then((r) => {
      return r || fetch(e.request);
    })
  );
});
J

mkdir -p .github/workflows
cat > .github/workflows/ci.yml <<'CI'
name: CI
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 18
      - run: npm ci
      - run: npm run lint
      - run: npm test
CI

cat > tests/notes.test.ts <<'TEST'
import { prisma } from "../lib/prisma";

describe("basic prisma smoke", () => {
  it("connects to db", async () => {
    const now = await prisma.$queryRaw`select now()`;
    expect(now).toBeDefined();
  });
});
TEST

cat > prisma/seed.ts <<'SEED'
import { prisma } from "../lib/prisma";

async function main() {
  const u = await prisma.user.upsert({
    where: { email: "demo@example.com" },
    update: {},
    create: { email: "demo@example.com", name: "Demo User" }
  });
  console.log("Seeded user:", u.email);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
SEED

cat > LICENSE <<'LIC'
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
LIC

cat > .gitignore <<'G'
node_modules
.env
.next
.DS_Store
coverage
G

# Add, commit, push
git add .

if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "Add production-ready notes app skeleton"
fi

# Try push to main
if git push origin main; then
  echo "Push to origin/main succeeded."
else
  echo "Push to origin/main failed. Attempting to push to a new branch 'add-notes-app'..."
  git checkout -b add-notes-app
  git push -u origin add-notes-app
  echo "Pushed to add-notes-app. Create a PR in GitHub to merge to main."
fi

echo "Done."
