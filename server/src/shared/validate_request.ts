import type { NextFunction, Request, RequestHandler, Response } from "express";
import type { ZodType } from "zod";

type Schemas = { body?: ZodType; params?: ZodType; query?: ZodType };

export function validateRequest(schemas: Schemas): RequestHandler {
  return (request: Request, _response: Response, next: NextFunction) => {
    if (schemas.body) request.validatedBody = schemas.body.parse(request.body);
    if (schemas.params) request.validatedParams = schemas.params.parse(request.params);
    if (schemas.query) request.validatedQuery = schemas.query.parse(request.query);
    next();
  };
}