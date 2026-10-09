CREATE TABLE `devicesession` (
    `id` VARCHAR(64) NOT NULL,
    `userId` INTEGER NOT NULL,
    `deviceName` VARCHAR(120) NOT NULL,
    `userAgent` VARCHAR(512) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `lastUsedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `expiresAt` DATETIME(3) NOT NULL,
    `revokedAt` DATETIME(3) NULL,
    `revokeReason` VARCHAR(40) NULL,
    INDEX `devicesession_userId_revokedAt_expiresAt_idx` (`userId`, `revokedAt`, `expiresAt`),
    PRIMARY KEY (`id`),
    CONSTRAINT `devicesession_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Preserve existing refresh-cookie logins; one device per rotation family.
INSERT INTO `devicesession` (`id`, `userId`, `deviceName`, `createdAt`, `lastUsedAt`, `expiresAt`, `revokedAt`, `revokeReason`)
SELECT `familyId`, MIN(`userId`), 'Existing browser or device', MIN(`createdAt`), MAX(`createdAt`), MAX(`expiresAt`),
       CASE WHEN SUM(`revokedAt` IS NULL AND `expiresAt` > CURRENT_TIMESTAMP(3)) > 0 THEN NULL ELSE CURRENT_TIMESTAMP(3) END,
       CASE WHEN SUM(`revokedAt` IS NULL AND `expiresAt` > CURRENT_TIMESTAMP(3)) > 0 THEN NULL ELSE 'MIGRATED_INACTIVE' END
FROM `refreshsession`
GROUP BY `familyId`;

CREATE TABLE `loginchallenge` (
    `id` CHAR(36) NOT NULL,
    `codeHash` CHAR(64) NOT NULL,
    `pollTokenHash` CHAR(64) NOT NULL,
    `deviceName` VARCHAR(120) NOT NULL,
    `userAgent` VARCHAR(512) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `expiresAt` DATETIME(3) NOT NULL,
    `approvedByUserId` INTEGER NULL,
    `approvedDeviceId` VARCHAR(64) NULL,
    `approvedAt` DATETIME(3) NULL,
    `deniedAt` DATETIME(3) NULL,
    `consumedAt` DATETIME(3) NULL,
    UNIQUE INDEX `loginchallenge_codeHash_key` (`codeHash`),
    INDEX `loginchallenge_expiresAt_idx` (`expiresAt`),
    PRIMARY KEY (`id`),
    CONSTRAINT `loginchallenge_approvedByUserId_fkey` FOREIGN KEY (`approvedByUserId`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
