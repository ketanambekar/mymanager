import { Router } from "express";
import { validateRequest } from "../../middlewares/validateRequest";
import { projectColorController } from "./projectColor.controller";
import { createProjectColorSchema, projectColorIdSchema, updateProjectColorSchema } from "./projectColor.validation";

export const projectColorRouter = Router();

projectColorRouter.post("/", validateRequest({ body: createProjectColorSchema.shape.body }), projectColorController.create);
projectColorRouter.get("/", projectColorController.getAll);
projectColorRouter.get("/:id", validateRequest({ params: projectColorIdSchema.shape.params }), projectColorController.getById);
projectColorRouter.put(
  "/:id",
  validateRequest({ params: updateProjectColorSchema.shape.params, body: updateProjectColorSchema.shape.body }),
  projectColorController.update,
);
projectColorRouter.delete("/:id", validateRequest({ params: projectColorIdSchema.shape.params }), projectColorController.remove);
