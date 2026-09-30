import { Router } from "express";
import { validateRequest } from "../../shared/validate_request.js";
import { projectController } from "./project_controller.js";
import { createProjectSchema, projectIdSchema, updateProjectSchema } from "./project_schema.js";

export const projectRouter = Router();
projectRouter.get("/", projectController.list);
projectRouter.post("/", validateRequest({ body: createProjectSchema }), projectController.create);
projectRouter.get("/:projectId", validateRequest({ params: projectIdSchema }), projectController.get);
projectRouter.patch("/:projectId", validateRequest({ params: projectIdSchema, body: updateProjectSchema }), projectController.update);
projectRouter.delete("/:projectId", validateRequest({ params: projectIdSchema }), projectController.remove);