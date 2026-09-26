# MyManager Coming Soon

A lightweight React landing page built with Vite.

## Run locally

```sh
npm install
npm run dev
```

## Deploy

The `release` branch deploys to Hostinger through GitHub Actions. In the GitHub repository, open **Settings → Secrets and variables → Actions**, then add these repository secrets using the FTP details from Hostinger hPanel:

- `FTP_SERVER`: Hostinger FTP hostname, without `ftp://`
- `FTP_USERNAME`: FTP account username
- `FTP_PASSWORD`: FTP account password
- `FTP_SERVER_DIR`: destination directory, usually `public_html/` for the domain's document root

Once those secrets are saved, each push to `release` builds the site and uploads `dist/`. You can also start a deploy manually from **Actions → Deploy to Hostinger → Run workflow**.

In Hostinger hPanel, make sure `mymanager.in` is assigned to the hosting plan and points to the directory used for `FTP_SERVER_DIR`. Configure DNS at Hostinger if the domain uses Hostinger nameservers. Enable SSL in hPanel after DNS points to the hosting account.

The previous application is preserved on the `legacy` branch.