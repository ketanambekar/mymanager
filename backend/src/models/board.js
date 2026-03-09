const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('Board', {
  id: {
    type: DataTypes.BIGINT.UNSIGNED,
    autoIncrement: true,
    primaryKey: true
  },
  project_id: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: false
  },
  name: {
    type: DataTypes.STRING(120),
    allowNull: false,
    defaultValue: 'Main Board'
  }
}, {
  tableName: 'boards',
  indexes: [{ fields: ['project_id'] }]
});
