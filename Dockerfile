FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install dependencies
RUN npm install -g create-strapi-app

# Create Strapi app (production build)
RUN create-strapi-app strapi-app --quickstart

WORKDIR /app/strapi-app

EXPOSE 1337

CMD ["npm", "run", "develop"]
