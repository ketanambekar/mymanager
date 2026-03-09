const router = require('express').Router();

router.use('/auth', require('./authRoutes'));
router.use('/projects', require('./projectRoutes'));
router.use('/tasks', require('./taskRoutes'));
router.use('/task-statuses', require('./taskStatusRoutes'));
router.use('/notifications', require('./notificationRoutes'));
router.use('/activity-logs', require('./activityRoutes'));

module.exports = router;
