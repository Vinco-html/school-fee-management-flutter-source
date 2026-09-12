import { createInsertSchema } from "drizzle-zod";
import {
  boolean,
  integer,
  pgTable,
  serial,
  text,
  timestamp,
} from "drizzle-orm/pg-core";

export const studentsTable = pgTable("school_students", {
  id: serial("id").primaryKey(),
  admissionNo: text("admission_no").notNull().unique(),
  name: text("name").notNull(),
  grade: text("grade").notNull(),
  guardian: text("guardian").notNull(),
  guardianPhone: text("guardian_phone").notNull(),
  balance: integer("balance").notNull().default(0),
  status: text("status").notNull().default("Active"),
  avatarUrl: text("avatar_url"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const classesTable = pgTable("school_classes", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  stream: text("stream").notNull(),
  studentsCount: integer("students_count").notNull().default(0),
  teacher: text("teacher").notNull(),
  feeTarget: integer("fee_target").notNull().default(0),
  term: text("term").notNull().default("Term 1"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const paymentsTable = pgTable("school_payments", {
  id: serial("id").primaryKey(),
  receiptNo: text("receipt_no").notNull().unique(),
  studentId: integer("student_id").notNull(),
  studentName: text("student_name").notNull(),
  amount: integer("amount").notNull(),
  method: text("method").notNull(),
  status: text("status").notNull().default("Completed"),
  channel: text("channel").notNull().default("Manual"),
  paidAt: timestamp("paid_at", { withTimezone: true }).notNull().defaultNow(),
});

export const pendingPaymentsTable = pgTable("school_pending_payments", {
  id: serial("id").primaryKey(),
  transactionId: text("transaction_id").notNull().unique(),
  amount: integer("amount").notNull(),
  accountReference: text("account_reference").notNull(),
  payerName: text("payer_name").notNull(),
  candidateIds: text("candidate_ids").notNull().default("[]"),
  status: text("status").notNull().default("Pending"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const activityTable = pgTable("school_activity", {
  id: serial("id").primaryKey(),
  actor: text("actor").notNull(),
  role: text("role").notNull(),
  action: text("action").notNull(),
  detail: text("detail").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const notificationsTable = pgTable("school_notifications", {
  id: serial("id").primaryKey(),
  title: text("title").notNull(),
  body: text("body").notNull(),
  type: text("type").notNull(),
  read: boolean("read").notNull().default(false),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const messagesTable = pgTable("school_messages", {
  id: serial("id").primaryKey(),
  campaign: text("campaign").notNull(),
  channel: text("channel").notNull(),
  audience: text("audience").notNull(),
  status: text("status").notNull().default("Queued"),
  recipientCount: integer("recipient_count").notNull().default(0),
  sentAt: timestamp("sent_at", { withTimezone: true }),
});

export const insertStudentSchema = createInsertSchema(studentsTable).omit({
  id: true,
  createdAt: true,
});
export const insertClassSchema = createInsertSchema(classesTable).omit({
  id: true,
  createdAt: true,
});
export const insertPaymentSchema = createInsertSchema(paymentsTable).omit({
  id: true,
  paidAt: true,
});
export const insertActivitySchema = createInsertSchema(activityTable).omit({
  id: true,
  createdAt: true,
});
export const insertNotificationSchema = createInsertSchema(notificationsTable).omit({
  id: true,
  createdAt: true,
});
export const insertMessageSchema = createInsertSchema(messagesTable).omit({
  id: true,
  sentAt: true,
});

export type Student = typeof studentsTable.$inferSelect;
export type SchoolClass = typeof classesTable.$inferSelect;
export type Payment = typeof paymentsTable.$inferSelect;
export type PendingPayment = typeof pendingPaymentsTable.$inferSelect;
export type Activity = typeof activityTable.$inferSelect;
export type Notification = typeof notificationsTable.$inferSelect;
export type Message = typeof messagesTable.$inferSelect;