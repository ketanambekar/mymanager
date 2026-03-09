const { DataTypes } = require('sequelize');

module.exports = {
  async up({ context: queryInterface }) {
    await queryInterface.createTable('task_statuses', {
      id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
      user_id: {
        type: DataTypes.BIGINT.UNSIGNED,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE'
      },
      code: { type: DataTypes.STRING(64), allowNull: false },
      name: { type: DataTypes.STRING(80), allowNull: false },
      color: { type: DataTypes.STRING(16), allowNull: true },
      sort_order: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
      is_system: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
      created_at: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW },
      updated_at: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW },
      deleted_at: { type: DataTypes.DATE, allowNull: true }
    });

    await queryInterface.addIndex('task_statuses', ['user_id', 'sort_order']);
    await queryInterface.addIndex('task_statuses', ['user_id', 'code'], { unique: true });
    await queryInterface.addIndex('task_statuses', ['user_id', 'name'], { unique: true });

    await queryInterface.changeColumn('tasks', 'status', {
      type: DataTypes.STRING(64),
      allowNull: false,
      defaultValue: 'todo'
    });

    const [users] = await queryInterface.sequelize.query('SELECT id FROM users');
    const now = new Date();
    const rows = [];

    for (const user of users) {
      rows.push(
        { user_id: user.id, code: 'todo', name: 'Todo', color: '#6366F1', sort_order: 1, is_system: true, created_at: now, updated_at: now },
        { user_id: user.id, code: 'on_progress', name: 'In Progress', color: '#F59E0B', sort_order: 2, is_system: true, created_at: now, updated_at: now },
        { user_id: user.id, code: 'done', name: 'Completed', color: '#22C55E', sort_order: 3, is_system: true, created_at: now, updated_at: now }
      );
    }

    if (rows.length) {
      await queryInterface.bulkInsert('task_statuses', rows);
    }
  },

  async down({ context: queryInterface }) {
    await queryInterface.sequelize.query("UPDATE tasks SET status = 'todo' WHERE status NOT IN ('todo', 'on_progress', 'done')");

    await queryInterface.changeColumn('tasks', 'status', {
      type: DataTypes.ENUM('todo', 'on_progress', 'done'),
      allowNull: false,
      defaultValue: 'todo'
    });

    await queryInterface.dropTable('task_statuses');
  }
};
