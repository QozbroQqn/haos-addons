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

To allow easy editing of your Strapi project, this add-on synchronizes key files between the internal container storage and your Home Assistant `/config/` directory (accessible via Samba or File Editor).

### Mapped Folders
- `/config/src/`: Your custom API, components, and frontend code.
- `/config/config/`: Strapi configuration files.
- `/config/database/`: Database migrations and seeds.
- `/config/public/uploads/`: All uploaded media files.

### Key Files
- `/config/.env`: Environment variables and secrets.
- `/config/data.sqlite`: The SQLite database.

## Managing Secrets

The add-on generates secure defaults for all Strapi secrets on the first start. These are stored in `/config/.env`.

**Important:**
- The `.env` file in the `/config/` directory is the **Source of Truth** after the first run.
- To change secrets later, edit `/config/.env` directly and restart the add-on.

## Development & Customization

### Synchronization
On every start, the add-on syncs changes from your `/config/` directory to the internal execution directory.

### Node Environment
- **Development**: Runs `npm run dev`. This mode is useful for debugging and creating new content types. Note that `--no-watch-admin` is used, so HMR is disabled for the admin panel.
- **Production**: Runs `npm run start` after a clean build. Use this for better performance once your project is stable.

### Applying Changes
You must **restart the add-on** manually to apply changes made to files in the `/config/` directory.

## Networking & Ingress

- **Ingress**: Allows secure access to the Strapi Admin panel directly from the Home Assistant sidebar without exposing ports.
- **Public URL**: Automatically detected, but can be overridden in the configuration if you use a custom domain or reverse proxy.

## Troubleshooting

- **First Start Fails**: Check the logs. Bootstrapping requires an internet connection to download Strapi and its dependencies.
- **Changes Not Appearing**: Ensure you have restarted the add-on after editing files in the `/config/` directory.
- **Port Conflicts**: If port `1337` is already in use, you can change the port mapping in the **Network** tab of the add-on settings.
