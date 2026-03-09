const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('EmailOtpCode', {
  id: {
    type: DataTypes.BIGINT.UNSIGNED,
    autoIncrement: true,
    primaryKey: true
  },
  email: {
    type: DataTypes.STRING(190),
    allowNull: false,
    unique: true
  },
  otp_code: {
    type: DataTypes.STRING(6),
    allowNull: false
  },
  expires_at: {
    type: DataTypes.DATE,
    allowNull: false
  }
}, {
  tableName: 'email_otp_codes'
});
