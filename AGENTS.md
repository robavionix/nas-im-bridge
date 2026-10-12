# Public project rules

- This is nas-im-bridge, an independent project derived from nas-chat-mobile 0.5.4. Preserve MIT attribution. Keep the original project and live deployments unchanged unless the user requests changes there.
- Keep the neutral name and generic phone icon. Never commit official client logos, penguins, private parody icons or private screenshots. Client names in adapters and compatibility docs are descriptive only.
- Never commit deployment addresses, tunnel origins, credentials, account data, session keys, push subscriptions, certificates or private keys. Use example.com and generic example IPs in documentation.
- Setup defaults to QQ, builds natively on amd64 / arm64 and writes to a separate directory. Do not overwrite existing deployments or redistribute client packages.
- Preserve Retina drawing, touch mapping, composited scrolling, conversation guards and send idempotency.
- Run relevant Python and JavaScript tests. Deployment changes also require tests/test_deploy.sh, tests/test_lan.sh, shell syntax and Compose validation.
- Inspect exact tracked files for private data before publishing. Retain neutral public icon assets.
