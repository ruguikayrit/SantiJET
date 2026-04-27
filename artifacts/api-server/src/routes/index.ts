import { Router, type IRouter } from "express";
import healthRouter from "./health";
import workspacesRouter from "./workspaces";
import aiRouter from "./ai";

const router: IRouter = Router();

router.use(healthRouter);
router.use(workspacesRouter);
router.use(aiRouter);

export default router;
