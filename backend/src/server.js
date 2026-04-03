const app = require('./app');
const env = require('./config/env');
const { connectDatabase } = require('./config/database');
const { initModels } = require('./models');

async function bootstrap() {
  await connectDatabase();
  await initModels();

  app.listen(env.port, '0.0.0.0', () => {
    console.log(`Backend started on http://0.0.0.0:${env.port}`);
    console.log(`Access from another system: http://192.168.0.241:${env.port}`);
  });
}

bootstrap().catch((error) => {
  console.error('Failed to start backend:', error.message);
  process.exit(1);
});
