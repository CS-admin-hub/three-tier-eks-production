# # backend/Dockerfile
# FROM node:18-alpine

# # Create non-root user - required by Kyverno policy (disallow-root-user)
# RUN addgroup -g 1000 appgroup && \
#     adduser -u 1000 -G appgroup -s /bin/sh -D appuser

# WORKDIR /app

# # Copy package files first for better layer caching
# COPY package*.json ./
# RUN npm install

# # Copy source with correct ownership
# COPY --chown=appuser:appgroup . .

# # Switch to non-root user
# USER 1000

# EXPOSE 8080

# # index.js is at root of backend/ (not in src/)
# CMD ["node", "index.js"]


# backend/Dockerfile
FROM node:18-alpine

# Use GID 1001 - 1000 is already taken by node:18-alpine
RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -G appgroup -s /bin/sh -D appuser

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY --chown=appuser:appgroup . .

USER 1001

EXPOSE 8080
CMD ["node", "index.js"]