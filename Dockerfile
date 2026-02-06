FROM node:18-alpine

WORKDIR /app

# Install dependencies
RUN npm install -g create-strapi-app

# Create Strapi app
RUN create-strapi-app strapi-app --quickstart

WORKDIR /app/strapi-app

# Build Strapi for production
RUN npm run build

EXPOSE 1337

# IMPORTANT: run in production mode
CMD ["npm", "start"]