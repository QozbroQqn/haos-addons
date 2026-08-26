# Home Assistant Add-On: JDownloader

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield]

The add-on provides [JDownloader 2](https://jdownloader.org/) running as a
container inside your HAOS. It is based on
[jlesage/jdownloader-2](https://github.com/jlesage/docker-jdownloader-2),
which serves the desktop UI over noVNC.

## Download folder

`/share` is mapped read-write, and the add-on creates `/share/jdownloader` on
every start. The base image declares `/output` as a Docker volume, so it cannot
be redirected to the share — set the download folder once inside JDownloader:

**Settings → General → Default download folder → `/share/jdownloader`**

The setting is stored in `/config` and survives restarts and updates.

## MyJDownloader

Credentials are not add-on options on purpose — they would end up in plain text
in this repository. Enter them in the UI instead:

**Settings → My.JDownloader**

Port `3129` is declared for direct connections and is closed by default.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
