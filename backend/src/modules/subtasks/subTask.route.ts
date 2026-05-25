import { Router } from "express";
import { validateRequest } from "../../middlewares/validateRequest";
import { subTaskController } from "./subTask.controller";
import { createSubTaskSchema, subTaskIdSchema, updateSubTaskSchema } from "./subTask.validation";

export const subTaskRouter = Router();

subTaskRouter.post("/", validateRequest({ body: createSubTaskSchema.shape.body }), subTaskController.create);
subTaskRouter.get("/", subTaskController.getAll);
subTaskRouter.get("/:id", validateRequest({ params: subTaskIdSchema.shape.params }), subTaskController.getById);
subTaskRouter.put("/:id", validateRequest({ params: updateSubTaskSchema.shape.params, body: updateSubTaskSchema.shape.body }), subTaskController.update);
subTaskRouter.delete("/:id", validateRequest({ params: subTaskIdSchema.shape.params }), subTaskController.remove);
