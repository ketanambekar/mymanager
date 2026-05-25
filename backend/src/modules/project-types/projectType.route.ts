import { Router } from "express";
import { validateRequest } from "../../middlewares/validateRequest";
import { projectTypeController } from "./projectType.controller";
import { createProjectTypeSchema, projectTypeIdSchema, updateProjectTypeSchema } from "./projectType.validation";

export const projectTypeRouter = Router();

projectTypeRouter.post("/", validateRequest({ body: createProjectTypeSchema.shape.body }), projectTypeController.create);
projectTypeRouter.get("/", projectTypeController.getAll);
projectTypeRouter.get("/:id", validateRequest({ params: projectTypeIdSchema.shape.params }), projectTypeController.getById);
projectTypeRouter.put(
  "/:id",
  validateRequest({ params: updateProjectTypeSchema.shape.params, body: updateProjectTypeSchema.shape.body }),
  projectTypeController.update,
);
projectTypeRouter.delete("/:id", validateRequest({ params: projectTypeIdSchema.shape.params }), projectTypeController.remove);
