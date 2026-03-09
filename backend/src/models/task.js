const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('Task', {
  id: {
    type: DataTypes.BIGINT.UNSIGNED,
    autoIncrement: true,
    primaryKey: true
  },
  title: {
    type: DataTypes.STRING(220),
    allowNull: false
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  priority: {
    type: DataTypes.ENUM('low', 'medium', 'high'),
    allowNull: false,
    defaultValue: 'medium'
  },
  status: {
    type: DataTypes.STRING(64),
    allowNull: false,
    defaultValue: 'todo'
  },
  project_id: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: false
  },
  column_id: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: false
  },
  assigned_to: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: true
  },
  created_by: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: false
  },
  due_date: {
    type: DataTypes.DATE,
    allowNull: true
  },
  order_index: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  }
}, {
  tableName: 'tasks',
  indexes: [
    { fields: ['project_id', 'status'] },
    { fields: ['assigned_to'] },
    { fields: ['priority'] },
    { fields: ['due_date'] }
  ]
});
