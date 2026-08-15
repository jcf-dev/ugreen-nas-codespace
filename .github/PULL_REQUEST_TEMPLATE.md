## Summary

<!-- What changed, and why? -->

## Verification

- [ ] `docker compose -f docker-compose.yml -f compose/build.yml config --quiet`
- [ ] Image builds successfully
- [ ] Container becomes healthy and the browser login works
- [ ] `make verify` passes

Tested architecture(s):

<!-- linux/amd64, linux/arm64, or static validation only -->

## Security and compatibility

- [ ] No credentials, personal paths, tokens, or private hostnames are included
- [ ] Documentation and `.env.example` reflect new configuration
- [ ] Default deployment does not expose the Docker socket or disable auth
