# ---------------------------
# DEPENDENCIES STAGE
# ---------------------------
FROM node:20-bullseye AS deps
WORKDIR /app

# Enable corepack so you can use pnpm/yarn if desired
RUN corepack enable

# Install dependencies (choose your package manager)
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./

# npm
RUN if [ -f package-lock.json ]; then npm ci; fi
# pnpm
# RUN if [ -f pnpm-lock.yaml ]; then pnpm install --frozen-lockfile; fi
# yarn
# RUN if [ -f yarn.lock ]; then yarn install --frozen-lockfile; fi

# ---------------------------
# BUILD STAGE
# ---------------------------
FROM node:20-bullseye AS builder
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build Next.js with standalone output
RUN npm run build

# ---------------------------
# RUNTIME STAGE
# ---------------------------
FROM node:20-bullseye AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Copy standalone server and static assets
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# Default Next.js port
EXPOSE 3000
ENV PORT=3000

# Run the standalone Next.js server
CMD ["node", "server.js"]
