# Use official Node.js LTS image
FROM node:18

# Set working directory inside the container
WORKDIR /app

# Copy package files separately for better layer caching
COPY app/package*.json ./

# Install only production dependencies (omit dev deps)
#RUN npm install --production
RUN npm install

# Copy the rest of the app
COPY app/ ./

# Expose the port your app runs on
EXPOSE 3000

# Run the application
CMD ["node", "index.js"]
