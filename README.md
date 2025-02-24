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

- [x] fix image drag styles in dark mode
- [x] add .env file parsing
- [ ] fix atom feed properties
- [ ] update dockerfile to account for env variables
- [x] create docker compose file
- [ ] audit themes and remove problematic ones
- [ ] audit themes and fix broken ones
- [ ] implement export option
  - [ ] this should be non-blocking; maybe fork a worker
- [ ] admin panel (use umhi?)
  - [ ] session + trustedIp ?
- [ ] add artist "feed" mode
- [ ] add archive page
- [ ] fix mobile styles
- [ ] add buttons to editor for mobile/accessibility reasons
- [ ] highlightjs audit
- [ ] option for date in post