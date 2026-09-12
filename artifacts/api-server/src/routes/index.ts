import { Router, type IRouter } from "express";
import healthRouter from "./health";
import schoolRouter from "./school";
import authRouter from "./auth";

const router: IRouter = Router();

router.use(healthRouter);
router.use(authRouter);
router.use(schoolRouter);

export default router;
