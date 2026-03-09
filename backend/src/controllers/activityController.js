const asyncHandler = require('../utils/asyncHandler');
const activityService = require('../services/activityService');
const { ensureProjectAccess } = require('../services/projectService');

const listActivity = asyncHandler(async (req, res) => {
  if (req.query.project_id) {
    await ensureProjectAccess(req.query.project_id, req.user.id);
  }

  const data = await activityService.listActivityLogs(req.query);
  res.json({ success: true, ...data });
});

module.exports = { listActivity };
