const router = require('express').Router();

const auth = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const controller = require('../../controllers/activityController');
const { activityQuerySchema } = require('../../validators/activityValidator');

router.use(auth);
router.get('/', validate(activityQuerySchema, 'query'), controller.listActivity);

module.exports = router;
