# MyManger

A React task workspace built with Vite. Tasks are currently saved in this browser; account sync and a backend are not connected yet.

## Run locally

```sh
npm --prefix client install
npm --prefix client run dev
```

To use the production API from `http://localhost:3000` without CORS errors, put this in `client/.env.local` (ignored by git):

```sh
VITE_API_BASE_URL=/api/v1
API_PROXY_TARGET=https://api.mymanger.in
```

The Vite dev server then proxies `/api` to production, so the browser makes same-origin requests and the refresh cookie stays first-party. To use a local backend instead, set `API_PROXY_TARGET=http://localhost:5000`. Google sign-in additionally requires `http://localhost:3000` to be an authorized JavaScript origin of the Google OAuth client.

## Deploy

Build the static site with:

```sh
npm --prefix client install
npm --prefix client run build
```

Upload the generated `dist/` directory to a static hosting provider, then attach `mymanger.in` and `www.mymanger.in` in that provider's domain settings. Configure the DNS records it supplies at your domain registrar and enable HTTPS after verification.

The previous application is preserved on the `legacy` branch.