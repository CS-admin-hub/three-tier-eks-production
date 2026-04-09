# backend/Dockerfile 

FROM node:18-alpine 

  

# Non-root user — required by Kyverno disallow-root-user policy 

# UID 1001 because 1000 is taken in node:18-alpine 

RUN addgroup -g 1001 appgroup && \ 

    adduser -u 1001 -G appgroup -s /bin/sh -D appuser 

  

WORKDIR /app 

COPY package*.json ./ 

RUN npm install 

  

# --chown ensures appuser owns files (required for readOnlyRootFilesystem) 

COPY --chown=appuser:appgroup . . 

  

USER 1001 

EXPOSE 8080 

CMD ["node", "index.js"] 
