# MyManager Backend

Layered Express + TypeScript + Prisma backend.

## Setup

1. Copy .env.example to .env
2. Update DATABASE_URL
3. Set GOOGLE_CLIENT_ID and JWT_ACCESS_SECRET
4. Run npm install
5. Run npm run prisma:generate
6. Run npm run prisma:migrate
7. Run npm run prisma:seed
8. Run npm run dev

## Access From Another System (LAN)

1. In .env, set HOST=0.0.0.0 and keep PORT=5000 (or your preferred port)
2. If the caller is a browser app, add that app origin in FRONTEND_URL as comma-separated values
3. Start backend with npm run dev
4. From the second system, call:
	- http://<backend-machine-ip>:5000/health
	- http://<backend-machine-ip>:5000/api/v1/...

Example:
- Backend machine IP: 192.168.0.233
- Health URL: http://192.168.0.233:5000/health

Windows firewall note:
- Allow inbound TCP on your backend PORT (default 5000), otherwise other systems on the network cannot connect.
