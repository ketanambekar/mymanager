# Phase 1 Structure

## Backend Folder Structure

backend/
- prisma/
  - schema.prisma
  - seed.ts
- src/
  - app.ts
  - server.ts
  - config/
    - env.ts
  - lib/
    - prisma.ts
  - middlewares/
    - errorMiddleware.ts
    - validateRequest.ts
  - routes/
    - index.ts
  - modules/
    - project-types/
    - priorities/
    - project-colors/
    - projects/
    - tasks/
    - subtasks/
  - utils/
    - appError.ts
    - asyncHandler.ts
  - types/
    - express.d.ts

Each module has:
- <module>.route.ts
- <module>.controller.ts
- <module>.service.ts
- <module>.repository.ts
- <module>.validation.ts
- <module>.dto.ts

## Frontend Folder Structure

frontend/
- src/
  - app/
    - layout.tsx
    - page.tsx
    - globals.css
  - components/
    - ui/
      - button.tsx
      - card.tsx
      - badge.tsx
    - dashboard/
      - sidebar.tsx
      - stats-cards.tsx
      - project-card.tsx
      - task-list.tsx
  - store/
    - dashboard-store.ts
  - lib/
    - utils.ts
  - types/
    - dashboard.ts

## Notes
- Backend architecture follows service-controller-repository.
- Soft delete is used in all main tables.
- Frontend uses Zustand for state and reusable ShadCN-style UI components.
