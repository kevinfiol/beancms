# Bean CMS

A micro-CMS built with [redbean](https://redbean.dev).

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

## TODO

- [ ] fix image drag styles in dark mode
- [ ] fix atom feed properties
- [ ] audit themes and remove problematic ones
- [ ] audit themes and fix broken ones
- [ ] add artist "feed" mode"
- [ ] add archive page
- [ ] add .env file parsing
- [ ] update dockerfile to account for env variables
- [ ] create docker compose file
