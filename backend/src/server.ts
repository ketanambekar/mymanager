import { app } from "./app";
import { env } from "./config/env";

app.listen(env.PORT, env.HOST, () => {
  console.log(`Server running at http://${env.HOST}:${env.PORT}`);
});
