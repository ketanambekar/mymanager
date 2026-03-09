const router = require('express').Router();

const auth = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const controller = require('../../controllers/projectController');
const { createProjectSchema, updateProjectSchema, inviteMemberSchema, reorderColumnsSchema } = require('../../validators/projectValidator');

router.use(auth);

router.post('/', validate(createProjectSchema), controller.createProject);
router.get('/', controller.listProjects);
router.get('/:id', controller.getProject);
router.put('/:id', validate(updateProjectSchema), controller.updateProject);
router.delete('/:id', controller.deleteProject);

router.post('/:id/invite', validate(inviteMemberSchema), controller.inviteMember);
router.get('/:id/members', controller.listMembers);
router.get('/:id/boards', controller.listBoards);

router.patch('/boards/:boardId/reorder-columns', validate(reorderColumnsSchema), controller.reorderColumns);

module.exports = router;
