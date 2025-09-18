# syntax=docker.io/docker/dockerfile:1

########## Base ##########
FROM node:20-alpine AS base

########## Deps ##########
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy lockfiles/config if present
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* .npmrc* ./

# Install (prefer lockfile)
# If you use yarn/pnpm, adapt accordingly (or we can auto-detect)
RUN if [ -f package-lock.json ]; then \
      echo "Using npm ci"; npm ci; \
    else \
      echo "No package-lock.json found, using npm install"; npm i --no-audit --no-fund; \
    fi

########## Build ##########
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Build with script if present, else fallback to standard build
RUN if npm run | grep -qE '^  build:docker'; then \
      echo "Running npm run build:docker"; npm run build:docker; \
    else \
      echo "build:docker not found, running npm run build"; npm run build; \
    fi

# Sanity check standalone output
# Next.js standalone produces server.js in .next/standalone
RUN test -f .next/standalone/server.js || (echo "ERROR: .next/standalone/server.js not found. Ensure Next.js standalone output is enabled."; ls -laR .next || true; exit 2)

########## Runtime ##########
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV HOSTNAME=0.0.0.0
ENV PORT=80

# Non-root user
RUN addgroup --system --gid 1001 nodejs \
 && adduser  --system --uid 1001 nextjs

# Static assets + standalone app
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 80

# Next standalone entry
CMD ["node", "server.js"]
