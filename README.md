# Bean CMS

A micro-CMS built with [redbean](https://redbean.dev).

## Installation

There are currently two ways to run Bean CMS.

### Executable

1. Download the latest release from the [Releases](https://github.com/kevinfiol/cms/releases) page.
2. On MacOS/Linux, make `beancms.com` executable with `chmod +x beancms.com`.
3. On Windows/MacOS/Linux, run `./beancms.com -D ./`.

Note: The `-D` flag is required for Bean CMS to be able to serve user uploaded images from the current directory.

### Docker

A Docker Compose file is included in the project. Currently, Bean CMS is not on Docker Hub.

Steps to run with Docker:
```bash
git clone https://github.com/kevinfiol/cms.git beancms
cd beancms
docker compose up -d
```

Note: Environment variables can be defined in `.env`. See `.env.defaults` for default values.

## Development

System dependencies required for building:

* `make`
* `zip`

Note: [watchexec](https://github.com/watchexec/watchexec) is required for `make watch` to work.

```bash
# download dev dependencies
make download

# run
make run

# or start service and watch for changes
make watch
```
