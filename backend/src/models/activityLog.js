const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('ActivityLog', {
  id: {
    type: DataTypes.BIGINT.UNSIGNED,
    autoIncrement: true,
    primaryKey: true
  },
  user_id: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: false
  },
  project_id: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: true
  },
  task_id: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: true
  },
  action: {
    type: DataTypes.STRING(80),
    allowNull: false
  },
  metadata: {
    type: DataTypes.JSON,
    allowNull: true
  }
}, {
  tableName: 'activity_logs',
  indexes: [{ fields: ['project_id', 'created_at'] }, { fields: ['task_id'] }]
});
