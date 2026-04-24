#!/bin/bash
set -euo pipefail

# Production Notes App generator
# Creates a Next.js 14 + NextAuth v4 + Prisma + PostgreSQL notes app.

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

cat > README.md << 'EOF'
# Production Notes App

A production-oriented notes application built with **Next.js 14 Pages Router**, **NextAuth v4**, **Prisma**, and **PostgreSQL**.

## Features

- Email magic-link authentication and optional GitHub OAuth
- Database-backed sessions with Prisma Adapter
- Rich-text notes with React Quill
- Note tags, pinned/archive state, revision history
- PostgreSQL full-text search query path
- Optional PostgreSQL GIN index installer for faster search
- Offline-aware service worker shell caching
- Dockerized local development
- TypeScript, ESLint, Jest, and GitHub Actions CI

## Quick Start With Docker

```bash
cp .env.example .env
docker compose up --build
