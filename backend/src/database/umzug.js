const path = require('path');
const { Umzug, SequelizeStorage } = require('umzug');
const { getSequelize } = require('../config/database');

async function createMigrator() {
  const sequelize = await getSequelize();
  const migrationsGlob = path
    .join(__dirname, 'migrations', '*.js')
    .replace(/\\/g, '/');

  return new Umzug({
    migrations: {
      glob: migrationsGlob
    },
    context: sequelize.getQueryInterface(),
    storage: new SequelizeStorage({ sequelize, tableName: 'migrations_meta' }),
    logger: console
  });
}

module.exports = { createMigrator };
