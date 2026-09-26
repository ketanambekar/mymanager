# MyManager Coming Soon

A lightweight React landing page built with Vite.

## Run locally

```sh
npm install
npm run dev
```

## Deploy to Render

Create a **Static Site** connected to this repository, using the `main` branch. Render can read the build and publish settings from `render.yaml`; otherwise use:

- Build command: `npm install && npm run build`
- Publish directory: `dist`

After deploy, add `mymanager.in` and `www.mymanager.in` under the service's Custom Domains settings and configure the DNS records Render provides at your domain registrar. DNS changes can take time to propagate. Enable HTTPS in Render once the domain verifies.

The previous application is preserved on the `legacy` branch.