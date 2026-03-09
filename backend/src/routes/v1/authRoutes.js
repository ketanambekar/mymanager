const router = require('express').Router();
const auth = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const controller = require('../../controllers/authController');
const {
	registerSchema,
	loginSchema,
	refreshSchema,
	requestEmailOtpSchema,
	verifyEmailOtpSchema
} = require('../../validators/authValidator');

router.post('/register', validate(registerSchema), controller.register);
router.post('/login', validate(loginSchema), controller.login);
router.post('/email-otp/request', validate(requestEmailOtpSchema), controller.requestEmailOtp);
router.post('/email-otp/verify', validate(verifyEmailOtpSchema), controller.verifyEmailOtp);
router.post('/refresh', validate(refreshSchema), controller.refresh);
router.post('/logout', auth, controller.logout);
router.get('/me', auth, controller.me);

module.exports = router;
