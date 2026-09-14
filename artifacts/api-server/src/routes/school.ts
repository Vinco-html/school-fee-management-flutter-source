import { Router, type IRouter } from "express";
import { asc, desc, eq, sql } from "drizzle-orm";
import {
  activityTable,
  eventsTable,
  classesTable,
  db,
  messagesTable,
  notificationsTable,
  pendingPaymentsTable,
  paymentsTable,
  studentsTable,
} from "@workspace/db";
import { sendPushNotification } from "../push";
import { requireAdmin, requireAuth } from "./auth";

const router: IRouter = Router();
let seedPromise: Promise<void> | undefined;

function isoDate(value: Date | null | undefined) {
  return value ? value.toISOString() : null;
}

async function seedSchoolData() {
  if (process.env.DEMO_SEED !== "true") return;
  if (seedPromise) return seedPromise;
  seedPromise = (async () => {
    const [{ count }] = await db.select({ count: sql<number>`count(*)` }).from(studentsTable);
    if (Number(count) > 0) return;

    const [a, b, c] = await db.insert(studentsTable).values([
      {
        admissionNo: "ADM-24018",
        name: "Amara Wanjiku",
        grade: "Grade 8",
        guardian: "Grace Wanjiku",
        guardianPhone: "+254 712 442 118",
        balance: 18500,
        status: "Active",
        avatarUrl: "https://i.pravatar.cc/96?img=47",
      },
      {
        admissionNo: "ADM-24022",
        name: "Daniel Otieno",
        grade: "Grade 7",
        guardian: "Peter Otieno",
        guardianPhone: "+254 722 814 223",
        balance: 0,
        status: "Active",
        avatarUrl: "https://i.pravatar.cc/96?img=12",
      },
      {
        admissionNo: "ADM-24029",
        name: "Zuri Mwangi",
        grade: "Grade 9",
        guardian: "Lucy Mwangi",
        guardianPhone: "+254 704 990 184",
        balance: 42000,
        status: "Pending",
        avatarUrl: "https://i.pravatar.cc/96?img=32",
      },
    ]).returning();

    await db.insert(classesTable).values([
      { name: "Grade 7", stream: "North", studentsCount: 31, teacher: "Joyce Njeri", feeTarget: 1850000, term: "Term 1" },
      { name: "Grade 8", stream: "East", studentsCount: 28, teacher: "Mark Kamau", feeTarget: 1680000, term: "Term 1" },
      { name: "Grade 9", stream: "West", studentsCount: 26, teacher: "Esther Achieng", feeTarget: 1560000, term: "Term 1" },
      { name: "Grade 10", stream: "South", studentsCount: 24, teacher: "David Kiptoo", feeTarget: 1440000, term: "Term 1" },
    ]);

    await db.insert(paymentsTable).values([
      { receiptNo: "RCT-10482", studentId: a.id, studentName: a.name, amount: 65000, method: "Equity Bank", channel: "Automated", status: "Completed" },
      { receiptNo: "RCT-10481", studentId: b.id, studentName: b.name, amount: 40000, method: "M-Pesa", channel: "Manual", status: "Completed" },
      { receiptNo: "RCT-10480", studentId: c.id, studentName: c.name, amount: 28000, method: "Cash", channel: "Manual", status: "Completed" },
    ]);

    await db.insert(activityTable).values([
      { actor: "Sarah Njeri", role: "Accountant", action: "Recorded manual payment", detail: "KES 40,000 from Daniel Otieno", },
      { actor: "John Kamau", role: "Accountant", action: "Added a student", detail: "Amara Wanjiku to Grade 8", },
      { actor: "Equity Bank", role: "Automated", action: "Payment received", detail: "KES 65,000 for Amara Wanjiku", },
    ]);

    await db.insert(notificationsTable).values([
      { title: "Payment recorded", body: "Sarah Njeri recorded a KES 40,000 manual payment for Daniel Otieno.", type: "payment", read: false },
      { title: "New student added", body: "John Kamau added Amara Wanjiku to Grade 8 East.", type: "student", read: false },
      { title: "Equity Bank connected", body: "Automated payment updates are ready to sync.", type: "integration", read: true },
    ]);

    await db.insert(messagesTable).values([
      { campaign: "Term 1 balance reminder", channel: "WhatsApp + SMS", audience: "Parents with balances", status: "Ready", recipientCount: 84 },
      { campaign: "Sports day announcement", channel: "Bulk email", audience: "All parents", status: "Sent", recipientCount: 312, sentAt: new Date() },
    ]);
  })();
  return seedPromise;
}

function studentDto(student: typeof studentsTable.$inferSelect) {
  return { ...student, createdAt: isoDate(student.createdAt) };
}

function classDto(schoolClass: typeof classesTable.$inferSelect) {
  return { ...schoolClass, createdAt: isoDate(schoolClass.createdAt) };
}

function paymentDto(payment: typeof paymentsTable.$inferSelect) {
  return { ...payment, paidAt: isoDate(payment.paidAt) };
}

function activityDto(item: typeof activityTable.$inferSelect) {
  return { ...item, createdAt: isoDate(item.createdAt) };
}

function notificationDto(item: typeof notificationsTable.$inferSelect) {
  return { ...item, createdAt: isoDate(item.createdAt) };
}

async function createNotification(title: string, body: string, type: string) {
  await db.insert(notificationsTable).values({ title, body, type });
  void sendPushNotification(title, body, { type }).catch((error) => {
    console.error("Push notification delivery failed", error);
  });
}

function messageDto(item: typeof messagesTable.$inferSelect) {
  return { ...item, sentAt: isoDate(item.sentAt) };
}

function eventDto(item: typeof eventsTable.$inferSelect) {
  return {
    ...item,
    eventDate: isoDate(item.eventDate),
    createdAt: isoDate(item.createdAt),
  };
}

function pendingPaymentDto(item: typeof pendingPaymentsTable.$inferSelect) {
  return {
    ...item,
    candidateIds: JSON.parse(item.candidateIds) as number[],
    createdAt: isoDate(item.createdAt),
  };
}

function normalized(value: unknown) {
  return String(value ?? "").trim().toLowerCase().replace(/\s+/g, " ");
}

async function recordPayment(student: typeof studentsTable.$inferSelect,
  amount: number, transactionId: string, method: string, channel: string) {
  const [payment] = await db.insert(paymentsTable).values({
    receiptNo: `RCT-${Math.floor(10500 + Math.random() * 400)}`,
    studentId: student.id,
    studentName: student.name,
    amount,
    method,
    channel,
    status: "Completed",
  }).returning();
  await db.update(studentsTable)
    .set({ balance: Math.max(0, student.balance - amount) })
    .where(eq(studentsTable.id, student.id));
  await db.insert(activityTable).values({
    actor: channel === "TUMA" ? "TUMA" : "Accountant",
    role: channel === "TUMA" ? "Automated" : "Accountant",
    action: "Recorded payment",
    detail: `KES ${amount.toLocaleString()} for ${student.name} (${transactionId})`,
  });
  await createNotification(
    "Payment received",
    `KES ${amount.toLocaleString()} was applied to ${student.name}.`,
    "payment",
  );
  return payment;
}

router.get("/school/dashboard", async (_req, res) => {
  await seedSchoolData();
  const [studentTotals] = await db.select({
    count: sql<number>`count(*)`,
    balance: sql<number>`coalesce(sum(balance), 0)`,
  }).from(studentsTable);
  const [paymentTotals] = await db.select({
    collected: sql<number>`coalesce(sum(amount), 0)`,
    count: sql<number>`count(*)`,
  }).from(paymentsTable).where(eq(paymentsTable.status, "Completed"));
  const recentActivity = await db.select().from(activityTable).orderBy(desc(activityTable.createdAt)).limit(5);
  const unread = await db.select({ count: sql<number>`count(*)` }).from(notificationsTable).where(eq(notificationsTable.read, false));
  return res.json({
    students: Number(studentTotals.count),
    outstanding: Number(studentTotals.balance),
    collected: Number(paymentTotals.collected),
    paymentCount: Number(paymentTotals.count),
    unreadNotifications: Number(unread[0].count),
    term: "Term 1 · 2025",
    recentActivity: recentActivity.map(activityDto),
  });
});

router.get("/school/students", async (req, res) => {
  await seedSchoolData();
  const search = String(req.query.search ?? "").trim();
  const students = await db.select().from(studentsTable).orderBy(asc(studentsTable.name));
  const filtered = search
    ? students.filter((student) => `${student.name} ${student.admissionNo} ${student.grade}`.toLowerCase().includes(search.toLowerCase()))
    : students;
  return res.json(filtered.map(studentDto));
});

router.post("/school/students", requireAuth, requireAdmin, async (req, res) => {
  await seedSchoolData();
  const body = req.body as Partial<typeof studentsTable.$inferInsert> & { actor?: string };
  if (!body.name || !body.admissionNo || !body.grade || !body.guardian || !body.guardianPhone) {
    return res.status(400).json({ error: "name, admissionNo, grade, guardian and guardianPhone are required" });
  }
  const [student] = await db.insert(studentsTable).values({
    admissionNo: body.admissionNo,
    name: body.name,
    grade: body.grade,
    guardian: body.guardian,
    guardianPhone: body.guardianPhone,
    balance: Number(body.balance ?? 0),
    status: body.status ?? "Active",
    avatarUrl: body.avatarUrl ?? null,
  }).returning();
  await db.insert(activityTable).values({
    actor: body.actor ?? "Accountant",
    role: "Accountant",
    action: "Added a student",
    detail: `${student.name} to ${student.grade}`,
  });
  await createNotification(
    "New student added",
    `${student.name} was added to ${student.grade}.`,
    "student",
  );
  return res.status(201).json(studentDto(student));
});

router.delete("/school/students/:id", async (req, res) => {
  await seedSchoolData();
  const studentId = Number(req.params.id);
  if (!Number.isInteger(studentId)) {
    return res.status(400).json({ error: "student id must be an integer" });
  }

  const [student] = await db
    .select()
    .from(studentsTable)
    .where(eq(studentsTable.id, studentId));
  if (!student) {
    return res.status(404).json({ error: "student not found" });
  }

  await db.delete(paymentsTable).where(eq(paymentsTable.studentId, studentId));
  await db.delete(studentsTable).where(eq(studentsTable.id, studentId));
  await db.insert(activityTable).values({
    actor: "Accountant",
    role: "Accountant",
    action: "Removed a student",
    detail: `${student.name} from ${student.grade}`,
  });
  return res.status(204).send();
});

router.get("/school/classes", async (_req, res) => {
  await seedSchoolData();
  const classes = await db.select().from(classesTable).orderBy(asc(classesTable.name));
  return res.json(classes.map(classDto));
});

router.post("/school/classes", async (req, res) => {
  await seedSchoolData();
  const body = req.body as Partial<typeof classesTable.$inferInsert> & { actor?: string };
  if (!body.name || !body.stream || !body.teacher) {
    return res.status(400).json({ error: "name, stream and teacher are required" });
  }
  const [schoolClass] = await db.insert(classesTable).values({
    name: body.name,
    stream: body.stream,
    teacher: body.teacher,
    studentsCount: Number(body.studentsCount ?? 0),
    feeTarget: Number(body.feeTarget ?? 0),
    term: body.term ?? "Term 1",
  }).returning();
  await db.insert(activityTable).values({
    actor: body.actor ?? "Accountant",
    role: "Accountant",
    action: "Created a class",
    detail: `${schoolClass.name} ${schoolClass.stream}`,
  });
  return res.status(201).json(classDto(schoolClass));
});

router.delete("/school/classes/:id", async (req, res) => {
  await seedSchoolData();
  const classId = Number(req.params.id);
  if (!Number.isInteger(classId)) {
    return res.status(400).json({ error: "class id must be an integer" });
  }

  const [schoolClass] = await db.select().from(classesTable)
    .where(eq(classesTable.id, classId));
  if (!schoolClass) {
    return res.status(404).json({ error: "class not found" });
  }

  await db.delete(classesTable).where(eq(classesTable.id, classId));
  await db.insert(activityTable).values({
    actor: "Accountant",
    role: "Accountant",
    action: "Deleted a class",
    detail: `${schoolClass.name} ${schoolClass.stream}`,
  });
  return res.status(204).send();
});

router.get("/school/payments", async (_req, res) => {
  await seedSchoolData();
  const payments = await db.select().from(paymentsTable).orderBy(desc(paymentsTable.paidAt)).limit(50);
  return res.json(payments.map(paymentDto));
});

router.post("/school/payments/manual", requireAuth, requireAdmin, async (req, res) => {
  await seedSchoolData();
  const body = req.body as Partial<typeof paymentsTable.$inferInsert> & { actor?: string };
  if (!body.studentId || !body.studentName || !body.amount || !body.method) {
    return res.status(400).json({ error: "studentId, studentName, amount and method are required" });
  }
  const receiptNo = `RCT-${Math.floor(10500 + Math.random() * 400)}`;
  const [payment] = await db.insert(paymentsTable).values({
    receiptNo,
    studentId: Number(body.studentId),
    studentName: body.studentName,
    amount: Number(body.amount),
    method: body.method,
    channel: "Manual",
    status: "Completed",
  }).returning();
  await db.insert(activityTable).values({
    actor: body.actor ?? "Accountant",
    role: "Accountant",
    action: "Recorded manual payment",
    detail: `KES ${Number(body.amount).toLocaleString()} from ${body.studentName}`,
  });

  router.get("/school/payments/pending", async (_req, res) => {
    await seedSchoolData();
    const pending = await db.select().from(pendingPaymentsTable)
      .where(eq(pendingPaymentsTable.status, "Pending"))
      .orderBy(desc(pendingPaymentsTable.createdAt));
    return res.json(pending.map(pendingPaymentDto));
  });

  router.post("/school/payments/pending/:id/resolve", async (req, res) => {
    await seedSchoolData();
    const pendingId = Number(req.params.id);
    const studentId = Number(req.body.studentId);
    if (!Number.isInteger(pendingId) || !Number.isInteger(studentId)) {
      return res.status(400).json({ error: "pending id and studentId must be integers" });
    }
    const [pending] = await db.select().from(pendingPaymentsTable)
      .where(eq(pendingPaymentsTable.id, pendingId));
    const [student] = await db.select().from(studentsTable)
      .where(eq(studentsTable.id, studentId));
    if (!pending || pending.status !== "Pending") {
      return res.status(404).json({ error: "pending payment not found" });
    }
    if (!student || !(JSON.parse(pending.candidateIds) as number[]).includes(studentId)) {
      return res.status(400).json({ error: "student is not a candidate for this payment" });
    }
    const payment = await recordPayment(
      student, pending.amount, pending.transactionId, "TUMA Paybill", "TUMA");
    await db.update(pendingPaymentsTable)
      .set({ status: "Resolved" })
      .where(eq(pendingPaymentsTable.id, pendingId));
    return res.status(201).json(paymentDto(payment));
  });

  router.post("/webhooks/tuma", async (req, res) => {
    const expectedSecret = process.env.TUMA_WEBHOOK_SECRET;
    if (expectedSecret && req.header("x-tuma-signature") !== expectedSecret) {
      return res.status(401).json({ error: "invalid TUMA webhook signature" });
    }
    await seedSchoolData();
    const body = req.body as Record<string, unknown>;
    const transactionId = String(body.transactionId ?? body.transaction_id ?? body.id ?? "").trim();
    const amount = Number(body.amount ?? body.transAmount ?? body.transaction_amount);
    const accountReference = String(
      body.accountNumber ?? body.account_number ?? body.accountReference ?? body.billRefNumber ?? "",
    ).trim();
    const payerName = String(body.studentName ?? body.payerName ?? body.name ?? "").trim();
    if (!transactionId || !Number.isFinite(amount) || amount <= 0 || (!accountReference && !payerName)) {
      return res.status(400).json({ error: "transactionId, amount and account number or payer name are required" });
    }

    const [existing] = await db.select().from(pendingPaymentsTable)
      .where(eq(pendingPaymentsTable.transactionId, transactionId));
    if (existing) return res.json({ status: existing.status, pendingId: existing.id });
    const students = await db.select().from(studentsTable);
    const reference = normalized(accountReference);
    const name = normalized(payerName);
    const referenceMatches = students.filter((student) =>
      reference && normalized(student.admissionNo) === reference);
    const candidates = referenceMatches.length > 0
      ? referenceMatches
      : students.filter((student) => name && normalized(student.name) === name);
    if (candidates.length === 1) {
      const payment = await recordPayment(candidates[0], amount, transactionId, "TUMA Paybill", "TUMA");
      return res.status(201).json({ status: "Applied", payment: paymentDto(payment) });
    }

    const [pending] = await db.insert(pendingPaymentsTable).values({
      transactionId,
      amount,
      accountReference: accountReference || payerName,
      payerName: payerName || accountReference,
      candidateIds: JSON.stringify(candidates.map((student) => student.id)),
    }).returning();
    await createNotification(
      "Payment needs confirmation",
      `KES ${amount.toLocaleString()} from ${payerName || accountReference} needs a student match.`,
      "payment",
    );
    return res.status(202).json({
      status: "PendingConfirmation",
      pending: pendingPaymentDto(pending),
      candidates: candidates.map(studentDto),
    });
  });
  await createNotification(
    "Payment recorded",
    `A KES ${Number(body.amount).toLocaleString()} payment for ${body.studentName} was recorded.`,
    "payment",
  );
  return res.status(201).json(paymentDto(payment));
});

router.post("/school/payments/sync-equity", async (_req, res) => {
  await seedSchoolData();
  await db.insert(activityTable).values({
    actor: "Equity Bank",
    role: "Automated",
    action: "Payment sync completed",
    detail: "No new transactions since the last sync.",
  });
  return res.json({ status: "ready", provider: "Equity Bank", syncedAt: new Date().toISOString(), newPayments: 0 });
});

router.get("/school/activity", async (_req, res) => {
  await seedSchoolData();
  const activity = await db.select().from(activityTable).orderBy(desc(activityTable.createdAt)).limit(50);
  return res.json(activity.map(activityDto));
});

router.get("/school/notifications", async (_req, res) => {
  await seedSchoolData();
  const notifications = await db.select().from(notificationsTable).orderBy(desc(notificationsTable.createdAt)).limit(50);
  return res.json(notifications.map(notificationDto));
});

router.post("/school/notifications/read-all", async (_req, res) => {
  await seedSchoolData();
  await db.update(notificationsTable).set({ read: true }).where(eq(notificationsTable.read, false));
  return res.json({ ok: true });
});

router.get("/school/messages", async (_req, res) => {
  await seedSchoolData();
  const messages = await db.select().from(messagesTable).orderBy(desc(messagesTable.id));
  return res.json(messages.map(messageDto));
});

router.get("/school/events", async (_req, res) => {
  await seedSchoolData();
  const events = await db.select().from(eventsTable)
    .orderBy(asc(eventsTable.eventDate));
  return res.json(events.map(eventDto));
});

router.post("/school/events", async (req, res) => {
  await seedSchoolData();
  const body = req.body as {
    title?: string;
    description?: string;
    eventDate?: string;
    createdBy?: string;
  };
  const eventDate = body.eventDate ? new Date(body.eventDate) : null;
  if (!body.title?.trim() || !eventDate || Number.isNaN(eventDate.getTime())) {
    return res.status(400).json({ error: "title and a valid eventDate are required" });
  }
  const [event] = await db.insert(eventsTable).values({
    title: body.title.trim(),
    description: body.description?.trim() ?? "",
    eventDate,
    createdBy: body.createdBy?.trim() || "Accountant",
  }).returning();
  return res.status(201).json(eventDto(event));
});

router.post("/school/messages", async (req, res) => {
  await seedSchoolData();
  const body = req.body as Partial<typeof messagesTable.$inferInsert>;
  if (!body.campaign || !body.channel || !body.audience) {
    return res.status(400).json({ error: "campaign, channel and audience are required" });
  }
  const [message] = await db.insert(messagesTable).values({
    campaign: body.campaign,
    channel: body.channel,
    audience: body.audience,
    status: "Queued",
    recipientCount: Number(body.recipientCount ?? 0),
  }).returning();
  return res.status(201).json(messageDto(message));
});

export default router;