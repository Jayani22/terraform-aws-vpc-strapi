FROM node:18-alpine

WORKDIR /app

# Copy Strapi app source
COPY strapi-app ./strapi-app

WORKDIR /app/strapi-app

# Install dependencies
RUN npm install

# Build Strapi for production
RUN npm run build

EXPOSE 1337

# Run Strapi
CMD ["npm", "start"]