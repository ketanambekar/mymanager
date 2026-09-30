import { app } from "./app.js";
import { env } from "./config/env.js";

app.listen(env.PORT, env.HOST, () => {
  console.log(`MyManger API listening on http://${env.HOST}:${env.PORT}`);
});