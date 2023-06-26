/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SCHEMA_CHANGE_LOGS` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `version` varchar(32) NOT NULL,
  `chg_number` varchar(32) NOT NULL,
  `infdba_number` varchar(32) NOT NULL,
  `executed_by` varchar(32) NOT NULL,
  `table_schemas` varchar(255) NOT NULL DEFAULT '',
  `command` varchar(32) NOT NULL DEFAULT '',
  `script` varchar(255) NOT NULL DEFAULT '',
  `executed_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unq_version_script` (`version`,`script`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
INSERT INTO `SCHEMA_CHANGE_LOGS` VALUES (1,'V__20230512141552','000','0101','dbadmin','balance','ALTER TABLE','20230512151203__alter_table_kraken_main.balance_add_index_coin_name.json','2023-06-02 16:15:05');
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `balance` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `coin_name` varchar(64) NOT NULL,
  `amount` decimal(6,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  KEY `idx_coin_name` (`coin_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;
