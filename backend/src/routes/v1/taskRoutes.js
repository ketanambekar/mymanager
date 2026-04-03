const router = require('express').Router();

const auth = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const upload = require('../../middlewares/upload');
const controller = require('../../controllers/taskController');
const { createTaskSchema, updateTaskSchema, moveTaskSchema, commentSchema, taskQuerySchema } = require('../../validators/taskValidator');

router.use(auth);

router.post('/', validate(createTaskSchema), controller.createTask);
router.get('/', validate(taskQuerySchema, 'query'), controller.listTasks);

router.post('/:id/comments', validate(commentSchema), controller.addComment);
router.get('/:id/comments', controller.listComments);
router.put('/comments/:commentId', validate(commentSchema), controller.updateComment);
router.delete('/comments/:commentId', controller.deleteComment);

router.post('/:id/files', upload.single('file'), controller.uploadFile);
router.get('/files/:fileId/download', controller.downloadFile);
router.delete('/files/:fileId', controller.deleteFile);

router.patch('/:id/move', validate(moveTaskSchema), controller.moveTask);
router.put('/:id', validate(updateTaskSchema), controller.updateTask);
router.delete('/:id', controller.deleteTask);

module.exports = router;
