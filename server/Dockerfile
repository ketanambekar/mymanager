FROM node:22-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates openssl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY prisma ./prisma
COPY tsconfig.json ./
COPY src ./src

RUN npm run build

ARG APP_VERSION=dev
ARG GIT_COMMIT=unknown
ARG BUILD_TIME=
LABEL org.opencontainers.image.title="mymanager-api" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.created="${BUILD_TIME}"
ENV GIT_COMMIT=${GIT_COMMIT} \
    BUILD_TIME=${BUILD_TIME}

ENV NODE_ENV=production
EXPOSE 5000

CMD ["sh", "-c", "npm run db:deploy && node dist/src/server.js"]