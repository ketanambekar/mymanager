import { AuthProvider, MasterScope, PrismaClient, ProjectStatus, TaskFrequency, TaskStatus } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  await prisma.refreshSession.deleteMany();
  await prisma.subTask.deleteMany();
  await prisma.task.deleteMany();
  await prisma.project.deleteMany();
  await prisma.projectType.deleteMany();
  await prisma.priority.deleteMany();
  await prisma.projectColor.deleteMany();
  await prisma.user.deleteMany();

  const demoUser = await prisma.user.create({
    data: {
      googleId: "seed-google-user-id",
      email: "demo@mymanager.local",
      name: "Demo User",
      authProvider: AuthProvider.GOOGLE,
      emailVerifiedAt: new Date(),
      isActive: true,
      lastLoginAt: new Date(),
    },
  });

  const projectTypes = [
    { name: "Office", iconUrl: "https://img.icons8.com/color/96/briefcase.png" },
    { name: "Freelance", iconUrl: "https://img.icons8.com/color/96/laptop--v1.png" },
    { name: "Households", iconUrl: "https://img.icons8.com/color/96/home--v1.png" },
    { name: "Hobby", iconUrl: "https://img.icons8.com/color/96/controller.png" },
    { name: "Relationships", iconUrl: "https://img.icons8.com/color/96/filled-like.png" },
    { name: "Learning", iconUrl: "https://img.icons8.com/color/96/study.png" },
    { name: "Passive Income", iconUrl: "https://img.icons8.com/color/96/combo-chart--v1.png" },
  ];

  for (const projectType of projectTypes) {
    await prisma.projectType.create({
      data: {
        name: projectType.name,
        iconUrl: projectType.iconUrl,
        scope: MasterScope.SYSTEM,
      },
    });
  }

  const priorities = [
    { code: "P1", title: "Urgent & Important" },
    { code: "P2", title: "Urgent But Not Important" },
    { code: "P3", title: "Not Urgent But Important" },
    { code: "P4", title: "Not Urgent Not Important" },
  ];

  for (const item of priorities) {
    await prisma.priority.create({
      data: {
        ...item,
        scope: MasterScope.SYSTEM,
      },
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
    await prisma.projectColor.create({
      data: {
        ...color,
        scope: MasterScope.SYSTEM,
      },
    });
  }

  const officeType = await prisma.projectType.findFirstOrThrow({ where: { name: "Office", isDeleted: false } });
  const p1 = await prisma.priority.findFirstOrThrow({ where: { code: "P1", isDeleted: false } });
  const red = await prisma.projectColor.findFirstOrThrow({ where: { hexCode: "#D62828", isDeleted: false } });

  const project = await prisma.project.create({
    data: {
      userId: demoUser.id,
      name: "Launch MyManager MVP",
      description: "First release planning and execution.",
      typeId: officeType.id,
      colorId: red.id,
      priorityId: p1.id,
      status: ProjectStatus.ACTIVE,
    },
  });

  const task = await prisma.task.create({
    data: {
      userId: demoUser.id,
      projectId: project.id,
      name: "Design core API modules",
      description: "Project, task, and subtask APIs.",
      priorityId: p1.id,
      frequency: TaskFrequency.ONCE,
      status: TaskStatus.IN_PROGRESS,
      alertEnabled: true,
      alertBeforeMinutes: 30,
    },
  });

  await prisma.subTask.createMany({
    data: [
      {
        userId: demoUser.id,
        taskId: task.id,
        name: "Create prisma models",
        description: "Design all database relations",
        status: TaskStatus.COMPLETED,
      },
      {
        userId: demoUser.id,
        taskId: task.id,
        name: "Add repository layer",
        description: "Keep DB logic isolated",
        status: TaskStatus.PENDING,
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
