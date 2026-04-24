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
