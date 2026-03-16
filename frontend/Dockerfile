# frontend/Dockerfile
# Stage 1 - Build React app
FROM node:18-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Set backend URL at build time - nginx proxies /api to backend service
ENV REACT_APP_BACKEND_URL=/api/tasks

RUN npm run build

# Stage 2 - Serve with nginx (lightweight production server)
FROM nginx:alpine

# Create non-root user - required by Kyverno policy
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -s /bin/sh -D appuser

# Copy built React app from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Fix permissions for non-root nginx
RUN chown -R appuser:appgroup /usr/share/nginx/html && \
    chown -R appuser:appgroup /var/cache/nginx && \
    chown -R appuser:appgroup /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown appuser:appgroup /var/run/nginx.pid

USER 1000

EXPOSE 3000
CMD ["nginx", "-g", "daemon off;"]