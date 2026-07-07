-- ============================================================
-- OPTIONAL – wird beim Start automatisch angelegt (Config.AutoDatabaseSetup)
-- Dient der Protokollierung abgeschlossener Vermietungen (Statistik/Übersicht).
-- Manuelles Importieren ist nur nötig, wenn AutoDatabaseSetup = false ist.
-- ============================================================

CREATE TABLE IF NOT EXISTS `MB_Fahrzeugvermitung_history` (
    `id`         INT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(64)  NOT NULL,
    `location`   VARCHAR(64)  NOT NULL,
    `vehicle`    VARCHAR(64)  NOT NULL,
    `plate`      VARCHAR(16)  NOT NULL,
    `price`      INT NOT NULL,
    `minutes`    INT NOT NULL,
    `payment`    VARCHAR(16)  NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
