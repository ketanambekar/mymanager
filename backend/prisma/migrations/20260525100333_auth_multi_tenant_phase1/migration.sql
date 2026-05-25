/*
  Warnings:

  - Added the required column `userId` to the `Project` table without a default value. This is not possible if the table is not empty.
  - Added the required column `userId` to the `SubTask` table without a default value. This is not possible if the table is not empty.
  - Added the required column `userId` to the `Task` table without a default value. This is not possible if the table is not empty.

*/
-- DropIndex
DROP INDEX `Priority_code_key` ON `priority`;

-- DropIndex
DROP INDEX `ProjectColor_hexCode_key` ON `projectcolor`;

-- DropIndex
DROP INDEX `ProjectType_name_key` ON `projecttype`;

-- AlterTable
ALTER TABLE `priority` ADD COLUMN `ownerUserId` INTEGER NULL,
    ADD COLUMN `scope` ENUM('SYSTEM', 'USER') NOT NULL DEFAULT 'USER';

-- AlterTable
ALTER TABLE `project` ADD COLUMN `userId` INTEGER NOT NULL;

-- AlterTable
ALTER TABLE `projectcolor` ADD COLUMN `ownerUserId` INTEGER NULL,
    ADD COLUMN `scope` ENUM('SYSTEM', 'USER') NOT NULL DEFAULT 'USER';

-- AlterTable
ALTER TABLE `projecttype` ADD COLUMN `ownerUserId` INTEGER NULL,
    ADD COLUMN `scope` ENUM('SYSTEM', 'USER') NOT NULL DEFAULT 'USER';

-- AlterTable
ALTER TABLE `subtask` ADD COLUMN `userId` INTEGER NOT NULL;

-- AlterTable
ALTER TABLE `task` ADD COLUMN `userId` INTEGER NOT NULL;

-- CreateTable
CREATE TABLE `User` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `googleId` VARCHAR(191) NOT NULL,
    `email` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `avatarUrl` VARCHAR(191) NULL,
    `authProvider` ENUM('GOOGLE') NOT NULL DEFAULT 'GOOGLE',
    `emailVerifiedAt` DATETIME(3) NULL,
    `timezone` VARCHAR(191) NULL,
    `locale` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    `lastLoginAt` DATETIME(3) NULL,
    `isActive` BOOLEAN NOT NULL DEFAULT true,

    UNIQUE INDEX `User_googleId_key`(`googleId`),
    UNIQUE INDEX `User_email_key`(`email`),
    INDEX `User_isActive_idx`(`isActive`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `RefreshSession` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `userId` INTEGER NOT NULL,
    `tokenHash` VARCHAR(255) NOT NULL,
    `familyId` VARCHAR(120) NOT NULL,
    `replacedBySessionId` INTEGER NULL,
    `userAgent` VARCHAR(191) NULL,
    `ipAddress` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `expiresAt` DATETIME(3) NOT NULL,
    `revokedAt` DATETIME(3) NULL,
    `revokeReason` VARCHAR(191) NULL,

    INDEX `RefreshSession_userId_expiresAt_idx`(`userId`, `expiresAt`),
    INDEX `RefreshSession_familyId_idx`(`familyId`),
    INDEX `RefreshSession_revokedAt_idx`(`revokedAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateIndex
CREATE INDEX `Priority_ownerUserId_isDeleted_idx` ON `Priority`(`ownerUserId`, `isDeleted`);

-- CreateIndex
CREATE INDEX `Priority_scope_isDeleted_idx` ON `Priority`(`scope`, `isDeleted`);

-- CreateIndex
CREATE INDEX `Project_userId_isDeleted_updatedAt_idx` ON `Project`(`userId`, `isDeleted`, `updatedAt`);

-- CreateIndex
CREATE INDEX `Project_userId_status_isDeleted_idx` ON `Project`(`userId`, `status`, `isDeleted`);

-- CreateIndex
CREATE INDEX `ProjectColor_ownerUserId_isDeleted_idx` ON `ProjectColor`(`ownerUserId`, `isDeleted`);

-- CreateIndex
CREATE INDEX `ProjectColor_scope_isDeleted_idx` ON `ProjectColor`(`scope`, `isDeleted`);

-- CreateIndex
CREATE INDEX `ProjectType_ownerUserId_isDeleted_idx` ON `ProjectType`(`ownerUserId`, `isDeleted`);

-- CreateIndex
CREATE INDEX `ProjectType_scope_isDeleted_idx` ON `ProjectType`(`scope`, `isDeleted`);

-- CreateIndex
CREATE INDEX `SubTask_userId_taskId_isDeleted_idx` ON `SubTask`(`userId`, `taskId`, `isDeleted`);

-- CreateIndex
CREATE INDEX `SubTask_userId_status_isDeleted_idx` ON `SubTask`(`userId`, `status`, `isDeleted`);

-- CreateIndex
CREATE INDEX `Task_userId_projectId_isDeleted_idx` ON `Task`(`userId`, `projectId`, `isDeleted`);

-- CreateIndex
CREATE INDEX `Task_userId_status_isDeleted_idx` ON `Task`(`userId`, `status`, `isDeleted`);

-- AddForeignKey
ALTER TABLE `RefreshSession` ADD CONSTRAINT `RefreshSession_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `RefreshSession` ADD CONSTRAINT `RefreshSession_replacedBySessionId_fkey` FOREIGN KEY (`replacedBySessionId`) REFERENCES `RefreshSession`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ProjectType` ADD CONSTRAINT `ProjectType_ownerUserId_fkey` FOREIGN KEY (`ownerUserId`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Priority` ADD CONSTRAINT `Priority_ownerUserId_fkey` FOREIGN KEY (`ownerUserId`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ProjectColor` ADD CONSTRAINT `ProjectColor_ownerUserId_fkey` FOREIGN KEY (`ownerUserId`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Project` ADD CONSTRAINT `Project_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Task` ADD CONSTRAINT `Task_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SubTask` ADD CONSTRAINT `SubTask_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
