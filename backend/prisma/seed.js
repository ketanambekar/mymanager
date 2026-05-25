"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
async function main() {
    const projectTypes = [
        "Office",
        "Freelance",
        "Households",
        "Hobby",
        "Relationships",
        "Learning",
        "Passive Income",
    ];
    for (const name of projectTypes) {
        await prisma.projectType.upsert({
            where: { name },
            update: { isDeleted: false, deletedAt: null },
            create: { name },
        });
    }
    const priorities = [
        { code: "P1", title: "Urgent & Important" },
        { code: "P2", title: "Urgent But Not Important" },
        { code: "P3", title: "Not Urgent But Important" },
        { code: "P4", title: "Not Urgent Not Important" },
    ];
    for (const item of priorities) {
        await prisma.priority.upsert({
            where: { code: item.code },
            update: { title: item.title, isDeleted: false, deletedAt: null },
            create: item,
        });
    }
    const colors = [
        { name: "Straw Hat Red", hexCode: "#D62828" },
        { name: "Sunset Orange", hexCode: "#F77F00" },
        { name: "Grand Line Gold", hexCode: "#FCBF49" },
        { name: "Ink Dark", hexCode: "#1D1D1D" },
        { name: "Cloud Light", hexCode: "#F8F9FA" },
    ];
    for (const color of colors) {
        await prisma.projectColor.upsert({
            where: { hexCode: color.hexCode },
            update: { name: color.name, isDeleted: false, deletedAt: null },
            create: color,
        });
    }
    const officeType = await prisma.projectType.findFirstOrThrow({ where: { name: "Office", isDeleted: false } });
    const p1 = await prisma.priority.findFirstOrThrow({ where: { code: "P1", isDeleted: false } });
    const red = await prisma.projectColor.findFirstOrThrow({ where: { hexCode: "#D62828", isDeleted: false } });
    const project = await prisma.project.create({
        data: {
            name: "Launch MyManager MVP",
            description: "First release planning and execution.",
            typeId: officeType.id,
            colorId: red.id,
            priorityId: p1.id,
            status: client_1.ProjectStatus.ACTIVE,
        },
    });
    const task = await prisma.task.create({
        data: {
            projectId: project.id,
            name: "Design core API modules",
            description: "Project, task, and subtask APIs.",
            priorityId: p1.id,
            frequency: client_1.TaskFrequency.ONCE,
            status: client_1.TaskStatus.IN_PROGRESS,
            alertEnabled: true,
            alertBeforeMinutes: 30,
        },
    });
    await prisma.subTask.createMany({
        data: [
            {
                taskId: task.id,
                name: "Create prisma models",
                description: "Design all database relations",
                status: client_1.TaskStatus.COMPLETED,
            },
            {
                taskId: task.id,
                name: "Add repository layer",
                description: "Keep DB logic isolated",
                status: client_1.TaskStatus.PENDING,
            },
        ],
    });
}
main()
    .then(async () => {
    await prisma.$disconnect();
})
    .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
});
