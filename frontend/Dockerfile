# frontend/Dockerfile 

# Stage 1: Build React app 

FROM node:18-alpine AS builder 

WORKDIR /app 

COPY package*.json ./ 

  

# Delete stale lock file — prevents ajv dependency conflicts with react-scripts 5.0.1 

# react-scripts 4.0.3 had webpack incompatible with Node 18 OpenSSL implementation 

RUN rm -f package-lock.json && npm install --force 

  

COPY . . 

ENV REACT_APP_BACKEND_URL=/api/tasks   

RUN npm run build 

  

# Stage 2: Serve with nginx 

FROM nginx:alpine 

  

# Non-root user — UID 1001 (1000 is taken in nginx:alpine) 

RUN addgroup -g 1001 appgroup && \ 

    adduser -u 1001 -G appgroup -s /bin/sh -D appuser 

  

COPY --from=builder /app/build /usr/share/nginx/html 

COPY nginx.conf /etc/nginx/conf.d/default.conf 

  

# Grant ownership of nginx runtime directories 

RUN chown -R appuser:appgroup /usr/share/nginx/html && \ 

    chown -R appuser:appgroup /var/cache/nginx && \ 

    chown -R appuser:appgroup /var/log/nginx && \ 

    touch /var/run/nginx.pid && \ 

    chown appuser:appgroup /var/run/nginx.pid 

  

USER 1001 

EXPOSE 3000 

CMD ["nginx", "-g", "daemon off;"]
