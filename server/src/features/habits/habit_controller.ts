import { asyncHandler } from "../../shared/async_handler.js";
import { authenticatedUser } from "../auth/auth_context.js";
import type { HabitListInput } from "./habit_schema.js";
import { habitService } from "./habit_service.js";

export const habitController = {
  list: asyncHandler(async (request, response) => {
    const auth = authenticatedUser(request);
    const input = request.validatedQuery as HabitListInput;
    response.json({ success: true, data: await habitService.list(auth.sub, auth.workspaceId, input) });
  }),
  calendar: asyncHandler(async (request, response) => {
    const auth = authenticatedUser(request);
    const { habitId } = request.validatedParams as { habitId: string };
    const { month } = request.validatedQuery as { month?: string };
    response.json({ success: true, data: await habitService.calendar(auth.sub, auth.workspaceId, habitId, month) });
  }),
};
