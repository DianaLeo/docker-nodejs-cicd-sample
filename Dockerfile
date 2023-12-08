# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

ARG NODE_VERSION=18.16.0

FROM node:${NODE_VERSION}-alpine as base
WORKDIR /usr/src/app
EXPOSE 3000

# development stage
FROM base as dev
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --include=dev
USER node
COPY . .
CMD npm run dev



# production stage
FROM base as prod
ENV NODE_ENV production
# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.npm to speed up subsequent builds.
# Leverage a bind mounts to package.json and package-lock.json to avoid having to copy them into
# into this layer.
# omit devDependencies
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev
# Run the application as a non-root user.
USER node
# Copy the rest of the source files into the image.
COPY . .
# Run the application.
CMD node src/index.js




# test stage
FROM base as test
ENV NODE_ENV test
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --include=dev
USER node
COPY . .
# Instead of using CMD in the test stage, use RUN to run the tests. 
# The reason is that the CMD instruction runs when the container runs, 
# and the RUN instruction runs when the image is being built
# and the build will fail if the tests fail.
RUN npm run test