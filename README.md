# MyManager

Phase 1 implementation for a simplified and scalable project and task management system.

## Tech Stack
- Frontend: Next.js (App Router), TypeScript, Tailwind CSS, Zustand
- Backend: Node.js, Express.js, TypeScript
- Database: MySQL
- ORM: Prisma

## Quick Start

### 1) Backend
1. Go to backend folder
2. Copy .env.example to .env
3. Set DATABASE_URL (password contains @ so it is URL-encoded as %40 in the example)
4. Run:
   - npm install
   - npm run prisma:generate
   - npm run prisma:migrate
   - npm run prisma:seed
   - npm run dev

### 2) Frontend
1. Go to frontend folder
2. Run:
   - npm install
   - npm run dev

## Phase 1 Deliverables
- Prisma schema with relations and soft delete fields
- CRUD REST APIs for masters, projects, tasks, and subtasks
- Validation schemas and DTOs
- Centralized error middleware
- Seed data
- Basic responsive dashboard UI

See docs in:
- docs/phase-1-structure.md
- backend/docs/api-routes.md
- backend/docs/mysql-table-structure.sql
