const router = require('express').Router();

const auth = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const controller = require('../../controllers/notificationController');
const { listNotificationQuerySchema } = require('../../validators/notificationValidator');

router.use(auth);

router.get('/', validate(listNotificationQuerySchema, 'query'), controller.listNotifications);
router.patch('/:id/read', controller.markRead);
router.delete('/:id', controller.deleteOne);
router.delete('/', controller.deleteAll);

module.exports = router;
