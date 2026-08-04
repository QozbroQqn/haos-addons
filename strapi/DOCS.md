# Documentation

Welcome to the Strapi Home Assistant Add-on documentation. This guide provides detailed information on how to configure, use, and customize your Strapi installation.

## Table of Contents

- [Getting Started](#getting-started)
- [Persistence & Directory Structure](#persistence--directory-structure)
- [Managing Secrets](#managing-secrets)
- [Development & Customization](#development--customization)
- [Networking & Ingress](#networking--ingress)
- [Troubleshooting](#troubleshooting)

## Getting Started

After installing the add-on, click **Start**. The first boot will take several minutes as it bootstraps a fresh Strapi installation and installs dependencies.

Once started, you can access the Strapi Admin panel via the **Open Web UI** button or the **Ingress** link in the sidebar (if enabled).

## Persistence & Directory Structure

To allow easy editing of your Strapi project, this add-on synchronizes key files between the internal container storage and your Home Assistant `/config/` directory (accessible via Samba or File Editor). The Strapi project is installed in `/config/strapi`, so there is no `/data/strapi` sync to maintain.

### Mapped Folders
- `/config/src/`: Your custom API, components, and frontend code.
- `/config/config/`: Strapi configuration files.
- `/config/database/`: Database migrations and seeds.
- `/config/public/uploads/`: All uploaded media files.
- `/config/package.json`: Project dependencies and metadata.
- `/config/package-lock.json`: Locked dependency versions.

### Key Files
- `/config/.env`: Environment variables and secrets.
- `/config/data.sqlite`: The SQLite database.

## Managing Secrets

Six secrets protect Strapi: `app_keys`, `api_token_salt`, `admin_jwt_secret`, `jwt_secret`, `transfer_token_salt`, `encryption_key`. They live in `/config/.env`, not in the add-on's Configuration UI.

### First Start

On the very first start, if `/config/.env` does not exist yet, the add-on creates it:
- Any secret field filled in under **Configuration** is copied into `.env` as-is (useful if you already have existing secrets you want to keep, e.g. when migrating from another instance).
- Every secret field left empty is replaced with a freshly generated random value.

### `.env` Is the Source of Truth Afterwards

Once `/config/.env` exists, it is never touched again on restart — the Configuration UI has **no effect** anymore, even if you change it there. All sessions, API tokens, and cookies are validated against `/config/.env` only.

### Rotating Secrets

For example after an accidental leak (e.g. a secret ending up in a log or a shared terminal):

1. In **Settings → Add-ons → Strapi → Configuration**, clear the fields you want to rotate (leave them empty).
2. Delete `/config/.env` from the add-on's persistent folder (back it up first if you're unsure).
3. Restart the add-on. A new `.env` is generated exactly as described under "First Start" above, using fresh random values for every field you cleared.
4. Log back in to the Strapi admin panel — the previous session is now invalid.
5. Re-create any API tokens under **Settings → API Tokens** — the old ones no longer validate — and update every consumer that stores one (e.g. a Home Assistant `secrets.yaml` entry).

`encryption_key` additionally protects any Strapi field or plugin data stored encrypted at rest. Only rotate it if you're sure nothing relies on the old value — otherwise that data becomes unreadable.

## Development & Customization

### Synchronization
The add-on uses a two-way synchronization strategy at startup to ensure both your manual edits and Strapi's automatic changes (like the Content-Type Builder) are preserved:
1. **Back-sync**: Files created or updated by Strapi inside the container (e.g., new APIs) are copied to your `/config/strapi` folder.
2. **Forward-sync**: Any manual edits you made in `/config/strapi` are then pushed into the container.

**Note1:** If you delete a file in `/config/strapi`, it will also be deleted inside the container upon the next restart.

**Note2:** You can develop directly inside `/config/strapi`. Strapi watches files in development mode and apllies changes automatically

### Node Environment
- **Development**: Runs `npm run dev`. This mode is useful for debugging and creating new content types. Note that `--no-watch-admin` is used, so HMR is disabled for the admin panel.
- **Production**: Runs `npm run start` after a clean build. Use this for better performance once your project is stable.

### Installing Plugins
You can install Strapi plugins from the marketplace by adding the package names to the `plugins` field in the add-on configuration.
The package name can be found via the **copy install command** button. If you click it, you get a command like this: `npm install plugin-name`.
The part after `npm install` is the package name.

Example configuration:
```yaml
plugins:
  - "@strapi/plugin-documentation"
  - "@strapi/plugin-graphql"
```
The add-on will automatically run `npm install` for these packages and rebuild Strapi upon the next restart.

### Applying Changes
You must **restart the add-on** manually to apply changes made to files in the `/config/` directory. If you created a new Collection Type in the UI, restarting the add-on will ensure those generated files are safely moved to your persistent `/config/strapi` folder.

## Networking & Ingress

- **Ingress**: Allows secure access to the Strapi Admin panel directly from the Home Assistant sidebar without exposing ports.
- **Public URL**: Automatically detected, but can be overridden in the configuration if you use a custom domain or reverse proxy.

## Troubleshooting

- **Watchdog Restarts**: Building the Strapi admin panel is resource-intensive. If your addon restarts repeatedly during the "Building admin panel" phase, it is likely the Home Assistant Watchdog killing the process because it hasn't responded yet.
  - In production, you can deactivate the watchdog until the build is complete.
  - In development, build times are even longer and you should deactivate the watchdog entirely.
- **First Start Fails**: Check the logs. Bootstrapping requires an internet connection to download Strapi and its dependencies.
- **Changes Not Appearing**: Ensure you have restarted the add-on after editing files in the `/config/` directory.
- **Port Conflicts**: If port `1337` is already in use, you can change the port mapping in the **Network** tab of the add-on settings.
