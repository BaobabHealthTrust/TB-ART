--
-- Table structure for table `task`
--

DROP TABLE IF EXISTS `task`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `task` (
  `task_id` int(11) NOT NULL auto_increment,
  `url` varchar(255) default NULL,
  `encounter_type` varchar(255) default NULL,
  `description` text,
  `location` varchar(255) default NULL,
  `gender` varchar(50) default NULL,
  `has_obs_concept_id` int(11) default NULL,
  `has_obs_value_coded` int(11) default NULL,
  `has_obs_value_drug` int(11) default NULL,
  `has_obs_value_datetime` datetime default NULL,
  `has_obs_value_numeric` double default NULL,
  `has_obs_value_text` text,
  `has_program_id` int(11) default NULL,
  `has_program_workflow_state_id` int(11) default NULL,
  `has_identifier_type_id` int(11) default NULL,
  `has_relationship_type_id` int(11) default NULL,
  `has_order_type_id` int(11) default NULL,
  `skip_if_has` smallint(6) default '0',
  `sort_weight` double default NULL,
  `creator` int(11) NOT NULL,
  `date_created` datetime NOT NULL,
  `voided` smallint(6) default '0',
  `voided_by` int(11) default NULL,
  `date_voided` datetime default NULL,
  `void_reason` varchar(255) default NULL,
  `changed_by` int(11) default NULL,
  `date_changed` datetime default NULL,
  `uuid` char(38) default NULL,
  PRIMARY KEY  (`task_id`),
  KEY `task_creator` (`creator`),
  KEY `user_who_voided_task` (`voided_by`),
  KEY `user_who_changed_task` (`changed_by`),
  CONSTRAINT `task_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user_who_changed_task` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user_who_voided_task` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=17461 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `task`
--

LOCK TABLES `task` WRITE;
/*!40000 ALTER TABLE `task` DISABLE KEYS */;
INSERT INTO `task` VALUES 
  (1,'/encounters/new/registration?patient_id={patient}','REGISTRATION','Registration clerk needs to do registration if it hasn\'t happened yet','Registration',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,1,1,'2010-02-18 17:25:10',0,NULL,NULL,NULL,1,'2010-02-18 17:25:10','cd5b8184-1ca1-11df-82c4-0026181bb84d'),
  (2,'/encounters/new/registration?patient_id={patient}','REGISTRATION','Everyone needs to do registration if it hasn\'t happened yet','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,2,1,'2010-02-18 17:25:10',0,NULL,NULL,NULL,1,'2010-02-18 17:25:10','cd7ab4be-1ca1-11df-82c4-0026181bb84d'),
  (3,'/encounters/new/vitals?patient_id={patient}','VITALS','If we are at the vitals location and no vitals have been taken, then we need to do it','Vitals',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,4,1,'2010-02-18 17:25:10',0,NULL,NULL,NULL,1,'2010-02-18 17:25:10','cd934d9e-1ca1-11df-82c4-0026181bb84d'),
  (4,'/encounters/new/outpatient_diagnosis?patient_id={patient}','OUTPATIENT DIAGNOSIS','If we are at the outpatient diagnosis location and no diagnosis has been made, then we need to do it','Outpatient',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,4,1,'2010-02-18 17:25:11',0,NULL,NULL,NULL,1,'2010-02-18 17:25:11','cdaf4f76-1ca1-11df-82c4-0026181bb84d'),
  (5,'/patients/show/{patient}',NULL,'If everything is done, go to the dashboard for the patient','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,10,1,'2010-02-18 17:25:11',0,NULL,NULL,NULL,1,'2010-02-18 17:25:11','cdbfda9e-1ca1-11df-82c4-0026181bb84d'),
  (6,'/prescriptions/new?patient_id={patient}','TREATMENT','If we are at outpatient diagnosis and a diagnosis has been made but no treatment, then go to treatment.','Outpatient',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,5,1,'2010-02-26 11:10:56',0,NULL,NULL,NULL,1,'2010-02-26 11:10:56','d8cf35a4-22b6-11df-b344-0026181bb84d'),
  (7,'/encounters/new/art_initial?show&patient_id={patient}','ART_INITIAL','If patient is not ON ANTIRETROVIRALS at the current location, go to ART_INITIAL.','HIV Reception',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,1,4,1,'2010-02-26 11:25:51',0,NULL,NULL,NULL,1,'2010-02-26 11:25:51','eeba2f84-22b8-11df-b344-0026181bb84d'),
  (8,'/encounters/new/hiv_reception?show&patient_id={patient}','HIV RECEPTION','If patient has not had an HIV Reception encounter yet, create one.','HIV Reception',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,0,5,1,'2010-02-26 11:47:13',0,NULL,NULL,NULL,1,'2010-02-26 11:47:13','ea6de076-22bb-11df-b344-0026181bb84d'),
  (9,'/encounters/new/vitals?patient_id={patient}','VITALS','Patient present at HIV Reception (PATIENT_PRESENT=YES) and has not had vitals taken','HIV Reception',NULL,1805,1065,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,6,1,'2010-02-26 13:45:50',0,NULL,NULL,NULL,1,'2010-02-26 13:45:50','7cc4fc2e-22cc-11df-b344-0026181bb84d'),
  (10,'/encounters/new/art_clinician_visit?show&patient_id={patient}','ART CLINICIAN VISIT','At the HIV Clinician Station, if the patient does not have an ART CLINICIAN VISIT, do it.','HIV Clinician Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,4,1,'2010-02-26 14:00:23',0,NULL,NULL,NULL,1,'2010-02-26 14:00:23','84dd80dc-22ce-11df-b344-0026181bb84d'),
  (11,'/encounters/new/art_nurse_visit?show&patient_id={patient}','ART NURSE VISIT','At HIV Nurse Station, if the patient does not have an ART NURSE VISIT, do it.','HIV Nurse Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,4,1,'2010-02-26 14:11:46',0,NULL,NULL,NULL,1,'2010-02-26 14:11:46','1c15bac2-22d0-11df-b344-0026181bb84d'),
  (12,'/regimens/new?patient_id={patient}','TREATMENT','Prescribe regimen if reason for ART eligibility is not UNKNOWN','HIV Clinician Station',NULL,7563,1067,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,5,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),
  (13,'/regimens/new?patient_id={patient}','TREATMENT','Prescribe regimen if reason for ART eligibility is not UNKNOWN','HIV Nurse Station',NULL,7563,1067,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,5,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL);

-- Deactivated for now as Dispensing is not fully thought through 
-- (14,'/encounters/new/appointment?patient_id={patient}','APPOINTMENT','Always give out a new appointment','HIV Nurse Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,7,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),
-- (15,'/dispensations/new?patient_id={patient}','DISPENSE','Dispense','HIV Nurse Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,6,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL);

/*!40000 ALTER TABLE `task` ENABLE KEYS */;
UNLOCK TABLES;
