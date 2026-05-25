import { Router } from "express";
import { validateRequest } from "../../middlewares/validateRequest";
import { projectController } from "./project.controller";
import { createProjectSchema, projectIdSchema, updateProjectSchema } from "./project.validation";

export const projectRouter = Router();

projectRouter.post("/", validateRequest({ body: createProjectSchema.shape.body }), projectController.create);
projectRouter.get("/", projectController.getAll);
projectRouter.get("/:id", validateRequest({ params: projectIdSchema.shape.params }), projectController.getById);
projectRouter.put("/:id", validateRequest({ params: updateProjectSchema.shape.params, body: updateProjectSchema.shape.body }), projectController.update);
projectRouter.delete("/:id", validateRequest({ params: projectIdSchema.shape.params }), projectController.remove);
