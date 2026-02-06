FROM node:18-alpine

# Set base directory
WORKDIR /app

# Install Strapi CLI
RUN npm install -g create-strapi-app

# Create Strapi app (non-interactive)
RUN create-strapi-app strapi-app --quickstart --no-run

# Move into Strapi app directory
WORKDIR /app/strapi-app

# Install dependencies
RUN npm install

# Build Strapi for production (THIS WAS FAILING BEFORE)
RUN npm run build

# Expose Strapi port
EXPOSE 1337

# Run Strapi in production mode
CMD ["npm", "start"]
