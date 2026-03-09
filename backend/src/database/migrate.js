const { connectDatabase } = require('../config/database');
const { createMigrator } = require('./umzug');

async function run() {
  const action = process.argv[2] || 'up';

  await connectDatabase();
  const migrator = await createMigrator();

  if (action === 'up') {
    await migrator.up();
    console.log('Migrations completed');
  } else if (action === 'down') {
    await migrator.down();
    console.log('Last migration reverted');
  } else if (action === 'reset') {
    let executed = await migrator.executed();
    while (executed.length > 0) {
      await migrator.down();
      executed = await migrator.executed();
    }
    await migrator.up();
    console.log('Database reset and migrated');
  } else {
    console.log('Unknown migration action. Use up|down|reset');
  }

  process.exit(0);
}

run().catch((error) => {
  console.error('Migration failed:', error.message);
  process.exit(1);
});
