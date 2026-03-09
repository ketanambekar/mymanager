const asyncHandler = require('../utils/asyncHandler');
const authService = require('../services/authService');

function refreshCookieOptions() {
  const isProd = process.env.NODE_ENV === 'production';
  return {
    httpOnly: true,
    secure: isProd,
    sameSite: isProd ? 'none' : 'lax',
    path: '/api/v1/auth'
  };
}

const register = asyncHandler(async (req, res) => {
  const user = await authService.register(req.body);
  res.status(201).json({ success: true, data: user });
});

const login = asyncHandler(async (req, res) => {
  const data = await authService.login(req.body);
  res.cookie('refresh_token', data.refresh_token, refreshCookieOptions());
  res.json({ success: true, data });
});

const requestEmailOtp = asyncHandler(async (req, res) => {
  const data = await authService.requestEmailOtp(req.body);
  res.json({ success: true, data });
});

const verifyEmailOtp = asyncHandler(async (req, res) => {
  const data = await authService.verifyEmailOtp(req.body);
  res.cookie('refresh_token', data.refresh_token, refreshCookieOptions());
  res.json({ success: true, data });
});

const refresh = asyncHandler(async (req, res) => {
  const incomingRefresh = req.body.refresh_token || req.cookies?.refresh_token;
  const data = await authService.refreshToken(incomingRefresh);
  res.cookie('refresh_token', data.refresh_token, refreshCookieOptions());
  res.json({ success: true, data });
});

const logout = asyncHandler(async (req, res) => {
  await authService.logout(req.token);
  res.clearCookie('refresh_token', refreshCookieOptions());
  res.json({ success: true, message: 'Logged out' });
});

const me = asyncHandler(async (req, res) => {
  const user = await authService.me(req.user.id);
  res.json({ success: true, data: user });
});

module.exports = { register, login, requestEmailOtp, verifyEmailOtp, refresh, logout, me };
