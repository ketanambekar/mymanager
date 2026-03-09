const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('ProjectMember', {
  id: {
    type: DataTypes.BIGINT.UNSIGNED,
    autoIncrement: true,
    primaryKey: true
  },
  project_id: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: false
  },
  user_id: {
    type: DataTypes.BIGINT.UNSIGNED,
    allowNull: false
  },
  role: {
    type: DataTypes.ENUM('owner', 'member'),
    allowNull: false,
    defaultValue: 'member'
  }
}, {
  tableName: 'project_members',
  indexes: [{ unique: true, fields: ['project_id', 'user_id'] }]
});
