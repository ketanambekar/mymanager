const { Sequelize } = require('sequelize');
const env = require('./env');
const { promptMySqlPassword } = require('../utils/promptPassword');

let sequelize;

async function getSequelize() {
  if (sequelize) return sequelize;

  let effectivePassword = process.env.DB_PASSWORD || '';
  if (!effectivePassword) {
    effectivePassword = await promptMySqlPassword();
    process.env.DB_PASSWORD = effectivePassword;
  }

  sequelize = new Sequelize(env.db.name, env.db.user, effectivePassword, {
    host: env.db.host,
    dialect: env.db.dialect,
    logging: env.nodeEnv === 'development' ? console.log : false,
    define: {
      underscored: true,
      paranoid: true,
      timestamps: true,
      createdAt: 'created_at',
      updatedAt: 'updated_at',
      deletedAt: 'deleted_at'
    },
    pool: {
      max: 10,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  });

  return sequelize;
}

async function connectDatabase() {
  const db = await getSequelize();
  await db.authenticate();
  return db;
}

module.exports = { getSequelize, connectDatabase };
