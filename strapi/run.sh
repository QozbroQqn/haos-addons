#!/usr/bin/with-contenv bashio

set -euo pipefail

STRAPI_DIR="/config"

NODE_ENV=$(bashio::config 'node_env')
SERVE_ADMIN=$(bashio::config 'serve_admin')
USE_INGRESS=$(bashio::addon.ingress)

# For internal docker environment. No sense in making changes
HOST=0.0.0.0
PORT=1337
PROXY=true

# Secrets settings
gen_secret() {
  head -c 32 /dev/urandom | od -An -tx1 -v | tr -d ' \n' | head -c 64
}

MAX_REFRESH_TOKEN_LIFESPAN=$(bashio::config 'max_refresh_token_lifespan')
MAX_SESSION_LIFESPAN=$(bashio::config 'max_session_lifespan')

# Default to 7 and 30 days if 0 or not set
if [ "${MAX_REFRESH_TOKEN_LIFESPAN}" -le 0 ]; then MAX_REFRESH_TOKEN_LIFESPAN=7; fi
if [ "${MAX_SESSION_LIFESPAN}" -le 0 ]; then MAX_SESSION_LIFESPAN=30; fi

# Convert days to milliseconds
MAX_REFRESH_TOKEN_LIFESPAN_MS=$((MAX_REFRESH_TOKEN_LIFESPAN * 24 * 60 * 60 * 1000))
MAX_SESSION_LIFESPAN_MS=$((MAX_SESSION_LIFESPAN * 24 * 60 * 60 * 1000))

APP_KEYS=$(bashio::config 'app_keys')
if [ -z "${APP_KEYS}" ]; then APP_KEYS="$(gen_secret),$(gen_secret),$(gen_secret),$(gen_secret)"; fi
API_TOKEN_SALT=$(bashio::config 'api_token_salt')
if [ -z "${API_TOKEN_SALT}" ]; then API_TOKEN_SALT="$(gen_secret)"; fi
ADMIN_JWT_SECRET=$(bashio::config 'admin_jwt_secret')
if [ -z "${ADMIN_JWT_SECRET}" ]; then ADMIN_JWT_SECRET="$(gen_secret)"; fi
JWT_SECRET=$(bashio::config 'jwt_secret')
if [ -z "${JWT_SECRET}" ]; then JWT_SECRET="$(gen_secret)"; fi
TRANSFER_TOKEN_SALT=$(bashio::config 'transfer_token_salt')
if [ -z "${TRANSFER_TOKEN_SALT}" ]; then TRANSFER_TOKEN_SALT="$(gen_secret)"; fi
ENCRYPTION_KEY=$(bashio::config 'encryption_key')
if [ -z "${ENCRYPTION_KEY}" ]; then ENCRYPTION_KEY="$(gen_secret)"; fi

# Database settings
DATABASE_CLIENT=sqlite
DATABASE_FILENAME="${STRAPI_DIR}/data.sqlite"
DATABASE_DIR="$(dirname "${DATABASE_FILENAME}")"

mkdir -p "${STRAPI_DIR}/public/uploads" "${DATABASE_DIR}"

# Early diagnostics
bashio::log.info "-------------------------------------------------------"
bashio::log.info "Strapi add-on starting..."
bashio::log.info "NODE_ENV=${NODE_ENV}"
bashio::log.info "HOST=${HOST}"
bashio::log.info "PORT=${PORT}"
bashio::log.info "DATABASE_CLIENT=${DATABASE_CLIENT}"
bashio::log.info "USE_INGRESS=${USE_INGRESS}"
bashio::log.info "-------------------------------------------------------"
if command -v node >/dev/null 2>&1; then node -v || true; fi
if command -v npm >/dev/null 2>&1; then npm -v || true; fi

# Determine the actual PUBLIC_URL to use
USER_URL=$(bashio::config 'url')
if [ "${USE_INGRESS}" = "true" ]; then
    PUBLIC_URL="$(bashio::addon.ingress_entry)"
    bashio::log.info "Ingress detected. Setting PUBLIC_URL to: ${PUBLIC_URL}"
elif [ -n "${USER_URL}" ] && [ "${USER_URL}" != "null" ]; then
    PUBLIC_URL="${USER_URL}"
    bashio::log.info "Using custom User URL: ${PUBLIC_URL}"
else
    PUBLIC_URL="http://homeassistant.local:1337"
    bashio::log.info "Using default fallback URL: ${PUBLIC_URL}"
fi

# Bootstrap Strapi app on first run under ${STRAPI_DIR}
if [ ! -f "${STRAPI_DIR}/package.json" ]; then
  bashio::log.info "Bootstrapping Strapi app under ${STRAPI_DIR} (this may take a while)"

  export CI=true STRAPI_TELEMETRY_DISABLED=true
  export npm_config_loglevel=${npm_config_loglevel:-warn}

  # FIXME: https://github.com/strapi/strapi/issues/24293
  # Unfortunately we have to do "... yes '' | npx ..." for now
  yes '' | npx --yes create-strapi@latest "${STRAPI_DIR}" \
               --ts --skip-db --skip-cloud --install --no-run --no-example --no-git-init --use-npm \
               2>&1 || true
      
  if [ ! -f "$STRAPI_DIR/package.json" ]; then
    bashio::log.error "Failed to install Strapi"
    exit 1
  fi
  
  # Configure admin to honor SERVE_ADMIN env and Ingress admin URL if set
  cat > "${STRAPI_DIR}/config/admin.ts" <<EOF
export default ({ env }) => ({
  auth: { 
    secret: env('ADMIN_JWT_SECRET'),
    sessions: {
      maxRefreshTokenLifespan: env.int('MAX_REFRESH_TOKEN_LIFESPAN_MS', 604800000),
      maxSessionLifespan: env.int('MAX_SESSION_LIFESPAN_MS', 2592000000),
    }
  },
  apiToken: { salt: env('API_TOKEN_SALT') },
  serveAdminPanel: env.bool('SERVE_ADMIN'),
  transfer: { token: { salt: env('TRANSFER_TOKEN_SALT') } },
  secrets: { encryptionKey: env('ENCRYPTION_KEY') },
  watchIgnoreFiles: [ '**/data.sqlite' ],
});
EOF
  
  # Configure database to bind sqlite file location outside of project
  cat > "${STRAPI_DIR}/config/database.ts" <<EOF
export default ({ env }) => ({
  connection: {
    client: env('DATABASE_CLIENT', 'sqlite'),
    connection: { filename: env('DATABASE_FILENAME', '${DATABASE_FILENAME}') },
    useNullAsDefault: true,
    acquireConnectionTimeout: env.int('DATABASE_CONNECTION_TIMEOUT', 60000),
  },
});
EOF

  # Create the Vite configuration to allow all hosts. Communication without it could fail otherwise.
  bashio::log.info "Configuring Vite to allow all hosts..."
  cat > "${STRAPI_DIR}/src/admin/vite.config.ts" <<EOF
import { mergeConfig, type UserConfig } from 'vite';

export default (config: UserConfig) => {
  return mergeConfig(config, {
    server: {
        allowedHosts: true,
    },
  });
};
EOF
fi

# Ensure .env exists in /config
if [ ! -f "${STRAPI_DIR}/.env" ]; then
    bashio::log.info "Initializing .env in ${STRAPI_DIR}..."
    cat > "${STRAPI_DIR}/.env" <<EOF
# Server
HOST=${HOST}
PORT=${PORT}
NODE_ENV=${NODE_ENV}
URL=${PUBLIC_URL}
PROXY=${PROXY}
SERVE_ADMIN=${SERVE_ADMIN}

# Secrets
APP_KEYS=${APP_KEYS}
API_TOKEN_SALT=${API_TOKEN_SALT}
ADMIN_JWT_SECRET=${ADMIN_JWT_SECRET}
JWT_SECRET=${JWT_SECRET}
TRANSFER_TOKEN_SALT=${TRANSFER_TOKEN_SALT}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
MAX_REFRESH_TOKEN_LIFESPAN=${MAX_REFRESH_TOKEN_LIFESPAN_MS}
MAX_SESSION_LIFESPAN=${MAX_SESSION_LIFESPAN_MS}

# Database
DATABASE_CLIENT=${DATABASE_CLIENT}
DATABASE_FILENAME=${DATABASE_FILENAME}

# Other
STRAPI_TELEMETRY_DISABLED=true
EOF
fi

# Install dependencies if needed
if [ -z "$(ls -A "${STRAPI_DIR}/node_modules" 2>/dev/null)" ]; then
  bashio::log.info "Installing Strapi dependencies"
  
  cd "${STRAPI_DIR}"
  npm install --no-audit --no-fund
fi

# Install requested plugins
if bashio::config.has_value 'plugins'; then
    bashio::log.info "Checking for additional plugins to install..."
    cd "${STRAPI_DIR}"
    for plugin in $(bashio::config 'plugins'); do
        bashio::log.info "Installing plugin: ${plugin}"
        npm install "${plugin}" --no-audit --no-fund || bashio::log.error "Failed to install plugin: ${plugin}"
    done
fi

# Build Strapi
cd "${STRAPI_DIR}"
if [ "${NODE_ENV}" = "production" ]; then
  bashio::log.info "Building Strapi for Production..."
  npm run build || bashio::log.warning "Build failed; attempting to continue"
else
  bashio::log.info "Skipping explicit build in development mode (npm run dev handles this)"
fi

bashio::log.notice "-------------------------------------------------------"
bashio::log.notice "Environment variables created in your addon data folder usually /addon_configs/strapi"
bashio::log.notice "If you lose them, strapi wont work anymore and need to be rebuilded."
bashio::log.warning "You have to copy the secrets from the created environment variables to the addon config or they are regenerated everytime strapi starts. See addon README for more details."
bashio::log.notice "Keep in mind that all sessions, API tokens or other secrets related stuff become invalid."
bashio::log.notice "As long as strapi can start up and the database is still present, you will be able to login to the admin."
bashio::log.notice "-------------------------------------------------------"

bashio::log.info "Starting Strapi on ${HOST}:${PORT} (DATABASE_CLIENT=${DATABASE_CLIENT}; ENV=${NODE_ENV})"
cd "${STRAPI_DIR}"
if [ "${NODE_ENV}" = "production" ]; then
  exec npm run start
else
  exec npm run dev -- --no-watch-admin
fi

# for debugging only. prevents container from being stopped
# sleep infinity
