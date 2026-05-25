import { Router } from "express";
import { validateRequest } from "../../middlewares/validateRequest";
import { taskController } from "./task.controller";
import { createTaskSchema, taskIdSchema, taskProjectIdSchema, updateTaskSchema } from "./task.validation";

export const taskRouter = Router();

taskRouter.post("/", validateRequest({ body: createTaskSchema.shape.body }), taskController.create);
taskRouter.get("/", taskController.getAll);
taskRouter.get("/project/:projectId", validateRequest({ params: taskProjectIdSchema.shape.params }), taskController.getByProject);
taskRouter.get("/:id", validateRequest({ params: taskIdSchema.shape.params }), taskController.getById);
taskRouter.put("/:id", validateRequest({ params: updateTaskSchema.shape.params, body: updateTaskSchema.shape.body }), taskController.update);
taskRouter.delete("/:id", validateRequest({ params: taskIdSchema.shape.params }), taskController.remove);
