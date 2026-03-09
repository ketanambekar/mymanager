const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('TaskFile', {
  id: {
    type: DataTypes.BIGINT.UNSIGNED,
    autoIncrement: true,
    primaryKey: true
  },
  task_id: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: false
  },
  uploaded_by: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: false
  },
  original_name: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  file_name: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  mime_type: {
    type: DataTypes.STRING(120),
    allowNull: false
  },
  size: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: false
  }
}, {
  tableName: 'task_files',
  indexes: [{ fields: ['task_id'] }]
});
