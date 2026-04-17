# Render vs Vercel: Pricing, Performance, and the Features That Actually Matter

Companion code for the Autonoma blog post 'Render vs Vercel: Pricing, Performance, and the Features That Actually Matter'. A GitHub Actions workflow that wires Render Pull Request Previews to Autonoma E2E testing — extracts the preview URL from Render's deploy event and triggers Autonoma tests against it.

> Companion code for the Autonoma blog post: **[Render vs Vercel: Pricing, Performance, and the Features That Actually Matter](https://getautonoma.com/blog/render-vs-vercel)**

## Requirements

GitHub Actions-enabled repository. Render account with Pull Request Previews enabled. Autonoma account with an API key.

## Quickstart

```bash
git clone https://github.com/Autonoma-Tools/render-vs-vercel.git
cd render-vs-vercel
1) In Render, configure a deploy webhook on your service to dispatch a repository_dispatch event to this repo with event_type 'render-deploy'. 2) Add AUTONOMA_API_KEY to your GitHub repository secrets. 3) Open a PR — the workflow fires on deploy success, grabs the preview URL, and runs Autonoma tests against it. Results post back as a status check on the PR.
```

## Project structure

```
.
├── .github/
│   └── workflows/
│       └── autonoma-render.yml
├── examples/
│   └── render-webhook-relay.sh
├── .gitignore
├── LICENSE
└── README.md
```

- `.github/workflows/` — the `autonoma-render.yml` GitHub Actions workflow that listens for Render deploy events and triggers Autonoma tests.
- `examples/` — runnable examples you can execute as-is (the Render → GitHub webhook relay lives here).

## About

This repository is maintained by [Autonoma](https://getautonoma.com) as reference material for the linked blog post. Autonoma builds autonomous AI agents that plan, execute, and maintain end-to-end tests directly from your codebase.

If something here is wrong, out of date, or unclear, please [open an issue](https://github.com/Autonoma-Tools/render-vs-vercel/issues/new).

## License

Released under the [MIT License](./LICENSE) © 2026 Autonoma Labs.
