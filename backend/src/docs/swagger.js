const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.3',
    info: {
      title: 'MyManager API',
      version: '1.0.0',
      description: 'Project Management / Task Management backend API'
    },
    servers: [{ url: 'http://localhost:5000/api/v1' }],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        }
      }
    },
    security: [{ bearerAuth: [] }],
    paths: {
      '/auth/register': { post: { summary: 'Register user' } },
      '/auth/login': { post: { summary: 'Login user' } },
      '/auth/refresh': { post: { summary: 'Refresh token' } },
      '/auth/logout': { post: { summary: 'Logout' } },

      '/projects': {
        post: { summary: 'Create project' },
        get: { summary: 'List projects' }
      },
      '/projects/{id}': {
        get: { summary: 'Get project by id' },
        put: { summary: 'Update project' },
        delete: { summary: 'Delete project' }
      },
      '/projects/{id}/invite': { post: { summary: 'Invite member' } },
      '/projects/{id}/members': { get: { summary: 'List project members' } },
      '/projects/{id}/boards': { get: { summary: 'List project boards and columns' } },
      '/projects/boards/{boardId}/reorder-columns': { patch: { summary: 'Reorder columns' } },

      '/tasks': {
        post: { summary: 'Create task' },
        get: { summary: 'List tasks with filters and pagination' }
      },
      '/tasks/{id}': {
        put: { summary: 'Update task' },
        delete: { summary: 'Delete task' }
      },
      '/tasks/{id}/move': { patch: { summary: 'Move task across columns' } },
      '/tasks/{id}/comments': {
        post: { summary: 'Add task comment' },
        get: { summary: 'List task comments' }
      },
      '/tasks/comments/{commentId}': {
        put: { summary: 'Edit task comment' },
        delete: { summary: 'Delete task comment' }
      },
      '/tasks/{id}/files': { post: { summary: 'Upload task file' } },
      '/tasks/files/{fileId}/download': { get: { summary: 'Download task file' } },
      '/tasks/files/{fileId}': { delete: { summary: 'Delete task file' } },

      '/notifications': { get: { summary: 'List notifications' } },
      '/notifications/{id}/read': { patch: { summary: 'Mark notification as read' } },

      '/activity-logs': { get: { summary: 'List activity logs' } }
    }
  },
  apis: []
};

module.exports = swaggerJsdoc(options);
