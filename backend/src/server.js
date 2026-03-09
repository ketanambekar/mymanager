const app = require('./app');
const env = require('./config/env');
const { connectDatabase } = require('./config/database');
const { initModels } = require('./models');

async function bootstrap() {
  await connectDatabase();
  await initModels();

  app.listen(env.port, () => {
    console.log(`Backend started on port ${env.port}`);
  });
}

bootstrap().catch((error) => {
  console.error('Failed to start backend:', error.message);
  process.exit(1);
});
