import { app } from "./app.js";
import { buildInfo } from "./config/build_info.js";
import { env } from "./config/env.js";

app.listen(env.PORT, env.HOST, () => {
  console.log(`MyManger API v${buildInfo.version} (commit ${buildInfo.commit}, built ${buildInfo.builtAt ?? "locally"}) listening on http://${env.HOST}:${env.PORT}`);
});