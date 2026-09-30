# MyManger

A React task workspace built with Vite. Tasks are currently saved in this browser; account sync and a backend are not connected yet.

## Run locally

```sh
npm --prefix client install
npm --prefix client run dev
```

## Deploy

Build the static site with:

```sh
npm --prefix client install
npm --prefix client run build
```

Upload the generated `dist/` directory to a static hosting provider, then attach `mymanger.in` and `www.mymanger.in` in that provider's domain settings. Configure the DNS records it supplies at your domain registrar and enable HTTPS after verification.

The previous application is preserved on the `legacy` branch.