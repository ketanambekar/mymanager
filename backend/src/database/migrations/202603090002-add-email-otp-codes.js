const { DataTypes } = require('sequelize');

module.exports = {
  async up({ context: queryInterface }) {
    await queryInterface.createTable('email_otp_codes', {
      id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
      email: { type: DataTypes.STRING(190), allowNull: false, unique: true },
      otp_code: { type: DataTypes.STRING(6), allowNull: false },
      expires_at: { type: DataTypes.DATE, allowNull: false },
      created_at: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW },
      updated_at: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW },
      deleted_at: { type: DataTypes.DATE, allowNull: true }
    });

    await queryInterface.addIndex('email_otp_codes', ['email']);
    await queryInterface.addIndex('email_otp_codes', ['expires_at']);
  },

  async down({ context: queryInterface }) {
    await queryInterface.dropTable('email_otp_codes');
  }
};
