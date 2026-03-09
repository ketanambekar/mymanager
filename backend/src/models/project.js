const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('Project', {
  id: {
    type: DataTypes.BIGINT.UNSIGNED,
    autoIncrement: true,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING(180),
    allowNull: false
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  parent_project_id: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: true
  },
  created_by: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: false
  }
}, {
  tableName: 'projects',
  indexes: [{ fields: ['created_by'] }, { fields: ['parent_project_id'] }]
});
