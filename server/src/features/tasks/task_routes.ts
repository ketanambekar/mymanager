import { Router } from "express";
import { validateRequest } from "../../shared/validate_request.js";
import { taskController } from "./task_controller.js";
import { createTaskSchema, subtaskCreateSchema, subtaskIdSchema, subtaskUpdateSchema, taskIdSchema, taskListSchema, updateTaskSchema, versionSchema } from "./task_schema.js";

export const taskRouter = Router();
taskRouter.get("/", validateRequest({ query: taskListSchema }), taskController.list);
taskRouter.post("/", validateRequest({ body: createTaskSchema }), taskController.create);
taskRouter.get("/:taskId", validateRequest({ params: taskIdSchema }), taskController.get);
taskRouter.patch("/:taskId", validateRequest({ params: taskIdSchema, body: updateTaskSchema }), taskController.update);
taskRouter.delete("/:taskId", validateRequest({ params: taskIdSchema }), taskController.remove);
taskRouter.post("/:taskId/complete", validateRequest({ params: taskIdSchema, body: versionSchema }), taskController.complete);
taskRouter.post("/:taskId/reopen", validateRequest({ params: taskIdSchema, body: versionSchema }), taskController.reopen);
taskRouter.post("/:taskId/subtasks", validateRequest({ params: taskIdSchema, body: subtaskCreateSchema }), taskController.addSubtask);
taskRouter.patch("/:taskId/subtasks/:subtaskId", validateRequest({ params: subtaskIdSchema, body: subtaskUpdateSchema }), taskController.updateSubtask);
taskRouter.delete("/:taskId/subtasks/:subtaskId", validateRequest({ params: subtaskIdSchema }), taskController.removeSubtask);
taskRouter.post("/:taskId/subtasks/:subtaskId/complete", validateRequest({ params: subtaskIdSchema, body: versionSchema }), taskController.completeSubtask);
taskRouter.post("/:taskId/subtasks/:subtaskId/reopen", validateRequest({ params: subtaskIdSchema, body: versionSchema }), taskController.reopenSubtask);