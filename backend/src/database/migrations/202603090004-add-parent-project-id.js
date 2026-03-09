const { DataTypes } = require('sequelize');

module.exports = {
  async up({ context: queryInterface }) {
    await queryInterface.addColumn('projects', 'parent_project_id', {
      type: DataTypes.BIGINT.UNSIGNED,
      allowNull: true,
      references: { model: 'projects', key: 'id' },
      onDelete: 'SET NULL',
      onUpdate: 'CASCADE'
    });

    await queryInterface.addIndex('projects', ['parent_project_id']);
  },

  async down({ context: queryInterface }) {
    await queryInterface.removeIndex('projects', ['parent_project_id']);
    await queryInterface.removeColumn('projects', 'parent_project_id');
  }
};
