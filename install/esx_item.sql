-- Wird bei ESX-Servern beim Start automatisch eingetragen (Config.AutoDatabaseSetup).
-- Nur bei AutoDatabaseSetup = false manuell importieren.
INSERT IGNORE INTO `items` (`name`, `label`, `weight`) VALUES ('mietvertrag', 'Mietvertrag', 1);
