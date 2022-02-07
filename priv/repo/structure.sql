-- MariaDB dump 10.19  Distrib 10.5.13-MariaDB, for Linux (x86_64)
--
-- Host: db    Database: ask_dev
-- ------------------------------------------------------
-- Server version	5.7.22

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `activity_log`
--

DROP TABLE IF EXISTS `activity_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `activity_log` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `project_id` bigint(20) unsigned DEFAULT NULL,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `entity_type` varchar(255) DEFAULT NULL,
  `entity_id` int(11) DEFAULT NULL,
  `action` varchar(255) DEFAULT NULL,
  `metadata` text,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `remote_ip` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `activity_log_project_id_fkey` (`project_id`),
  KEY `activity_log_user_id_fkey` (`user_id`),
  CONSTRAINT `activity_log_project_id_fkey` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`),
  CONSTRAINT `activity_log_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=441 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `audios`
--

DROP TABLE IF EXISTS `audios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `audios` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) CHARACTER SET ascii DEFAULT NULL,
  `data` mediumblob,
  `filename` varchar(255) DEFAULT NULL,
  `source` varchar(255) DEFAULT NULL,
  `duration` int(11) DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `channels`
--

DROP TABLE IF EXISTS `channels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `channels` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `provider` varchar(255) DEFAULT NULL,
  `settings` text,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `base_url` varchar(255) DEFAULT NULL,
  `patterns` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `channels_user_id_index` (`user_id`),
  CONSTRAINT `channels_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `completed_respondents`
--

DROP TABLE IF EXISTS `completed_respondents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `completed_respondents` (
  `survey_id` bigint(20) unsigned NOT NULL,
  `questionnaire_id` int(11) NOT NULL,
  `quota_bucket_id` int(11) NOT NULL,
  `mode` varchar(255) NOT NULL,
  `date` date NOT NULL,
  `count` int(11) DEFAULT '0',
  PRIMARY KEY (`survey_id`,`questionnaire_id`,`quota_bucket_id`,`mode`,`date`),
  CONSTRAINT `completed_respondents_survey_id_fkey` FOREIGN KEY (`survey_id`) REFERENCES `surveys` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `floip_endpoints`
--

DROP TABLE IF EXISTS `floip_endpoints`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `floip_endpoints` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `survey_id` bigint(20) unsigned DEFAULT NULL,
  `uri` varchar(255) DEFAULT NULL,
  `last_pushed_response_id` bigint(20) unsigned DEFAULT NULL,
  `retries` int(11) DEFAULT '0',
  `name` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `auth_token` varchar(255) DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `floip_endpoints_survey_id_uri_auth_token_index` (`survey_id`,`uri`,`auth_token`),
  KEY `floip_endpoints_last_pushed_response_id_fkey` (`last_pushed_response_id`),
  KEY `floip_endpoints_survey_id_index` (`survey_id`),
  CONSTRAINT `floip_endpoints_last_pushed_response_id_fkey` FOREIGN KEY (`last_pushed_response_id`) REFERENCES `responses` (`id`),
  CONSTRAINT `floip_endpoints_survey_id_fkey` FOREIGN KEY (`survey_id`) REFERENCES `surveys` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `folders`
--

DROP TABLE IF EXISTS `folders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `folders` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `project_id` bigint(20) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `folders_name_project_id_index` (`name`,`project_id`),
  KEY `folders_project_id_index` (`project_id`),
  CONSTRAINT `folders_project_id_fkey` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `invites`
--

DROP TABLE IF EXISTS `invites`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `invites` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(255) DEFAULT NULL,
  `level` varchar(255) DEFAULT NULL,
  `project_id` bigint(20) unsigned DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `inviter_email` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `project_id` (`project_id`,`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `oauth_tokens`
--

DROP TABLE IF EXISTS `oauth_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `oauth_tokens` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `provider` varchar(255) DEFAULT NULL,
  `access_token` text,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `expires_at` datetime DEFAULT NULL,
  `base_url` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `oauth_tokens_user_id_provider_base_url_index` (`user_id`,`provider`,`base_url`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `panel_surveys`
--

DROP TABLE IF EXISTS `panel_surveys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `panel_surveys` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `project_id` bigint(20) unsigned DEFAULT NULL,
  `folder_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `panel_surveys_project_id_fkey` (`project_id`),
  KEY `panel_surveys_folder_id_fkey` (`folder_id`),
  CONSTRAINT `panel_surveys_folder_id_fkey` FOREIGN KEY (`folder_id`) REFERENCES `folders` (`id`),
  CONSTRAINT `panel_surveys_project_id_fkey` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `project_channels`
--

DROP TABLE IF EXISTS `project_channels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `project_channels` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `channel_id` bigint(20) unsigned DEFAULT NULL,
  `project_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `project_channels_channel_id_project_id_index` (`channel_id`,`project_id`),
  KEY `project_channels_project_id_fkey` (`project_id`),
  CONSTRAINT `project_channels_channel_id_fkey` FOREIGN KEY (`channel_id`) REFERENCES `channels` (`id`) ON DELETE CASCADE,
  CONSTRAINT `project_channels_project_id_fkey` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `project_memberships`
--

DROP TABLE IF EXISTS `project_memberships`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `project_memberships` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `project_id` bigint(20) unsigned DEFAULT NULL,
  `level` varchar(255) DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `project_memberships_user_id_fkey` (`user_id`),
  KEY `project_memberships_project_id_fkey` (`project_id`),
  CONSTRAINT `project_memberships_project_id_fkey` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `project_memberships_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `projects`
--

DROP TABLE IF EXISTS `projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `projects` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `salt` varchar(255) DEFAULT NULL,
  `colour_scheme` varchar(255) DEFAULT 'default',
  `archived` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `questionnaire_variables`
--

DROP TABLE IF EXISTS `questionnaire_variables`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `questionnaire_variables` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `project_id` bigint(20) unsigned DEFAULT NULL,
  `questionnaire_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `questionnaire_variables_project_id_index` (`project_id`),
  KEY `questionnaire_variables_questionnaire_id_index` (`questionnaire_id`),
  CONSTRAINT `questionnaire_variables_project_id_fkey` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`),
  CONSTRAINT `questionnaire_variables_questionnaire_id_fkey` FOREIGN KEY (`questionnaire_id`) REFERENCES `questionnaires` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=92 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `questionnaires`
--

DROP TABLE IF EXISTS `questionnaires`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `questionnaires` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `project_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `modes` varchar(255) DEFAULT NULL,
  `steps` longtext,
  `languages` text,
  `default_language` varchar(255) DEFAULT NULL,
  `valid` tinyint(1) DEFAULT NULL,
  `settings` text,
  `snapshot_of` bigint(20) unsigned DEFAULT NULL,
  `quota_completed_steps` longtext,
  `deleted` tinyint(1) DEFAULT '0',
  `description` text,
  `partial_relevant_config` varchar(255) DEFAULT NULL,
  `archived` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `questionnaires_project_id_index` (`project_id`),
  KEY `questionnaires_snapshot_of_fkey` (`snapshot_of`),
  CONSTRAINT `questionnaires_project_id_fkey` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`),
  CONSTRAINT `questionnaires_snapshot_of_fkey` FOREIGN KEY (`snapshot_of`) REFERENCES `questionnaires` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `quota_buckets`
--

DROP TABLE IF EXISTS `quota_buckets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `quota_buckets` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `condition` text,
  `quota` int(11) DEFAULT NULL,
  `count` int(11) DEFAULT NULL,
  `survey_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `quota_buckets_survey_id_fkey` (`survey_id`),
  CONSTRAINT `quota_buckets_survey_id_fkey` FOREIGN KEY (`survey_id`) REFERENCES `surveys` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rememberables`
--

DROP TABLE IF EXISTS `rememberables`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rememberables` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `series_hash` varchar(255) DEFAULT NULL,
  `token_hash` varchar(255) DEFAULT NULL,
  `token_created_at` datetime DEFAULT NULL,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `rememberables_user_id_series_hash_token_hash_index` (`user_id`,`series_hash`,`token_hash`),
  KEY `rememberables_user_id_index` (`user_id`),
  KEY `rememberables_series_hash_index` (`series_hash`),
  KEY `rememberables_token_hash_index` (`token_hash`),
  CONSTRAINT `rememberables_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `respondent_disposition_history`
--

DROP TABLE IF EXISTS `respondent_disposition_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `respondent_disposition_history` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `disposition` varchar(255) DEFAULT NULL,
  `respondent_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `mode` varchar(255) DEFAULT NULL,
  `survey_id` bigint(20) unsigned DEFAULT NULL,
  `respondent_hashed_number` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `respondent_disposition_history_respondent_id_index` (`respondent_id`),
  KEY `respondent_disposition_history_survey_id_id_index` (`survey_id`,`id`),
  CONSTRAINT `respondent_disposition_history_respondent_id_fkey` FOREIGN KEY (`respondent_id`) REFERENCES `respondents` (`id`) ON DELETE CASCADE,
  CONSTRAINT `respondent_disposition_history_survey_id_fkey` FOREIGN KEY (`survey_id`) REFERENCES `surveys` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `respondent_group_channels`
--

DROP TABLE IF EXISTS `respondent_group_channels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `respondent_group_channels` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `respondent_group_id` bigint(20) unsigned DEFAULT NULL,
  `channel_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `mode` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `respondent_group_channels_respondent_group_id_index` (`respondent_group_id`),
  KEY `respondent_group_channels_channel_id_index` (`channel_id`),
  CONSTRAINT `respondent_group_channels_channel_id_fkey` FOREIGN KEY (`channel_id`) REFERENCES `channels` (`id`),
  CONSTRAINT `respondent_group_channels_respondent_group_id_fkey` FOREIGN KEY (`respondent_group_id`) REFERENCES `respondent_groups` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `respondent_groups`
--

DROP TABLE IF EXISTS `respondent_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `respondent_groups` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `survey_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `sample` longtext,
  `respondents_count` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `respondent_groups_survey_id_fkey` (`survey_id`),
  CONSTRAINT `respondent_groups_survey_id_fkey` FOREIGN KEY (`survey_id`) REFERENCES `surveys` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `respondent_stats`
--

DROP TABLE IF EXISTS `respondent_stats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `respondent_stats` (
  `survey_id` bigint(20) unsigned NOT NULL,
  `questionnaire_id` int(11) NOT NULL,
  `state` varchar(255) NOT NULL,
  `disposition` varchar(255) NOT NULL,
  `quota_bucket_id` int(11) NOT NULL,
  `mode` varchar(255) NOT NULL,
  `count` int(11) DEFAULT '0',
  PRIMARY KEY (`survey_id`,`questionnaire_id`,`state`,`disposition`,`quota_bucket_id`,`mode`),
  CONSTRAINT `respondent_stats_survey_id_fkey` FOREIGN KEY (`survey_id`) REFERENCES `surveys` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `respondents`
--

DROP TABLE IF EXISTS `respondents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `respondents` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(255) DEFAULT NULL,
  `survey_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `state` varchar(255) DEFAULT 'pending',
  `session` text,
  `completed_at` datetime DEFAULT NULL,
  `timeout_at` datetime DEFAULT NULL,
  `sanitized_phone_number` varchar(255) DEFAULT NULL,
  `quota_bucket_id` int(11) DEFAULT NULL,
  `questionnaire_id` bigint(20) unsigned DEFAULT NULL,
  `mode` varchar(255) DEFAULT NULL,
  `respondent_group_id` bigint(20) unsigned DEFAULT NULL,
  `hashed_number` varchar(255) DEFAULT NULL,
  `disposition` varchar(255) DEFAULT NULL,
  `lock_version` int(11) DEFAULT '1',
  `mobile_web_cookie_code` varchar(255) DEFAULT NULL,
  `language` varchar(255) DEFAULT NULL,
  `effective_modes` varchar(255) DEFAULT NULL,
  `stats` longtext NOT NULL,
  `section_order` varchar(255) DEFAULT NULL,
  `retry_stat_id` bigint(20) unsigned DEFAULT NULL,
  `canonical_phone_number` varchar(255) DEFAULT NULL,
  `user_stopped` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `respondents_survey_id_index` (`survey_id`),
  KEY `respondents_survey_id_state_index` (`survey_id`,`state`),
  KEY `respondents_state_timeout_at_index` (`state`,`timeout_at`),
  KEY `respondents_questionnaire_id_fkey` (`questionnaire_id`),
  KEY `respondents_respondent_group_id_fkey` (`respondent_group_id`),
  KEY `respondents_hashed_number_index` (`hashed_number`),
  KEY `respondents_updated_at_index` (`updated_at`),
  KEY `respondents_sanitized_phone_number_index` (`sanitized_phone_number`),
  KEY `respondents_retry_stat_id_fkey` (`retry_stat_id`),
  KEY `respondents_canonical_phone_number_index` (`canonical_phone_number`),
  CONSTRAINT `respondents_questionnaire_id_fkey` FOREIGN KEY (`questionnaire_id`) REFERENCES `questionnaires` (`id`),
  CONSTRAINT `respondents_respondent_group_id_fkey` FOREIGN KEY (`respondent_group_id`) REFERENCES `respondent_groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `respondents_retry_stat_id_fkey` FOREIGN KEY (`retry_stat_id`) REFERENCES `retry_stats` (`id`) ON DELETE CASCADE,
  CONSTRAINT `respondents_survey_id_fkey` FOREIGN KEY (`survey_id`) REFERENCES `surveys` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER respondents_ins
AFTER INSERT ON respondents
FOR EACH ROW
BEGIN

  INSERT INTO respondent_stats(survey_id, questionnaire_id, state, disposition, quota_bucket_id, mode, `count`)
  VALUES (NEW.survey_id, IFNULL(NEW.questionnaire_id, 0), NEW.state, NEW.disposition, IFNULL(NEW.quota_bucket_id, 0), IFNULL(NEW.mode, ''), 1)
  ON DUPLICATE KEY UPDATE `count` = `count` + 1
  ;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER on_respondents_completed_ins
AFTER INSERT ON respondents
FOR EACH ROW
BEGIN

  IF NEW.disposition = 'completed' THEN
    INSERT INTO completed_respondents(survey_id, questionnaire_id, quota_bucket_id, mode, date, count)
    VALUES (NEW.survey_id, IFNULL(NEW.questionnaire_id, 0), IFNULL(NEW.quota_bucket_id, 0), IFNULL(NEW.mode, ''), DATE(NEW.updated_at), 1)
    ON DUPLICATE KEY UPDATE `count` = `count` + 1;
  END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER respondents_upd
AFTER UPDATE ON respondents
FOR EACH ROW
BEGIN

  UPDATE respondent_stats
     SET `count` = `count` - 1
   WHERE survey_id = OLD.survey_id
     AND questionnaire_id = IFNULL(OLD.questionnaire_id, 0)
     AND state = OLD.state
     AND disposition = OLD.disposition
     AND quota_bucket_id = IFNULL(OLD.quota_bucket_id, 0)
     AND mode = IFNULL(OLD.mode, '')
  ;

  INSERT INTO respondent_stats(survey_id, questionnaire_id, state, disposition, quota_bucket_id, mode, `count`)
  VALUES (NEW.survey_id, IFNULL(NEW.questionnaire_id, 0), NEW.state, NEW.disposition, IFNULL(NEW.quota_bucket_id, 0), IFNULL(NEW.mode, ''), 1)
  ON DUPLICATE KEY UPDATE `count` = `count` + 1
  ;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER on_respondents_completed_upd
AFTER UPDATE ON respondents
FOR EACH ROW
BEGIN

  IF NEW.disposition = 'completed' AND OLD.disposition <> 'completed' THEN
    INSERT INTO completed_respondents(survey_id, questionnaire_id, quota_bucket_id, mode, date, count)
    VALUES (NEW.survey_id, IFNULL(NEW.questionnaire_id, 0), IFNULL(NEW.quota_bucket_id, 0), IFNULL(NEW.mode, ''), DATE(NEW.updated_at), 1)
    ON DUPLICATE KEY UPDATE `count` = `count` + 1;
  ELSEIF NEW.disposition <> 'completed' AND OLD.disposition = 'completed' THEN
    UPDATE completed_respondents
       SET `count` = `count` - 1
     WHERE survey_id = OLD.survey_id
       AND questionnaire_id = IFNULL(OLD.questionnaire_id, 0)
       AND quota_bucket_id = IFNULL(OLD.quota_bucket_id, 0)
       AND mode = IFNULL(OLD.mode, '')
       AND date = DATE(OLD.updated_at);
  END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER respondents_del
AFTER DELETE ON respondents
FOR EACH ROW
BEGIN

  UPDATE respondent_stats
     SET `count` = `count` - 1
   WHERE survey_id = OLD.survey_id
     AND questionnaire_id = IFNULL(OLD.questionnaire_id, 0)
     AND state = OLD.state
     AND disposition = OLD.disposition
     AND quota_bucket_id = IFNULL(OLD.quota_bucket_id, 0)
     AND mode = IFNULL(OLD.mode, '')
  ;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER on_respondents_completed_del
AFTER DELETE ON respondents
FOR EACH ROW
BEGIN

  IF OLD.disposition = 'completed' THEN
    UPDATE completed_respondents
       SET `count` = `count` - 1
     WHERE survey_id = OLD.survey_id
       AND questionnaire_id = IFNULL(OLD.questionnaire_id, 0)
       AND quota_bucket_id = IFNULL(OLD.quota_bucket_id, 0)
       AND mode = IFNULL(OLD.mode, '')
       AND date = DATE(OLD.updated_at);
  END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `responses`
--

DROP TABLE IF EXISTS `responses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `responses` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `field_name` varchar(255) DEFAULT NULL,
  `value` varchar(255) DEFAULT NULL,
  `respondent_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `responses_respondent_id_index` (`respondent_id`),
  CONSTRAINT `responses_respondent_id_fkey` FOREIGN KEY (`respondent_id`) REFERENCES `respondents` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `retry_stats`
--

DROP TABLE IF EXISTS `retry_stats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `retry_stats` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `mode` varchar(255) NOT NULL,
  `attempt` int(11) NOT NULL,
  `retry_time` varchar(255) NOT NULL,
  `count` int(11) NOT NULL,
  `survey_id` bigint(20) unsigned NOT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `ivr_active` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `retry_stats_mode_attempt_retry_time_ivr_active_survey_id_index` (`mode`,`attempt`,`retry_time`,`ivr_active`,`survey_id`),
  KEY `retry_stats_survey_id_fkey` (`survey_id`),
  CONSTRAINT `retry_stats_survey_id_fkey` FOREIGN KEY (`survey_id`) REFERENCES `surveys` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `schema_migrations`
--

DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schema_migrations` (
  `version` bigint(20) NOT NULL,
  `inserted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `token` varchar(255) DEFAULT NULL,
  `user_type` varchar(255) DEFAULT NULL,
  `user_id` varchar(255) DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `sessions_token_index` (`token`),
  KEY `sessions_user_id_index` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `short_links`
--

DROP TABLE IF EXISTS `short_links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `short_links` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `hash` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `target` varchar(255) DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `survey_log_entries`
--

DROP TABLE IF EXISTS `survey_log_entries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `survey_log_entries` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `survey_id` int(11) DEFAULT NULL,
  `mode` varchar(255) DEFAULT NULL,
  `respondent_id` int(11) DEFAULT NULL,
  `respondent_hashed_number` varchar(255) DEFAULT NULL,
  `channel_id` int(11) DEFAULT NULL,
  `disposition` varchar(255) DEFAULT NULL,
  `action_type` varchar(255) DEFAULT NULL,
  `action_data` longtext,
  `timestamp` datetime DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `survey_log_entries_survey_id_respondent_hashed_number_id_index` (`survey_id`,`respondent_hashed_number`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=59 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `survey_questionnaires`
--

DROP TABLE IF EXISTS `survey_questionnaires`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `survey_questionnaires` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `survey_id` bigint(20) unsigned DEFAULT NULL,
  `questionnaire_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `survey_questionnaires_survey_id_index` (`survey_id`),
  KEY `survey_questionnaires_questionnaire_id_index` (`questionnaire_id`),
  CONSTRAINT `survey_questionnaires_questionnaire_id_fkey` FOREIGN KEY (`questionnaire_id`) REFERENCES `questionnaires` (`id`),
  CONSTRAINT `survey_questionnaires_survey_id_fkey` FOREIGN KEY (`survey_id`) REFERENCES `surveys` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `surveys`
--

DROP TABLE IF EXISTS `surveys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `surveys` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `project_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `state` varchar(255) DEFAULT 'pending',
  `cutoff` int(11) DEFAULT NULL,
  `mode` text,
  `sms_retry_configuration` text,
  `ivr_retry_configuration` text,
  `started_at` datetime DEFAULT NULL,
  `quota_vars` text,
  `comparisons` text,
  `fallback_delay` varchar(255) DEFAULT NULL,
  `count_partial_results` tinyint(1) DEFAULT '0',
  `mobileweb_retry_configuration` text,
  `simulation` tinyint(1) DEFAULT '0',
  `exit_code` int(11) DEFAULT NULL,
  `exit_message` varchar(255) DEFAULT NULL,
  `schedule` text,
  `floip_package_id` varchar(255) DEFAULT NULL,
  `description` text,
  `locked` tinyint(1) DEFAULT '0',
  `folder_id` bigint(20) unsigned DEFAULT NULL,
  `ended_at` datetime DEFAULT NULL,
  `incentives_enabled` tinyint(1) DEFAULT '1',
  `first_window_started_at` datetime DEFAULT NULL,
  `last_window_ends_at` datetime DEFAULT NULL,
  `panel_survey_id` bigint(20) unsigned DEFAULT NULL,
  `generates_panel_survey` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `surveys_project_id_index` (`project_id`),
  KEY `surveys_id_index` (`id`),
  KEY `surveys_folder_id_index` (`folder_id`),
  KEY `surveys_panel_survey_id_fkey` (`panel_survey_id`),
  CONSTRAINT `surveys_folder_id_fkey` FOREIGN KEY (`folder_id`) REFERENCES `folders` (`id`),
  CONSTRAINT `surveys_panel_survey_id_fkey` FOREIGN KEY (`panel_survey_id`) REFERENCES `panel_surveys` (`id`),
  CONSTRAINT `surveys_project_id_fkey` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `translations`
--

DROP TABLE IF EXISTS `translations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `translations` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `mode` varchar(255) DEFAULT NULL,
  `source_lang` varchar(255) DEFAULT NULL,
  `source_text` longtext,
  `target_lang` varchar(255) DEFAULT NULL,
  `target_text` longtext,
  `project_id` bigint(20) unsigned DEFAULT NULL,
  `questionnaire_id` bigint(20) unsigned DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `scope` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `translations_project_id_index` (`project_id`),
  KEY `translations_questionnaire_id_index` (`questionnaire_id`),
  CONSTRAINT `translations_project_id_fkey` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`),
  CONSTRAINT `translations_questionnaire_id_fkey` FOREIGN KEY (`questionnaire_id`) REFERENCES `questionnaires` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) DEFAULT NULL,
  `encrypted_password` varchar(255) DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `settings` text,
  `password_hash` varchar(255) DEFAULT NULL,
  `reset_password_token` varchar(255) DEFAULT NULL,
  `reset_password_sent_at` datetime DEFAULT NULL,
  `confirmation_token` varchar(255) DEFAULT NULL,
  `confirmed_at` datetime DEFAULT NULL,
  `confirmation_sent_at` datetime DEFAULT NULL,
  `name` varchar(255) DEFAULT '',
  `remember_created_at` datetime DEFAULT NULL,
  `unconfirmed_email` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `users_email_index` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping routines for database 'ask_dev'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2022-01-31 10:39:36
INSERT INTO `schema_migrations` (version) VALUES (20160812145257);
INSERT INTO `schema_migrations` (version) VALUES (20160816183915);
INSERT INTO `schema_migrations` (version) VALUES (20160830200454);
INSERT INTO `schema_migrations` (version) VALUES (20160902185110);
INSERT INTO `schema_migrations` (version) VALUES (20160905135419);
INSERT INTO `schema_migrations` (version) VALUES (20160905173031);
INSERT INTO `schema_migrations` (version) VALUES (20160906161147);
INSERT INTO `schema_migrations` (version) VALUES (20160906173441);
INSERT INTO `schema_migrations` (version) VALUES (20160906192317);
INSERT INTO `schema_migrations` (version) VALUES (20160908162553);
INSERT INTO `schema_migrations` (version) VALUES (20160909144711);
INSERT INTO `schema_migrations` (version) VALUES (20160909150600);
INSERT INTO `schema_migrations` (version) VALUES (20160909152241);
INSERT INTO `schema_migrations` (version) VALUES (20160909195628);
INSERT INTO `schema_migrations` (version) VALUES (20160913171925);
INSERT INTO `schema_migrations` (version) VALUES (20160913180125);
INSERT INTO `schema_migrations` (version) VALUES (20160914174501);
INSERT INTO `schema_migrations` (version) VALUES (20160914194540);
INSERT INTO `schema_migrations` (version) VALUES (20160914215134);
INSERT INTO `schema_migrations` (version) VALUES (20160915191129);
INSERT INTO `schema_migrations` (version) VALUES (20160916194539);
INSERT INTO `schema_migrations` (version) VALUES (20160924055948);
INSERT INTO `schema_migrations` (version) VALUES (20160926225157);
INSERT INTO `schema_migrations` (version) VALUES (20160929135859);
INSERT INTO `schema_migrations` (version) VALUES (20161004181711);
INSERT INTO `schema_migrations` (version) VALUES (20161012200608);
INSERT INTO `schema_migrations` (version) VALUES (20161013154229);
INSERT INTO `schema_migrations` (version) VALUES (20161013162339);
INSERT INTO `schema_migrations` (version) VALUES (20161013170416);
INSERT INTO `schema_migrations` (version) VALUES (20161014181536);
INSERT INTO `schema_migrations` (version) VALUES (20161014221336);
INSERT INTO `schema_migrations` (version) VALUES (20161031144834);
INSERT INTO `schema_migrations` (version) VALUES (20161101163857);
INSERT INTO `schema_migrations` (version) VALUES (20161101174551);
INSERT INTO `schema_migrations` (version) VALUES (20161101174731);
INSERT INTO `schema_migrations` (version) VALUES (20161104145701);
INSERT INTO `schema_migrations` (version) VALUES (20161104165607);
INSERT INTO `schema_migrations` (version) VALUES (20161108201151);
INSERT INTO `schema_migrations` (version) VALUES (20161109034931);
INSERT INTO `schema_migrations` (version) VALUES (20161109053659);
INSERT INTO `schema_migrations` (version) VALUES (20161110190547);
INSERT INTO `schema_migrations` (version) VALUES (20161110191532);
INSERT INTO `schema_migrations` (version) VALUES (20161115202151);
INSERT INTO `schema_migrations` (version) VALUES (20161116163735);
INSERT INTO `schema_migrations` (version) VALUES (20161116165947);
INSERT INTO `schema_migrations` (version) VALUES (20161118174623);
INSERT INTO `schema_migrations` (version) VALUES (20161118175719);
INSERT INTO `schema_migrations` (version) VALUES (20161123205617);
INSERT INTO `schema_migrations` (version) VALUES (20161124170829);
INSERT INTO `schema_migrations` (version) VALUES (20161124171612);
INSERT INTO `schema_migrations` (version) VALUES (20161130183834);
INSERT INTO `schema_migrations` (version) VALUES (20161201181704);
INSERT INTO `schema_migrations` (version) VALUES (20161205182833);
INSERT INTO `schema_migrations` (version) VALUES (20161215165727);
INSERT INTO `schema_migrations` (version) VALUES (20161215191427);
INSERT INTO `schema_migrations` (version) VALUES (20161219200232);
INSERT INTO `schema_migrations` (version) VALUES (20161219204505);
INSERT INTO `schema_migrations` (version) VALUES (20161220144658);
INSERT INTO `schema_migrations` (version) VALUES (20161220152839);
INSERT INTO `schema_migrations` (version) VALUES (20161220165340);
INSERT INTO `schema_migrations` (version) VALUES (20161220202246);
INSERT INTO `schema_migrations` (version) VALUES (20161221100014);
INSERT INTO `schema_migrations` (version) VALUES (20161221100127);
INSERT INTO `schema_migrations` (version) VALUES (20161221101027);
INSERT INTO `schema_migrations` (version) VALUES (20161222124950);
INSERT INTO `schema_migrations` (version) VALUES (20161223131256);
INSERT INTO `schema_migrations` (version) VALUES (20161227192753);
INSERT INTO `schema_migrations` (version) VALUES (20161229162613);
INSERT INTO `schema_migrations` (version) VALUES (20161229171246);
INSERT INTO `schema_migrations` (version) VALUES (20161229195124);
INSERT INTO `schema_migrations` (version) VALUES (20170102165430);
INSERT INTO `schema_migrations` (version) VALUES (20170105213430);
INSERT INTO `schema_migrations` (version) VALUES (20170109115814);
INSERT INTO `schema_migrations` (version) VALUES (20170109180032);
INSERT INTO `schema_migrations` (version) VALUES (20170110002354);
INSERT INTO `schema_migrations` (version) VALUES (20170113200644);
INSERT INTO `schema_migrations` (version) VALUES (20170116175403);
INSERT INTO `schema_migrations` (version) VALUES (20170116175546);
INSERT INTO `schema_migrations` (version) VALUES (20170116180133);
INSERT INTO `schema_migrations` (version) VALUES (20170117143633);
INSERT INTO `schema_migrations` (version) VALUES (20170117143933);
INSERT INTO `schema_migrations` (version) VALUES (20170117190223);
INSERT INTO `schema_migrations` (version) VALUES (20170117191259);
INSERT INTO `schema_migrations` (version) VALUES (20170117191859);
INSERT INTO `schema_migrations` (version) VALUES (20170119123633);
INSERT INTO `schema_migrations` (version) VALUES (20170119152252);
INSERT INTO `schema_migrations` (version) VALUES (20170119152650);
INSERT INTO `schema_migrations` (version) VALUES (20170119153421);
INSERT INTO `schema_migrations` (version) VALUES (20170119182423);
INSERT INTO `schema_migrations` (version) VALUES (20170119184752);
INSERT INTO `schema_migrations` (version) VALUES (20170120110133);
INSERT INTO `schema_migrations` (version) VALUES (20170125151039);
INSERT INTO `schema_migrations` (version) VALUES (20170125165633);
INSERT INTO `schema_migrations` (version) VALUES (20170125165933);
INSERT INTO `schema_migrations` (version) VALUES (20170125202522);
INSERT INTO `schema_migrations` (version) VALUES (20170126172256);
INSERT INTO `schema_migrations` (version) VALUES (20170130141552);
INSERT INTO `schema_migrations` (version) VALUES (20170131101552);
INSERT INTO `schema_migrations` (version) VALUES (20170201123448);
INSERT INTO `schema_migrations` (version) VALUES (20170202175824);
INSERT INTO `schema_migrations` (version) VALUES (20170206162219);
INSERT INTO `schema_migrations` (version) VALUES (20170207152142);
INSERT INTO `schema_migrations` (version) VALUES (20170213152812);
INSERT INTO `schema_migrations` (version) VALUES (20170213175223);
INSERT INTO `schema_migrations` (version) VALUES (20170213185018);
INSERT INTO `schema_migrations` (version) VALUES (20170214231700);
INSERT INTO `schema_migrations` (version) VALUES (20170215173627);
INSERT INTO `schema_migrations` (version) VALUES (20170216184642);
INSERT INTO `schema_migrations` (version) VALUES (20170224213051);
INSERT INTO `schema_migrations` (version) VALUES (20170301154642);
INSERT INTO `schema_migrations` (version) VALUES (20170301180955);
INSERT INTO `schema_migrations` (version) VALUES (20170306224401);
INSERT INTO `schema_migrations` (version) VALUES (20170307180659);
INSERT INTO `schema_migrations` (version) VALUES (20170308192425);
INSERT INTO `schema_migrations` (version) VALUES (20170308202613);
INSERT INTO `schema_migrations` (version) VALUES (20170315145645);
INSERT INTO `schema_migrations` (version) VALUES (20170315151438);
INSERT INTO `schema_migrations` (version) VALUES (20170320182452);
INSERT INTO `schema_migrations` (version) VALUES (20170320192625);
INSERT INTO `schema_migrations` (version) VALUES (20170322170704);
INSERT INTO `schema_migrations` (version) VALUES (20170327142610);
INSERT INTO `schema_migrations` (version) VALUES (20170329195359);
INSERT INTO `schema_migrations` (version) VALUES (20170329214637);
INSERT INTO `schema_migrations` (version) VALUES (20170406224331);
INSERT INTO `schema_migrations` (version) VALUES (20170412201505);
INSERT INTO `schema_migrations` (version) VALUES (20170417172528);
INSERT INTO `schema_migrations` (version) VALUES (20170417193442);
INSERT INTO `schema_migrations` (version) VALUES (20170419140001);
INSERT INTO `schema_migrations` (version) VALUES (20170420194102);
INSERT INTO `schema_migrations` (version) VALUES (20170424180020);
INSERT INTO `schema_migrations` (version) VALUES (20170424193118);
INSERT INTO `schema_migrations` (version) VALUES (20170424193129);
INSERT INTO `schema_migrations` (version) VALUES (20170428143816);
INSERT INTO `schema_migrations` (version) VALUES (20170502170714);
INSERT INTO `schema_migrations` (version) VALUES (20170503172812);
INSERT INTO `schema_migrations` (version) VALUES (20170505203058);
INSERT INTO `schema_migrations` (version) VALUES (20170508193540);
INSERT INTO `schema_migrations` (version) VALUES (20170508193825);
INSERT INTO `schema_migrations` (version) VALUES (20170519125438);
INSERT INTO `schema_migrations` (version) VALUES (20170523174141);
INSERT INTO `schema_migrations` (version) VALUES (20170524132106);
INSERT INTO `schema_migrations` (version) VALUES (20170601040741);
INSERT INTO `schema_migrations` (version) VALUES (20170602005809);
INSERT INTO `schema_migrations` (version) VALUES (20170622182023);
INSERT INTO `schema_migrations` (version) VALUES (20170731210541);
INSERT INTO `schema_migrations` (version) VALUES (20170818182906);
INSERT INTO `schema_migrations` (version) VALUES (20170818184000);
INSERT INTO `schema_migrations` (version) VALUES (20170818184001);
INSERT INTO `schema_migrations` (version) VALUES (20170818192920);
INSERT INTO `schema_migrations` (version) VALUES (20171004213434);
INSERT INTO `schema_migrations` (version) VALUES (20171004213435);
INSERT INTO `schema_migrations` (version) VALUES (20171004213436);
INSERT INTO `schema_migrations` (version) VALUES (20171023192702);
INSERT INTO `schema_migrations` (version) VALUES (20171023192842);
INSERT INTO `schema_migrations` (version) VALUES (20171023212559);
INSERT INTO `schema_migrations` (version) VALUES (20171118010654);
INSERT INTO `schema_migrations` (version) VALUES (20171122200548);
INSERT INTO `schema_migrations` (version) VALUES (20171213183513);
INSERT INTO `schema_migrations` (version) VALUES (20180110182428);
INSERT INTO `schema_migrations` (version) VALUES (20180131174235);
INSERT INTO `schema_migrations` (version) VALUES (20180219132514);
INSERT INTO `schema_migrations` (version) VALUES (20180226163507);
INSERT INTO `schema_migrations` (version) VALUES (20180226195859);
INSERT INTO `schema_migrations` (version) VALUES (20180302023759);
INSERT INTO `schema_migrations` (version) VALUES (20180312173843);
INSERT INTO `schema_migrations` (version) VALUES (20180315000255);
INSERT INTO `schema_migrations` (version) VALUES (20180315000421);
INSERT INTO `schema_migrations` (version) VALUES (20180413192752);
INSERT INTO `schema_migrations` (version) VALUES (20180503032000);
INSERT INTO `schema_migrations` (version) VALUES (20180504144910);
INSERT INTO `schema_migrations` (version) VALUES (20181022174941);
INSERT INTO `schema_migrations` (version) VALUES (20181102164026);
INSERT INTO `schema_migrations` (version) VALUES (20190328175014);
INSERT INTO `schema_migrations` (version) VALUES (20190328182425);
INSERT INTO `schema_migrations` (version) VALUES (20190329144509);
INSERT INTO `schema_migrations` (version) VALUES (20190401140258);
INSERT INTO `schema_migrations` (version) VALUES (20190621174448);
INSERT INTO `schema_migrations` (version) VALUES (20190621180432);
INSERT INTO `schema_migrations` (version) VALUES (20190621180921);
INSERT INTO `schema_migrations` (version) VALUES (20190821214420);
INSERT INTO `schema_migrations` (version) VALUES (20190826202301);
INSERT INTO `schema_migrations` (version) VALUES (20191011174319);
INSERT INTO `schema_migrations` (version) VALUES (20191127150645);
INSERT INTO `schema_migrations` (version) VALUES (20191127152001);
INSERT INTO `schema_migrations` (version) VALUES (20191204182139);
INSERT INTO `schema_migrations` (version) VALUES (20191212203052);
INSERT INTO `schema_migrations` (version) VALUES (20191213131858);
INSERT INTO `schema_migrations` (version) VALUES (20191216133057);
INSERT INTO `schema_migrations` (version) VALUES (20191218160035);
INSERT INTO `schema_migrations` (version) VALUES (20191223110804);
INSERT INTO `schema_migrations` (version) VALUES (20191223182932);
INSERT INTO `schema_migrations` (version) VALUES (20200122115222);
INSERT INTO `schema_migrations` (version) VALUES (20200211130308);
INSERT INTO `schema_migrations` (version) VALUES (20200211131441);
INSERT INTO `schema_migrations` (version) VALUES (20200212200209);
INSERT INTO `schema_migrations` (version) VALUES (20200213155156);
INSERT INTO `schema_migrations` (version) VALUES (20200408144038);
INSERT INTO `schema_migrations` (version) VALUES (20200420135544);
INSERT INTO `schema_migrations` (version) VALUES (20200907093359);
INSERT INTO `schema_migrations` (version) VALUES (20201124112819);
INSERT INTO `schema_migrations` (version) VALUES (20210211131024);
INSERT INTO `schema_migrations` (version) VALUES (20210323192808);
INSERT INTO `schema_migrations` (version) VALUES (20210325194736);
INSERT INTO `schema_migrations` (version) VALUES (20210326160009);
INSERT INTO `schema_migrations` (version) VALUES (20210326160205);
INSERT INTO `schema_migrations` (version) VALUES (20210512142133);
INSERT INTO `schema_migrations` (version) VALUES (20210512151329);
INSERT INTO `schema_migrations` (version) VALUES (20210614154820);
INSERT INTO `schema_migrations` (version) VALUES (20210629170410);
INSERT INTO `schema_migrations` (version) VALUES (20211125141835);
INSERT INTO `schema_migrations` (version) VALUES (20211213094856);
INSERT INTO `schema_migrations` (version) VALUES (20220131103226);
