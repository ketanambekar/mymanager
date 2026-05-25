import { Router } from "express";
import { requireAuth } from "../middlewares/authContext";
import { authRouter } from "../modules/auth/auth.route";
import { projectTypeRouter } from "../modules/project-types/projectType.route";
import { priorityRouter } from "../modules/priorities/priority.route";
import { projectColorRouter } from "../modules/project-colors/projectColor.route";
import { projectRouter } from "../modules/projects/project.route";
import { taskRouter } from "../modules/tasks/task.route";
import { subTaskRouter } from "../modules/subtasks/subTask.route";

export const apiRouter = Router();

apiRouter.use("/auth", authRouter);
apiRouter.use(requireAuth);

apiRouter.use("/project-types", projectTypeRouter);
apiRouter.use("/priorities", priorityRouter);
apiRouter.use("/project-colors", projectColorRouter);
apiRouter.use("/projects", projectRouter);
apiRouter.use("/tasks", taskRouter);
apiRouter.use("/subtasks", subTaskRouter);
