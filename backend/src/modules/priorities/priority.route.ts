import { Router } from "express";
import { validateRequest } from "../../middlewares/validateRequest";
import { priorityController } from "./priority.controller";
import { createPrioritySchema, priorityIdSchema, updatePrioritySchema } from "./priority.validation";

export const priorityRouter = Router();

priorityRouter.post("/", validateRequest({ body: createPrioritySchema.shape.body }), priorityController.create);
priorityRouter.get("/", priorityController.getAll);
priorityRouter.get("/:id", validateRequest({ params: priorityIdSchema.shape.params }), priorityController.getById);
priorityRouter.put(
  "/:id",
  validateRequest({ params: updatePrioritySchema.shape.params, body: updatePrioritySchema.shape.body }),
  priorityController.update,
);
priorityRouter.delete("/:id", validateRequest({ params: priorityIdSchema.shape.params }), priorityController.remove);
