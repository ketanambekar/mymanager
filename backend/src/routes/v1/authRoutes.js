const router = require('express').Router();
const rateLimit = require('express-rate-limit');
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

const authLimiter = rateLimit({
	windowMs: 15 * 60 * 1000,
	max: 30,
	standardHeaders: true,
	legacyHeaders: false,
	message: { success: false, message: 'Too many authentication requests. Please try again later.' }
});

router.post('/register', authLimiter, validate(registerSchema), controller.register);
router.post('/login', authLimiter, validate(loginSchema), controller.login);
router.post('/email-otp/request', authLimiter, validate(requestEmailOtpSchema), controller.requestEmailOtp);
router.post('/email-otp/verify', authLimiter, validate(verifyEmailOtpSchema), controller.verifyEmailOtp);
router.post('/refresh', authLimiter, validate(refreshSchema), controller.refresh);
router.post('/logout', auth, controller.logout);
router.get('/me', auth, controller.me);

module.exports = router;
