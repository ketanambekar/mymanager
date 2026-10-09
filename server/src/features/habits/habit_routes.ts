import { Router } from "express";
import { validateRequest } from "../../shared/validate_request.js";
import { habitController } from "./habit_controller.js";
import { habitCalendarSchema, habitHistorySchema, habitListSchema, habitParamsSchema } from "./habit_schema.js";

export const habitRouter = Router();
habitRouter.use((_request, response, next) => {
  response.setHeader("Cache-Control", "no-store");
  next();
});
habitRouter.get("/", validateRequest({ query: habitListSchema }), habitController.list);
habitRouter.get("/:habitId/calendar", validateRequest({ params: habitParamsSchema, query: habitCalendarSchema }), habitController.calendar);
habitRouter.get("/:habitId/history", validateRequest({ params: habitParamsSchema, query: habitHistorySchema }), habitController.history);
