#!/bin/bash

# set -euo pipefail

# Load environment variables from .env file if present
if [ -f .env ]; then
  export $(awk 'NF && $1 !~ /^#/ {print $1}' .env | xargs)
fi

# Ensure the DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "DATABASE_URL is not set. Please set it first."
    exit 1
fi

# Strip the schema query parameter for psql connection
DATABASE_URL_NO_SCHEMA=$(echo $DATABASE_URL | sed 's/\?schema=.*//')

if [ ! -d "prisma/migrations" ]; then
    mkdir -p prisma/migrations
fi

touch prisma/migrations/migration.sql
# Capture the diff output and exit code from Prisma migrate diff
MODIFIED=$(npx prisma migrate diff --from-url "$DATABASE_URL_NO_SCHEMA" --to-schema-datamodel prisma/schema.prisma --script > prisma/migrations/migration.sql --exit-code)
MODIFIED=$?

# Output MODIFIED value for debugging
echo "MODIFIED value: $MODIFIED"

# Use MODIFIED value in your conditional logic
if [ $MODIFIED -eq 2 ]; then
    # Your code here for when MODIFIED is not empty
    # Generate a unique timestamped folder name for the migration
    TIMESTAMP=$(date +%s)
    BASELINE_DIR="prisma/migrations/${TIMESTAMP}_"
    mkdir -p ${BASELINE_DIR}
    mv prisma/migrations/migration.sql ${BASELINE_DIR}/migration.sql
    # npx prisma migrate resolve --applied "${TIMESTAMP}_"

    # Deploy migrations and handle errors
    if ! npx prisma migrate deploy; then
        echo 'Migration deployment failed, attempting to resolve conflicts...'
        # If migration fails due to existing types or tables, mark as resolved and continue
        npx prisma migrate resolve --applied $(ls -t prisma/migrations | head -n 1)
        if ! npx prisma migrate deploy; then
            exit 1;
        fi
        echo 'Migrations deployed successfully.'
    fi

    # Generate Prisma Client
    npm run db:generate
elif [ $MODIFIED -eq 0 ]; then
    # Your code here for when MODIFIED is empty
    echo "Migration diff is empty."
    rm prisma/migrations/migration.sql
else
    # Handle error case (MODIFIED == 1)
    echo "Error occurred during migration diff."
    rm prisma/migrations/migration.sql
    exit 1
fi