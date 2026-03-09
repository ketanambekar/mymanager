const { getSequelize } = require('../config/database');

const modelFactories = {
  User: require('./user'),
  Session: require('./session'),
  Project: require('./project'),
  ProjectMember: require('./projectMember'),
  Board: require('./board'),
  Column: require('./column'),
  Task: require('./task'),
  TaskStatus: require('./taskStatus'),
  TaskComment: require('./taskComment'),
  TaskFile: require('./taskFile'),
  Notification: require('./notification'),
  ActivityLog: require('./activityLog'),
  EmailOtpCode: require('./emailOtpCode')
};

const db = {};
let initialized = false;

async function initModels() {
  if (initialized) return db;

  const sequelize = await getSequelize();

  Object.entries(modelFactories).forEach(([name, factory]) => {
    db[name] = factory(sequelize);
  });

  const { User, Session, Project, ProjectMember, Board, Column, Task, TaskStatus, TaskComment, TaskFile, Notification, ActivityLog } = db;

  User.hasMany(Session, { foreignKey: 'user_id', onDelete: 'CASCADE' });
  Session.belongsTo(User, { foreignKey: 'user_id' });

  User.hasMany(Project, { foreignKey: 'created_by' });
  Project.belongsTo(User, { foreignKey: 'created_by', as: 'creator' });
  Project.belongsTo(Project, { foreignKey: 'parent_project_id', as: 'parentProject' });
  Project.hasMany(Project, { foreignKey: 'parent_project_id', as: 'subProjects' });

  Project.belongsToMany(User, { through: ProjectMember, foreignKey: 'project_id', otherKey: 'user_id', as: 'members' });
  User.belongsToMany(Project, { through: ProjectMember, foreignKey: 'user_id', otherKey: 'project_id', as: 'projects' });
  ProjectMember.belongsTo(User, { foreignKey: 'user_id' });
  ProjectMember.belongsTo(Project, { foreignKey: 'project_id' });

  Project.hasMany(Board, { foreignKey: 'project_id', onDelete: 'CASCADE' });
  Board.belongsTo(Project, { foreignKey: 'project_id' });

  Board.hasMany(Column, { foreignKey: 'board_id', onDelete: 'CASCADE' });
  Column.belongsTo(Board, { foreignKey: 'board_id' });

  Project.hasMany(Task, { foreignKey: 'project_id', onDelete: 'CASCADE' });
  Task.belongsTo(Project, { foreignKey: 'project_id' });

  Column.hasMany(Task, { foreignKey: 'column_id' });
  Task.belongsTo(Column, { foreignKey: 'column_id' });

  User.hasMany(Task, { foreignKey: 'assigned_to', as: 'assignedTasks' });
  Task.belongsTo(User, { foreignKey: 'assigned_to', as: 'assignee' });
  Task.belongsTo(User, { foreignKey: 'created_by', as: 'taskCreator' });
  User.hasMany(TaskStatus, { foreignKey: 'user_id', as: 'taskStatuses', onDelete: 'CASCADE' });
  TaskStatus.belongsTo(User, { foreignKey: 'user_id' });

  Task.hasMany(TaskComment, { foreignKey: 'task_id', onDelete: 'CASCADE' });
  TaskComment.belongsTo(Task, { foreignKey: 'task_id' });
  TaskComment.belongsTo(User, { foreignKey: 'user_id', as: 'author' });

  Task.hasMany(TaskFile, { foreignKey: 'task_id', onDelete: 'CASCADE' });
  TaskFile.belongsTo(Task, { foreignKey: 'task_id' });

  Notification.belongsTo(User, { foreignKey: 'user_id' });
  ActivityLog.belongsTo(User, { foreignKey: 'user_id' });

  db.sequelize = sequelize;
  db.Sequelize = sequelize.constructor;

  initialized = true;
  return db;
}

module.exports = new Proxy(db, {
  get(target, prop) {
    return target[prop];
  }
});

module.exports.initModels = initModels;
