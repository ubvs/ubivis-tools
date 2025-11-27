FROM node:20-bullseye

# Set the working directory
WORKDIR /workspace

# Install minimal system dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y \
    git \
    build-essential \
    python3 \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV NODE_ENV=development

# Expose common ports
EXPOSE 4200 3000 8080

# Set the default command
CMD ["sleep", "infinity"]
