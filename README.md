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
- [x] fix atom feed properties
- [x] update dockerfile to account for env variables
- [x] create docker compose file
- [ ] audit themes and remove problematic ones
- [ ] audit themes and fix broken ones
- [ ] implement export option
  - [ ] this should be non-blocking; maybe fork a worker
- [x] admin panel (use umhi?)
  - [x] use trustedIp
  - [ ] add password protection
- [ ] add artist "feed" mode
- [ ] add archive page
- [ ] fix mobile styles
- [x] add buttons to editor for mobile/accessibility reasons
- [ ] highlightjs audit
- [ ] option for date in post
- [ ] keep track of who uploaded what image
- [ ] fullmoon: report bug about xml responses
- [ ] redbean: WSL, need to clear /WSLInterop-late as well 
