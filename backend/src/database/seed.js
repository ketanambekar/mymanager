const bcrypt = require('bcrypt');

const { connectDatabase } = require('../config/database');
const { initModels } = require('../models');

async function seed() {
  await connectDatabase();
  await initModels();

  const models = require('../models');

  const adminPassword = await bcrypt.hash('Admin@123', 12);
  const [admin] = await models.User.findOrCreate({
    where: { email: 'admin@mymanager.local' },
    defaults: {
      name: 'System Admin',
      email: 'admin@mymanager.local',
      password_hash: adminPassword,
      role: 'admin'
    }
  });

  const [project] = await models.Project.findOrCreate({
    where: { name: 'Demo Project', created_by: admin.id },
    defaults: {
      description: 'Demo project for onboarding',
      created_by: admin.id
    }
  });

  await models.ProjectMember.findOrCreate({
    where: { project_id: project.id, user_id: admin.id },
    defaults: { role: 'owner' }
  });

  const [board] = await models.Board.findOrCreate({
    where: { project_id: project.id, name: 'Main Board' },
    defaults: { project_id: project.id, name: 'Main Board' }
  });

  const [todo] = await models.Column.findOrCreate({
    where: { board_id: board.id, name: 'To Do' },
    defaults: { board_id: board.id, name: 'To Do', order_index: 1 }
  });

  const [progress] = await models.Column.findOrCreate({
    where: { board_id: board.id, name: 'On Progress' },
    defaults: { board_id: board.id, name: 'On Progress', order_index: 2 }
  });

  const [done] = await models.Column.findOrCreate({
    where: { board_id: board.id, name: 'Done' },
    defaults: { board_id: board.id, name: 'Done', order_index: 3 }
  });

  await models.Task.findOrCreate({
    where: { title: 'Create project architecture', project_id: project.id },
    defaults: {
      title: 'Create project architecture',
      description: 'Set up MVC, DB migrations, and security middlewares',
      priority: 'high',
      status: 'todo',
      project_id: project.id,
      column_id: todo.id,
      assigned_to: admin.id,
      created_by: admin.id,
      due_date: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
      order_index: 1
    }
  });

  await models.Task.findOrCreate({
    where: { title: 'Implement task filtering', project_id: project.id },
    defaults: {
      title: 'Implement task filtering',
      description: 'Add status, assignee, priority, and due date filters',
      priority: 'medium',
      status: 'on_progress',
      project_id: project.id,
      column_id: progress.id,
      assigned_to: admin.id,
      created_by: admin.id,
      due_date: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
      order_index: 1
    }
  });

  await models.Task.findOrCreate({
    where: { title: 'Publish API docs', project_id: project.id },
    defaults: {
      title: 'Publish API docs',
      description: 'Expose Swagger and Postman collection',
      priority: 'low',
      status: 'done',
      project_id: project.id,
      column_id: done.id,
      assigned_to: admin.id,
      created_by: admin.id,
      due_date: null,
      order_index: 1
    }
  });

  console.log('Seed data created successfully');
  console.log('Admin login: admin@mymanager.local / Admin@123');
}

seed().then(() => process.exit(0)).catch((err) => {
  console.error('Seed failed:', err.message);
  process.exit(1);
});
