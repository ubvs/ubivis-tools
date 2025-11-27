-- Initialize Keycloak database
-- This script runs automatically when the PostgreSQL container starts

-- Create keycloak database if it doesn't exist
SELECT 'CREATE DATABASE keycloak'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'keycloak')\gexec

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE keycloak TO postgres;
