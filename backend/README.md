# MyManager Backend

Production-ready backend for a Project Management / Task Management app.

## Tech Stack
- Node.js
- Express.js (MVC)
- MySQL
- Sequelize ORM
- JWT auth (access + refresh)
- Joi validation
- Umzug migrations

## Features
- Auth: register, login, logout, refresh token, bcrypt hashing
- Projects: CRUD, invite members, member list
- Kanban: boards, columns, task CRUD, task move, column reorder
- Comments: add/edit/delete/list
- File attachments: upload/download/delete
- Notifications: assignment, mentions, project invites
- Activity logs: task/project events
- Task filtering + pagination
- Security: helmet, CORS, rate limiting, morgan logging
- Soft deletes, indexes, FK constraints, transactions
- API versioning: `/api/v1`
- Swagger docs + Postman collection

## Folder Structure
```
src/
  controllers/
  services/
  repositories/
  models/
  routes/
  middlewares/
  validators/
  config/
  utils/
  database/
    migrations/
    seeders/
  docs/
```

## Environment Variables
Copy `.env.example` to `.env` and configure:
- `DB_HOST`
- `DB_USER`
- `DB_PASSWORD` (left blank; prompted interactively at runtime)
- `DB_NAME`
- `JWT_SECRET`

## Install
```bash
cd backend
npm install
```

## IMPORTANT: Interactive MySQL Password Prompt
Before database connection, backend asks in terminal:

`Please enter your MySQL password:`

The password is never hardcoded.

## Migrations
```bash
npm run db:migrate
npm run db:migrate:undo
npm run db:reset
```

## Seed Data
```bash
npm run db:seed
```
Creates:
- admin user: `admin@mymanager.local / Admin@123`
- demo project
- demo board + columns
- demo tasks

## Run Server
```bash
npm run dev
```

Base URL: `http://localhost:5000/api/v1`

## Docs
- Swagger UI: `http://localhost:5000/api-docs`
- Postman: `src/docs/postman_collection.json`
- DB schema: `src/docs/database_schema.md`

## Core Endpoints
- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/logout`
- `POST /auth/refresh`
- `POST /projects`
- `GET /projects`
- `GET /projects/:id`
- `POST /projects/:id/invite`
- `POST /tasks`
- `GET /tasks`
- `PUT /tasks/:id`
- `DELETE /tasks/:id`
- `PATCH /tasks/:id/move`
- `POST /tasks/:id/comments`
- `GET /tasks/:id/comments`
- `POST /tasks/:id/files`
- `GET /notifications`
- `GET /activity-logs`
