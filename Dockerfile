FROM node:20-alpine AS base
RUN apk update && apk upgrade --no-cache libcrypto3 libssl3

#RUN apk update && apk upgrade --no-cache libcrypto3
#RUN apk update && apk upgrade --no-cache libcrypto3 libssl3 libc6-compat

FROM base AS deps
#RUN apk add --no-cache 

WORKDIR /app

COPY package-lock.json ./
COPY package.json ./
RUN npm ci

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build

FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000

ENV HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]
