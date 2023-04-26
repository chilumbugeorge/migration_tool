CREATE TABLE `SCHEMA_CHANGE_LOGS` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `version` varchar(32) NOT NULL,
  `chg_number` varchar(32) NOT NULL,
  `infdba_number` varchar(32) NOT NULL,
  `executed_by` varchar(32) NOT NULL,
  `table_schemas` varchar(255) NOT NULL DEFAULT '',
  `command` varchar(32) NOT NULL DEFAULT '',
  `script` varchar(255) NOT NULL DEFAULT '',
  `executed_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unq_version_script` (`version`,`script`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
