# Changelog

## 1.2.1
- Removed the obsolete `create-strapi` bootstrap workaround in `run.sh`. The
  upstream AB-testing prompt that required piping `yes ''` into the CLI was
  removed (strapi/strapi#24293), so the scaffolding command now runs directly.

# 1.2.0

Thats a breaking change disguised as a minor version bump.
**Please backup your data! Dont forget the database!**

- Changed Strapi installation location to `/config`, removing the need to sync with `/data/strapi`.

#### Migration guide:
- If you havent changed any files, you can skip migration
- stop addon
- backup all files from /addon_configs/<your-strapi-folder> (copy them somewhere)
- uninstall addon entirely with data
- install addon again and wait if it installs and runs fine
- stop addon -> copy files back -> start addon

## 1.1.0
- Added `plugins` configuration field to allow installing npm packages/plugins from the marketplace.
- Added persistence for `package.json` and `package-lock.json` in the user configuration directory.
- Updated documentation with plugin installation instructions and persistence details.
- Improved startup synchronization logic between container and persistent storage.

## 1.0.0
- Initial release of the Strapi add-on for Home Assistant.
- Automatic Strapi bootstrapping on first run.
- Persistent storage for source code, configuration, and SQLite database.
- Integrated secret generation and management via `.env`.
- Support for both Development and Production environments.
