#!/bin/bash
set -e

# This script ensures the pgvector extension is available
# The pgvector/pgvector image already includes the extension,
# but this script can be used for additional setup if needed

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Enable the vector extension (will be done in migration, but ensuring it's available)
    -- CREATE EXTENSION IF NOT EXISTS vector;
    
    -- Create any additional configurations here
    SELECT 'Database initialized successfully' as status;
EOSQL
