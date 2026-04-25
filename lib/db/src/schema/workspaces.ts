import { pgTable, text, jsonb, timestamp, integer } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";

export const workspacesTable = pgTable("workspaces", {
  id: text("id").primaryKey(),
  invite_code: text("invite_code").unique().notNull(),
  company_name: text("company_name").notNull(),
  password_hash: text("password_hash"),
  revision: integer("revision").notNull().default(0),
  data: jsonb("data"),
  created_at: timestamp("created_at", { withTimezone: true }).defaultNow(),
  updated_at: timestamp("updated_at", { withTimezone: true }).defaultNow(),
});

export const insertWorkspaceSchema = createInsertSchema(workspacesTable).omit({
  created_at: true,
  updated_at: true,
});

export type InsertWorkspace = z.infer<typeof insertWorkspaceSchema>;
export type Workspace = typeof workspacesTable.$inferSelect;
