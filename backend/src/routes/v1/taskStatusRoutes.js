const router = require('express').Router();

const auth = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const controller = require('../../controllers/taskStatusController');
const { createTaskStatusSchema, updateTaskStatusSchema } = require('../../validators/taskStatusValidator');

router.use(auth);

router.get('/', controller.listTaskStatuses);
router.post('/', validate(createTaskStatusSchema), controller.createTaskStatus);
router.put('/:id', validate(updateTaskStatusSchema), controller.updateTaskStatus);
router.delete('/:id', controller.deleteTaskStatus);

module.exports = router;
