# Changelog

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
