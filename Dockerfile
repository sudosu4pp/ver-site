FROM node:18-alpine AS BUILD_IMAGE

# Set the platform to build image for
ARG TARGETPLATFORM
ENV TARGETPLATFORM=${TARGETPLATFORM:-linux/amd64}

# Get environment variables
ARG NODE_ENV

# Install additional tools needed if on arm64 / armv7
RUN \
  case "${TARGETPLATFORM}" in \
  'linux/arm64') apk add --no-cache python3 make g++ ;; \
  'linux/arm/v7') apk add --no-cache python3 make g++ ;; \
  'linux/arm64/v8') apk add --no-cache python3 make g++ ;; \
  esac

# Create and set the working directory
WORKDIR /app

# Install app dependencies
COPY package.json package-lock.json ./
RUN npm install

# Copy over all project files and folders to the working directory
COPY . ./

# Build initial app for production
ENV DEPLOY_TARGET=NODE
RUN npm run build

# Production stage
FROM node:18-alpine

# Define some ENV Vars
ENV PORT=80 \
  DIRECTORY=/app \
  IS_DOCKER=true

# Create and set the working directory
WORKDIR ${DIRECTORY}

# Update tzdata for setting timezone
RUN apk add --no-cache tzdata

# Copy built application from build phase
COPY --from=BUILD_IMAGE /app ./

# Finally, run start command to serve up the built application
CMD [ "npm", "start" ]

# Expose the port
EXPOSE ${PORT}

# Run simple healthchecks every 5 mins, to check that everythings still great
HEALTHCHECK --interval=5m --timeout=5s --start-period=30s CMD yarn health-check
