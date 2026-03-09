const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('TaskStatus', {
  id: {
    type: DataTypes.BIGINT.UNSIGNED,
    autoIncrement: true,
    primaryKey: true
  },
  user_id: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: false
  },
  code: {
    type: DataTypes.STRING(64),
    allowNull: false
  },
  name: {
    type: DataTypes.STRING(80),
    allowNull: false
  },
  color: {
    type: DataTypes.STRING(16),
    allowNull: true
  },
  sort_order: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  is_system: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  }
}, {
  tableName: 'task_statuses',
  indexes: [
    { fields: ['user_id', 'sort_order'] },
    { fields: ['user_id', 'code'], unique: true },
    { fields: ['user_id', 'name'], unique: true }
  ]
});
