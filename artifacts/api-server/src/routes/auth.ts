import { createHash, randomBytes } from "node:crypto";
import { Router, type IRouter, type NextFunction, type Request, type Response } from "express";
import { eq } from "drizzle-orm";
import { db, deviceTokensTable, usersTable } from "@workspace/db";

const router: IRouter = Router();
const sessions = new Map<string, { userId: number; role: "admin" | "accountant" }>();

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.header("authorization") ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : "";
  const session = sessions.get(token);
  if (!session) return res.status(401).json({ error: "Authentication required" });
  res.locals.auth = session;
  return next();
}

function hashPassword(password: string) {
  return createHash("sha256").update(password).digest("hex");
}

function publicUser(user: typeof usersTable.$inferSelect) {
  return { id: user.id, name: user.name, email: user.email, role: user.role };
}

router.post("/auth/signup", async (req, res) => {
  const name = String(req.body.name ?? "").trim();
  const email = String(req.body.email ?? "").trim().toLowerCase();
  const password = String(req.body.password ?? "");
  const role = String(req.body.role ?? "accountant").toLowerCase();
  if (!name || !email || password.length < 8) {
    return res.status(400).json({ error: "name, email and an 8-character password are required" });
  }
  if (role !== "accountant") {
    return res.status(403).json({ error: "Only accountant accounts can be created" });
  }
  const [existing] = await db.select().from(usersTable).where(eq(usersTable.email, email));
  if (existing || email === (process.env.ADMIN_EMAIL ?? "").trim().toLowerCase()) {
    return res.status(409).json({ error: "An account with this email already exists" });
  }
  const [user] = await db.insert(usersTable).values({
    name,
    email,
    passwordHash: hashPassword(password),
    role: "accountant",
  }).returning();
  return res.status(201).json({ user: publicUser(user) });
});

router.post("/auth/login", async (req, res) => {
  const email = String(req.body.email ?? "").trim().toLowerCase();
  const password = String(req.body.password ?? "");
  const adminEmail = (process.env.ADMIN_EMAIL ?? "").trim().toLowerCase();
  const adminPassword = process.env.ADMIN_PASSWORD ?? "";
  let user: typeof usersTable.$inferSelect | undefined;

  if (email && email === adminEmail && password === adminPassword && adminEmail) {
    user = {
      id: 0,
      name: "School Admin",
      email: adminEmail,
      passwordHash: "",
      role: "admin",
      createdAt: new Date(),
    };
  } else {
    const [candidate] = await db.select().from(usersTable).where(eq(usersTable.email, email));
    if (candidate && candidate.passwordHash === hashPassword(password)) user = candidate;
  }
  if (!user) return res.status(401).json({ error: "Invalid email or password" });

  const token = randomBytes(32).toString("hex");
  sessions.set(token, { userId: user.id, role: user.role as "admin" | "accountant" });
  return res.json({ token, user: publicUser(user) });
});

router.post("/auth/device-tokens", requireAuth, async (req, res) => {
  const token = String(req.body.token ?? "").trim();
  const platform = String(req.body.platform ?? "android").trim().toLowerCase();
  if (!token) return res.status(400).json({ error: "token is required" });

  await db.insert(deviceTokensTable).values({
    userId: res.locals.auth.userId,
    token,
    platform,
    updatedAt: new Date(),
  }).onConflictDoUpdate({
    target: deviceTokensTable.token,
    set: {
      userId: res.locals.auth.userId,
      platform,
      updatedAt: new Date(),
    },
  });
  return res.status(204).send();
});

export default router;
