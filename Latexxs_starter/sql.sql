CREATE TABLE IF NOT EXISTS `starter_claims` (
    `identifier` VARCHAR(50) NOT NULL,
    `claimed` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
