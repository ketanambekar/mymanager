import { NextFunction, Request, Response } from "express";
import { z } from "zod";

type SchemaBundle = {
  body?: z.ZodTypeAny;
  query?: z.ZodTypeAny;
  params?: z.ZodTypeAny;
};

export function validateRequest(schemas: SchemaBundle) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (schemas.body) {
      req.validatedBody = schemas.body.parse(req.body);
    }

    if (schemas.query) {
      req.validatedQuery = schemas.query.parse(req.query);
    }

    if (schemas.params) {
      req.validatedParams = schemas.params.parse(req.params);
    }

    next();
  };
}
