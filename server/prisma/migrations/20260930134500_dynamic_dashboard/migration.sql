-- Preserve active legacy data while aligning storage with the completed dashboard.
SET FOREIGN_KEY_CHECKS = 0;

DELETE `SubTask` FROM `SubTask`
INNER JOIN `Task` ON `Task`.`id` = `SubTask`.`taskId`
INNER JOIN `Project` ON `Project`.`id` = `Task`.`projectId`
WHERE `SubTask`.`isDeleted` = 1 OR `Task`.`isDeleted` = 1 OR `Project`.`isDeleted` = 1;
DELETE `Task` FROM `Task`
INNER JOIN `Project` ON `Project`.`id` = `Task`.`projectId`
WHERE `Task`.`isDeleted` = 1 OR `Project`.`isDeleted` = 1;
DELETE FROM `Project` WHERE `isDeleted` = 1;

CREATE TABLE `Workspace` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `ownerId` INTEGER NOT NULL,
    `name` VARCHAR(80) NOT NULL DEFAULT 'My workspace',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    UNIQUE INDEX `Workspace_ownerId_key`(`ownerId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `UserPreference` (
    `userId` INTEGER NOT NULL,
    `theme` ENUM('DARK', 'LIGHT') NOT NULL DEFAULT 'DARK',
    `timezone` VARCHAR(64) NOT NULL DEFAULT 'UTC',
    `version` INTEGER NOT NULL DEFAULT 1,
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`userId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `DataImport` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `userId` INTEGER NOT NULL,
    `idempotencyKey` VARCHAR(100) NOT NULL,
    `source` VARCHAR(40) NOT NULL,
    `status` ENUM('PROCESSING', 'COMPLETED', 'FAILED') NOT NULL DEFAULT 'PROCESSING',
    `projectCount` INTEGER NOT NULL DEFAULT 0,
    `taskCount` INTEGER NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `completedAt` DATETIME(3) NULL,
    UNIQUE INDEX `DataImport_userId_idempotencyKey_key`(`userId`, `idempotencyKey`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

INSERT INTO `Workspace` (`ownerId`, `createdAt`, `updatedAt`)
SELECT `id`, `createdAt`, `updatedAt` FROM `User`;

INSERT INTO `UserPreference` (`userId`, `timezone`, `updatedAt`)
SELECT `id`, COALESCE(NULLIF(`timezone`, ''), 'UTC'), `updatedAt` FROM `User`;

ALTER TABLE `User`
    DROP INDEX `User_googleId_key`,
    DROP INDEX `User_isActive_idx`,
    CHANGE COLUMN `googleId` `googleSubject` VARCHAR(255) NOT NULL,
    CHANGE COLUMN `name` `displayName` VARCHAR(120) NOT NULL,
    ADD COLUMN `status` ENUM('ACTIVE', 'DISABLED') NOT NULL DEFAULT 'ACTIVE';
UPDATE `User` SET `status` = IF(`isActive` = 1, 'ACTIVE', 'DISABLED');
ALTER TABLE `User`
    DROP COLUMN `isActive`,
    DROP COLUMN `locale`,
    DROP COLUMN `timezone`,
    MODIFY `email` VARCHAR(320) NOT NULL,
    MODIFY `avatarUrl` TEXT NULL,
    ADD UNIQUE INDEX `User_googleSubject_key`(`googleSubject`);

ALTER TABLE `Project`
    ADD COLUMN `workspaceId` INTEGER NULL,
    ADD COLUMN `parentProjectId` INTEGER NULL,
    ADD COLUMN `color` CHAR(7) NULL,
    ADD COLUMN `version` INTEGER NOT NULL DEFAULT 1;
UPDATE `Project` p
INNER JOIN `Workspace` w ON w.`ownerId` = p.`userId`
LEFT JOIN `ProjectColor` c ON c.`id` = p.`colorId`
SET p.`workspaceId` = w.`id`, p.`color` = UPPER(COALESCE(c.`hexCode`, '#7383B5'));
ALTER TABLE `Project`
    DROP FOREIGN KEY `Project_colorId_fkey`,
    DROP FOREIGN KEY `Project_priorityId_fkey`,
    DROP FOREIGN KEY `Project_typeId_fkey`,
    DROP FOREIGN KEY `Project_userId_fkey`,
    DROP INDEX `Project_colorId_idx`,
    DROP INDEX `Project_priorityId_idx`,
    DROP INDEX `Project_typeId_idx`,
    DROP INDEX `Project_userId_isDeleted_updatedAt_idx`,
    DROP INDEX `Project_userId_status_isDeleted_idx`,
    DROP COLUMN `colorId`,
    DROP COLUMN `deletedAt`,
    DROP COLUMN `description`,
    DROP COLUMN `dpImage`,
    DROP COLUMN `isDeleted`,
    DROP COLUMN `priorityId`,
    DROP COLUMN `status`,
    DROP COLUMN `typeId`,
    DROP COLUMN `userId`,
    MODIFY `workspaceId` INTEGER NOT NULL,
    MODIFY `color` CHAR(7) NOT NULL,
    MODIFY `name` VARCHAR(60) NOT NULL;

ALTER TABLE `Task`
    ADD COLUMN `workspaceId` INTEGER NULL,
    ADD COLUMN `title` VARCHAR(120) NULL,
    ADD COLUMN `dueDate` DATE NULL,
    ADD COLUMN `statusNew` ENUM('OPEN', 'COMPLETED') NOT NULL DEFAULT 'OPEN',
    ADD COLUMN `completedAt` DATETIME(3) NULL,
    ADD COLUMN `recurrenceFrequency` ENUM('ONE_TIME', 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY', 'CUSTOM') NOT NULL DEFAULT 'ONE_TIME',
    ADD COLUMN `recurrenceInterval` INTEGER NULL,
    ADD COLUMN `recurrenceUnit` ENUM('DAY', 'WEEK', 'MONTH', 'YEAR') NULL,
    ADD COLUMN `recurrenceSeriesId` VARCHAR(36) NULL,
    ADD COLUMN `previousOccurrenceId` INTEGER NULL,
    ADD COLUMN `occurrenceNumber` INTEGER NOT NULL DEFAULT 1,
    ADD COLUMN `version` INTEGER NOT NULL DEFAULT 1;
UPDATE `Task` t
INNER JOIN `Workspace` w ON w.`ownerId` = t.`userId`
SET t.`workspaceId` = w.`id`,
    t.`title` = LEFT(t.`name`, 120),
    t.`dueDate` = DATE(COALESCE(t.`endDateTime`, t.`startDateTime`)),
    t.`statusNew` = IF(t.`status` = 'COMPLETED', 'COMPLETED', 'OPEN'),
    t.`completedAt` = IF(t.`status` = 'COMPLETED', t.`updatedAt`, NULL),
    t.`recurrenceFrequency` = IF(t.`frequency` = 'ONCE', 'ONE_TIME', t.`frequency`),
    t.`recurrenceSeriesId` = IF(t.`frequency` = 'ONCE', NULL, UUID());
ALTER TABLE `Task`
    DROP FOREIGN KEY `Task_priorityId_fkey`,
    DROP FOREIGN KEY `Task_projectId_fkey`,
    DROP FOREIGN KEY `Task_userId_fkey`,
    DROP INDEX `Task_priorityId_idx`,
    DROP INDEX `Task_projectId_idx`,
    DROP INDEX `Task_userId_projectId_isDeleted_idx`,
    DROP INDEX `Task_userId_status_isDeleted_idx`,
    DROP COLUMN `alertBeforeMinutes`,
    DROP COLUMN `alertEnabled`,
    DROP COLUMN `deletedAt`,
    DROP COLUMN `description`,
    DROP COLUMN `durationMinutes`,
    DROP COLUMN `endDateTime`,
    DROP COLUMN `frequency`,
    DROP COLUMN `isDeleted`,
    DROP COLUMN `name`,
    DROP COLUMN `priorityId`,
    DROP COLUMN `startDateTime`,
    DROP COLUMN `status`,
    DROP COLUMN `userId`,
    CHANGE COLUMN `statusNew` `status` ENUM('OPEN', 'COMPLETED') NOT NULL DEFAULT 'OPEN',
    MODIFY `workspaceId` INTEGER NOT NULL,
    MODIFY `title` VARCHAR(120) NOT NULL,
    MODIFY `projectId` INTEGER NULL;

ALTER TABLE `SubTask`
    ADD COLUMN `title` VARCHAR(120) NULL,
    ADD COLUMN `statusNew` ENUM('OPEN', 'COMPLETED') NOT NULL DEFAULT 'OPEN',
    ADD COLUMN `completedAt` DATETIME(3) NULL,
    ADD COLUMN `position` INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN `version` INTEGER NOT NULL DEFAULT 1;
UPDATE `SubTask`
SET `title` = LEFT(`name`, 120),
    `statusNew` = IF(`status` = 'COMPLETED', 'COMPLETED', 'OPEN'),
    `completedAt` = IF(`status` = 'COMPLETED', `updatedAt`, NULL);
ALTER TABLE `SubTask`
    DROP FOREIGN KEY `SubTask_taskId_fkey`,
    DROP FOREIGN KEY `SubTask_userId_fkey`,
    DROP INDEX `SubTask_taskId_idx`,
    DROP INDEX `SubTask_userId_status_isDeleted_idx`,
    DROP INDEX `SubTask_userId_taskId_isDeleted_idx`,
    DROP COLUMN `deletedAt`,
    DROP COLUMN `description`,
    DROP COLUMN `isDeleted`,
    DROP COLUMN `name`,
    DROP COLUMN `status`,
    DROP COLUMN `userId`,
    CHANGE COLUMN `statusNew` `status` ENUM('OPEN', 'COMPLETED') NOT NULL DEFAULT 'OPEN',
    MODIFY `title` VARCHAR(120) NOT NULL;

ALTER TABLE `RefreshSession`
    DROP FOREIGN KEY `RefreshSession_userId_fkey`,
    DROP INDEX `RefreshSession_revokedAt_idx`,
    DROP COLUMN `ipAddress`,
    DROP COLUMN `userAgent`,
    MODIFY `tokenHash` CHAR(64) NOT NULL,
    MODIFY `familyId` VARCHAR(64) NOT NULL,
    MODIFY `revokeReason` VARCHAR(40) NULL,
    ADD UNIQUE INDEX `RefreshSession_tokenHash_key`(`tokenHash`);

DROP TABLE `Priority`;
DROP TABLE `ProjectColor`;
DROP TABLE `ProjectType`;

CREATE INDEX `Project_workspaceId_parentProjectId_idx` ON `Project`(`workspaceId`, `parentProjectId`);
CREATE UNIQUE INDEX `Project_workspaceId_color_key` ON `Project`(`workspaceId`, `color`);
CREATE INDEX `Task_workspaceId_status_dueDate_idx` ON `Task`(`workspaceId`, `status`, `dueDate`);
CREATE INDEX `Task_workspaceId_projectId_status_dueDate_idx` ON `Task`(`workspaceId`, `projectId`, `status`, `dueDate`);
CREATE UNIQUE INDEX `Task_recurrenceSeriesId_dueDate_key` ON `Task`(`recurrenceSeriesId`, `dueDate`);
CREATE INDEX `Subtask_taskId_position_idx` ON `SubTask`(`taskId`, `position`);

ALTER TABLE `RefreshSession` ADD CONSTRAINT `RefreshSession_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `Workspace` ADD CONSTRAINT `Workspace_ownerId_fkey` FOREIGN KEY (`ownerId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `UserPreference` ADD CONSTRAINT `UserPreference_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `DataImport` ADD CONSTRAINT `DataImport_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `Project` ADD CONSTRAINT `Project_workspaceId_fkey` FOREIGN KEY (`workspaceId`) REFERENCES `Workspace`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `Project` ADD CONSTRAINT `Project_parentProjectId_fkey` FOREIGN KEY (`parentProjectId`) REFERENCES `Project`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `Task` ADD CONSTRAINT `Task_workspaceId_fkey` FOREIGN KEY (`workspaceId`) REFERENCES `Workspace`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `Task` ADD CONSTRAINT `Task_projectId_fkey` FOREIGN KEY (`projectId`) REFERENCES `Project`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `Task` ADD CONSTRAINT `Task_previousOccurrenceId_fkey` FOREIGN KEY (`previousOccurrenceId`) REFERENCES `Task`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `SubTask` ADD CONSTRAINT `Subtask_taskId_fkey` FOREIGN KEY (`taskId`) REFERENCES `Task`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `Workspace` ALTER COLUMN `updatedAt` DROP DEFAULT;
ALTER TABLE `UserPreference` ALTER COLUMN `updatedAt` DROP DEFAULT;

SET FOREIGN_KEY_CHECKS = 1;