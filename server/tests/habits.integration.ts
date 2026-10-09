import assert from "node:assert/strict";
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
import { once } from "node:events";
import { readFile } from "node:fs/promises";
import { createRequire } from "node:module";
import path from "node:path";
import test from "node:test";
import { PrismaClient, type Task } from "@prisma/client";
import dotenv from "dotenv";
import { z } from "zod";

test("habit APIs on disposable local MySQL", async (t) => {
  dotenv.config({ quiet: true });
  const originalUrl = process.env.DATABASE_URL ?? process.env.MYSQL_URL;
  assert.ok(originalUrl, "Configure local DATABASE_URL for integration testing");
  const url = new URL(originalUrl);
  assert.ok(["localhost", "127.0.0.1"].includes(url.hostname), "Only local MySQL is allowed");
  const databaseName = `mymanager_habit_test_${crypto.randomBytes(8).toString("hex")}`;
  const admin = new PrismaClient({ datasourceUrl: originalUrl });
  let databaseCreated = false;
  let db: PrismaClient | undefined;
  try {
    await admin.$executeRawUnsafe(`CREATE DATABASE \`${databaseName}\``);
    databaseCreated = true;
    url.pathname = `/${databaseName}`;
    process.env.DATABASE_URL = url.href;
    process.env.NODE_ENV = "test";
    process.env.GOOGLE_CLIENT_ID = "test.apps.googleusercontent.com";
    process.env.JWT_ACCESS_SECRET = "habit-integration-test-secret-at-least-32-characters";
    const require = createRequire(path.resolve("package.json"));
    execFileSync(process.execPath, [require.resolve("prisma/build/index.js"), "migrate", "deploy"], {
      env: process.env, stdio: "pipe",
    });
    const { prisma } = await import("../src/database/prisma.js");
    db = prisma;
    await prisma.$executeRawUnsafe("DROP INDEX `Task_workspaceId_series_occurrence_idx` ON `task`");
    const { habitService } = await import("../src/features/habits/habit_service.js");
    const { taskService } = await import("../src/features/tasks/task_service.js");
    const { issueSession } = await import("../src/features/auth/auth_service.js");
    const { deviceMetadata } = await import("../src/features/auth/device_service.js");
    const { dateInTimeZone } = await import("../src/features/tasks/recurrence.js");
    const { app } = await import("../src/app.js");
    const user = await prisma.user.create({
      data: {
        googleSubject: "habit-owner", email: "habits@example.com", displayName: "Habit owner",
        workspace: { create: {} }, preference: { create: { timezone: "Pacific/Kiritimati" } },
      }, include: { workspace: true },
    });
    assert.ok(user.workspace);
    const workspaceId = user.workspace.id;
    const other = await prisma.user.create({
      data: { googleSubject: "other", email: "other@example.com", displayName: "Other", workspace: { create: {} }, preference: { create: {} } },
      include: { workspace: true },
    });
    assert.ok(other.workspace);
    const project = await prisma.project.create({ data: { workspaceId, name: "Health", color: "#123456" } });
    const series = crypto.randomUUID();
    const dates = ["2026-10-01", "2026-10-02", "2026-10-03", "2026-10-04"];
    const statuses = ["COMPLETED", "SKIPPED", "MISSED", "OPEN"] as const;
    const records: Task[] = [];
    for (let i = 0; i < dates.length; i += 1) {
      records.push(await prisma.task.create({ data: {
        workspaceId, projectId: project.id, title: i === 3 ? "Walk daily" : "Old walk title",
        recurrenceSeriesId: series, recurrenceFrequency: "DAILY", occurrenceNumber: i + 1,
        dueDate: new Date(`${dates[i]}T00:00:00Z`), status: statuses[i],
        completedAt: i === 0 ? new Date("2026-10-05T12:00:00Z") : null,
        closedAt: i === 1 || i === 2 ? new Date("2026-10-05T12:00:00Z") : null,
        closeReason: i === 1 ? "Rest day" : i === 2 ? "Forgot" : null,
      } }));
    }
    const custom = await taskService.create(user.id, workspaceId, { title: "Read daily", recurrence: { frequency: "custom", interval: 1, unit: "day" } });
    const undated = await prisma.task.create({ data: { workspaceId, title: "Undated habit", recurrenceFrequency: "DAILY" } });
    await taskService.create(user.id, workspaceId, { title: "Every two days", recurrence: { frequency: "custom", interval: 2, unit: "day" } });
    await taskService.create(user.id, workspaceId, { title: "Weekly", recurrence: { frequency: "weekly" } });
    await taskService.create(user.id, workspaceId, { title: "One time" });
    const changedSeries = crypto.randomUUID();
    await prisma.task.create({ data: { workspaceId, title: "Stopped daily", recurrenceSeriesId: changedSeries, recurrenceFrequency: "DAILY", occurrenceNumber: 1, dueDate: new Date("2026-10-01") } });
    await prisma.task.create({ data: { workspaceId, title: "Now weekly", recurrenceSeriesId: changedSeries, recurrenceFrequency: "WEEKLY", occurrenceNumber: 2, dueDate: new Date("2026-10-08") } });
    const otherHabit = await taskService.create(other.id, other.workspace.id, { title: "Private habit", recurrence: { frequency: "daily" } });
    const session = await prisma.$transaction((tx) => issueSession(tx, user, deviceMetadata()));
    const server = app.listen(0, "127.0.0.1");
    await once(server, "listening");
    try {
      const address = server.address();
      assert.ok(address && typeof address !== "string");
      const base = `http://127.0.0.1:${address.port}/api/v1/habits`;
      const get = (suffix = "", authorized = true) => fetch(`${base}${suffix}`, {
        headers: authorized ? { authorization: `Bearer ${session.accessToken}` } : {},
      });
      const listSchema = z.object({
        asOfDate: z.string(), timezone: z.string(), nextCursor: z.string().nullable(),
        items: z.array(z.object({
          id: z.string(), title: z.string(), project: z.object({ id: z.number(), name: z.string(), color: z.string() }).nullable(),
          latestOccurrence: z.object({ taskId: z.number(), dueDate: z.string().nullable(), status: z.string(), version: z.number() }),
        }).strict()),
      }).strict();
      const readList = async (suffix = "") => {
        const response = await get(suffix);
        assert.equal(response.status, 200);
        return z.object({ success: z.literal(true), data: listSchema }).parse(await response.json()).data;
      };

      await t.test("additive lookup index applies without changing populated history", async () => {
        const before = await prisma.task.findMany({ orderBy: { id: "asc" } });
        const sql = await readFile(path.resolve("prisma", "migrations", "20261009093000_habit_series_lookup", "migration.sql"), "utf8");
        await prisma.$executeRawUnsafe(sql);
        assert.deepEqual(await prisma.task.findMany({ orderBy: { id: "asc" } }), before);
        const indexes = await prisma.$queryRaw<Array<{ Key_name: string }>>`SHOW INDEX FROM task WHERE Key_name = 'Task_workspaceId_series_occurrence_idx'`;
        assert.equal(indexes.length, 4);
      });

      await t.test("one list row per series; custom one-day included, other cadences excluded", async () => {
        const response = await get();
        assert.equal(response.headers.get("cache-control"), "no-store");
        const list = await readList();
        assert.equal(list.items.length, 3);
        assert.equal(list.timezone, "Pacific/Kiritimati");
        assert.equal(list.asOfDate, dateInTimeZone(new Date(), list.timezone));
        const walk = list.items.find((habit) => habit.id === series)!;
        assert.equal(walk.title, "Walk daily");
        assert.equal(walk.project?.id, project.id);
        assert.equal(walk.latestOccurrence.taskId, records[3].id);
        assert.ok(list.items.some((habit) => habit.id === custom.recurrenceSeriesId));
        assert.ok(list.items.some((habit) => habit.id === `task-${undated.id}`));
        const tasksBefore = await prisma.task.count({ where: { workspaceId } });
        await habitService.calendar(user.id, workspaceId, series, "2026-10");
        assert.equal(await prisma.task.count({ where: { workspaceId } }), tasksBefore, "Habit reads must not materialize tasks");
      });

      await t.test("keyset pagination operates on habits, not occurrences; filters use latest metadata", async () => {
        const full = await readList();
        const ids: string[] = [];
        let cursor: string | null = null;
        do {
          const page = await readList(`?limit=1${cursor ? `&cursor=${encodeURIComponent(cursor)}` : ""}`);
          ids.push(...page.items.map((habit) => habit.id));
          cursor = page.nextCursor;
        } while (cursor);
        assert.deepEqual(ids, full.items.map((habit) => habit.id));
        const filtered = await readList(`?search=Walk&projectId=${project.id}`);
        assert.deepEqual(filtered.items.map((habit) => habit.id), [series]);
        assert.equal((await readList("?search=Old")).items.length, 0);
        assert.equal((await readList("?search=%27%20OR%201%3D1")).items.length, 0);
        assert.equal((await readList("?search=%25")).items.length, 0, "Search percent is literal");
      });

      await t.test("month grid uses due date, carries reasons, distinguishes gaps and exact totals", async () => {
        const calendar = await habitService.calendar(user.id, workspaceId, series, "2026-10");
        assert.equal(calendar.days.length, 31);
        assert.equal(calendar.firstRecordedDueDate, "2026-10-01");
        assert.equal(calendar.undatedOccurrencesCount, 0);
        assert.equal(calendar.days[0].state, "COMPLETED");
        assert.equal(calendar.days[0].occurrence?.completedAt?.toISOString(), "2026-10-05T12:00:00.000Z");
        assert.equal(calendar.days[1].state, "SKIPPED");
        assert.equal(calendar.days[1].occurrence?.closeReason, "Rest day");
        assert.equal(calendar.days[2].state, "MISSED");
        assert.equal(calendar.days[4].state, "NOT_RECORDED");
        assert.equal(calendar.summary.recordedDays, 4);
        assert.equal(calendar.summary.notRecordedDays, 27);
        assert.equal(calendar.summary.completedDays, 1);
        assert.equal(calendar.summary.skippedDays, 1);
        assert.equal(calendar.summary.missedDays, 1);
        assert.equal(calendar.summary.overdueDays + calendar.summary.pendingDays + calendar.summary.scheduledDays, 1);
        const response = await get(`/${series}/calendar?month=2026-10`);
        assert.equal(response.status, 200);
        const json = z.object({ data: z.object({ days: z.array(z.object({ occurrence: z.object({ completedAt: z.string().nullable() }).passthrough().nullable() })) }).passthrough() }).parse(await response.json());
        assert.equal(json.data.days[0].occurrence?.completedAt, "2026-10-05T12:00:00.000Z");
      });

      await t.test("empty/leap/default months and undated legacy habits are honest", async () => {
        const leap = await habitService.calendar(user.id, workspaceId, series, "2024-02");
        assert.equal(leap.days.length, 29);
        assert.equal(leap.summary.notRecordedDays, 29);
        const empty = await habitService.calendar(user.id, workspaceId, `task-${undated.id}`, "2026-10");
        assert.equal(empty.undatedOccurrencesCount, 1);
        assert.equal(empty.firstRecordedDueDate, null);
        assert.equal(empty.summary.recordedDays, 0);
        const current = await habitService.calendar(user.id, workspaceId, series);
        assert.equal(current.month, current.asOfDate.slice(0, 7));
      });

      await t.test("task completion, reopen, skip and miss flow straight into habit history", async () => {
        const today = dateInTimeZone(new Date(), "Pacific/Kiritimati");
        const yesterday = new Date(`${today}T00:00:00Z`);
        yesterday.setUTCDate(yesterday.getUTCDate() - 1);
        const date = yesterday.toISOString().slice(0, 10);
        const daily = await taskService.create(user.id, workspaceId, { title: "Fresh habit", dueDate: date, recurrence: { frequency: "daily" } });
        assert.ok(daily.recurrenceSeriesId);
        const habitId = daily.recurrenceSeriesId;
        await taskService.setCompletion(user.id, workspaceId, daily.id, true, daily.version);
        const list = await habitService.list(user.id, workspaceId, { limit: 100, search: "Fresh habit" });
        assert.equal(list.items.length, 1);
        assert.equal(list.items[0].id, habitId);
        assert.notEqual(list.items[0].latestOccurrence.taskId, daily.id);
        let calendar = await habitService.calendar(user.id, workspaceId, habitId, date.slice(0, 7));
        assert.equal(calendar.days.find((day) => day.date === date)?.state, "COMPLETED");
        await taskService.setCompletion(user.id, workspaceId, daily.id, false, daily.version + 1);
        calendar = await habitService.calendar(user.id, workspaceId, habitId, date.slice(0, 7));
        assert.equal(calendar.days.find((day) => day.date === date)?.state, "OVERDUE");
        await taskService.closeOccurrence(user.id, workspaceId, daily.id, "skip", daily.version + 2, "Rest");
        calendar = await habitService.calendar(user.id, workspaceId, habitId, date.slice(0, 7));
        assert.equal(calendar.days.find((day) => day.date === date)?.state, "SKIPPED");
        assert.equal(calendar.days.find((day) => day.date === date)?.occurrence?.closeReason, "Rest");
        const missed = await taskService.create(user.id, workspaceId, { title: "Miss test", dueDate: date, recurrence: { frequency: "daily" } });
        assert.ok(missed.recurrenceSeriesId);
        await taskService.closeOccurrence(user.id, workspaceId, missed.id, "miss", missed.version, "Forgot");
        assert.equal((await habitService.calendar(user.id, workspaceId, missed.recurrenceSeriesId, date.slice(0, 7))).days.find((day) => day.date === date)?.state, "MISSED");
      });

      await t.test("latest-cadence eligibility, tied occurrence ordering and completed habits", async () => {
        const tiedSeries = crypto.randomUUID();
        await prisma.task.create({ data: {
          workspaceId, title: "Tied older", recurrenceSeriesId: tiedSeries,
          recurrenceFrequency: "DAILY", occurrenceNumber: 1, dueDate: new Date("2026-10-01"),
        } });
        const latest = await prisma.task.create({ data: {
          workspaceId, title: "Tied newer", recurrenceSeriesId: tiedSeries,
          recurrenceFrequency: "DAILY", occurrenceNumber: 1, dueDate: new Date("2026-10-02"), status: "COMPLETED",
        } });
        const list = await habitService.list(user.id, workspaceId, { limit: 100, search: "Tied" });
        assert.equal(list.items.length, 1);
        assert.equal(list.items[0].latestOccurrence.taskId, latest.id);
        const calendar = await habitService.calendar(user.id, workspaceId, tiedSeries, "2026-10");
        assert.equal(calendar.days[1].state, "COMPLETED");
        assert.equal(calendar.days[1].occurrence?.completedAt, null, "Legacy completion without timestamp remains recorded");
        await taskService.update(workspaceId, latest.id, { version: latest.version, recurrence: { frequency: "weekly" } });
        assert.equal((await habitService.list(user.id, workspaceId, { limit: 100, search: "Tied" })).items.length, 0);
        await assert.rejects(habitService.calendar(user.id, workspaceId, tiedSeries, "2026-10"), { code: "HABIT_NOT_FOUND" });
      });

      await t.test("mixed historical cadence and title/date edits do not invent history", async () => {
        await prisma.task.update({ where: { id: records[1].id }, data: { recurrenceFrequency: "WEEKLY" } });
        let calendar = await habitService.calendar(user.id, workspaceId, series, "2026-10");
        assert.equal(calendar.days[1].state, "NOT_DAILY");
        assert.equal(calendar.summary.skippedDays, 0);
        assert.equal(calendar.summary.notDailyDays, 1);
        await taskService.update(workspaceId, records[0].id, { version: 1, dueDate: "2026-10-07", title: "Moved history" });
        calendar = await habitService.calendar(user.id, workspaceId, series, "2026-10");
        assert.equal(calendar.days[0].state, "NOT_RECORDED");
        assert.equal(calendar.days[6].state, "COMPLETED");
        assert.equal(calendar.days[6].occurrence?.title, "Moved history");
        await taskService.remove(workspaceId, records[2].id);
        calendar = await habitService.calendar(user.id, workspaceId, series, "2026-10");
        assert.equal(calendar.days[2].state, "NOT_RECORDED");
      });

      await t.test("tenant boundaries, auth and query validation apply to every surface", async () => {
        assert.equal((await get("", false)).status, 401);
        assert.equal((await get(`/${series}/calendar`, false)).status, 401);
        assert.equal((await get(`/${otherHabit.recurrenceSeriesId}/calendar`)).status, 404);
        assert.equal((await get(`/${changedSeries}/calendar`)).status, 404);
        assert.equal((await get(`/${crypto.randomUUID()}/calendar`)).status, 404);
        assert.equal((await get("/not-valid/calendar")).status, 400);
        for (const query of ["month=2026-13", "month=2026-02-31", "month=2026-1", "month=2200-01"]) {
          assert.equal((await get(`/${series}/calendar?${query}`)).status, 400);
        }
        for (const query of ["limit=101", "limit=0", "cursor=bad", "cursor=task-9999999999", "projectId=-1", "unexpected=1"]) {
          assert.equal((await get(`?${query}`)).status, 400);
        }
        assert.equal((await get("/task-9999999999/calendar")).status, 400);
      });
    } finally {
      await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
    }
  } finally {
    await db?.$disconnect();
    if (databaseCreated) await admin.$executeRawUnsafe(`DROP DATABASE \`${databaseName}\``);
    await admin.$disconnect();
  }
});
