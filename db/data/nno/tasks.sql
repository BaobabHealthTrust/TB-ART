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
  `has_encounter_type_today` varchar(255) default NULL,
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
-- everywhere
  (5,'/patients/show/{patient}',NULL,'Nothing left, go to dashboard','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,100,1,'2010-02-18 17:25:11',0,NULL,NULL,NULL,1,'2010-02-18 17:25:11','cdbfda9e-1ca1-11df-82c4-0026181bb84d'),
  (2,'/encounters/new/registration?patient_id={patient}','REGISTRATION','Registration for every location','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,2,1,'2010-02-18 17:25:10',0,NULL,NULL,NULL,1,'2010-02-18 17:25:10','cd7ab4be-1ca1-11df-82c4-0026181bb84d'),
-- registration
  (1,'/encounters/new/registration?patient_id={patient}','REGISTRATION','Always do a Registration here','Registration',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,1,1,'2010-02-18 17:25:10',0,NULL,NULL,NULL,1,'2010-02-18 17:25:10','cd5b8184-1ca1-11df-82c4-0026181bb84d'),
-- vitals
  (10,'/encounters/new/vitals?patient_id={patient}','VITALS','Always tke the vitals here','Vitals',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,1,1,'2010-02-18 17:25:10',0,NULL,NULL,NULL,1,'2010-02-18 17:25:10','cd934d9e-1ca1-11df-82c4-0026181bb84d'),
-- opd
  (21,'/encounters/new/outpatient_diagnosis?patient_id={patient}','OUTPATIENT DIAGNOSIS','Always make a diagnosis here','Outpatient',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,1,1,'2010-02-18 17:25:11',0,NULL,NULL,NULL,1,'2010-02-18 17:25:11','cdaf4f76-1ca1-11df-82c4-0026181bb84d'),
  (22,'/prescriptions/new?patient_id={patient}','TREATMENT','Always do a treatment here','Outpatient',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,2,1,'2010-02-26 11:10:56',0,NULL,NULL,NULL,1,'2010-02-26 11:10:56','d8cf35a4-22b6-11df-b344-0026181bb84d'),
-- hiv reception
  (31,'/encounters/new/art_initial?show&patient_id={patient}','ART_INITIAL','Not enrolled in HIV programn','HIV Reception',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,1,1,1,'2010-02-26 11:25:51',0,NULL,NULL,NULL,1,'2010-02-26 11:25:51','eeba2f84-22b8-11df-b344-0026181bb84d'),
  (32,'/encounters/new/hiv_reception?show&patient_id={patient}','HIV RECEPTION','Always','HIV Reception',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,2,1,'2010-02-26 11:47:13',0,NULL,NULL,NULL,1,'2010-02-26 11:47:13','ea6de076-22bb-11df-b344-0026181bb84d'),
  /* (34,'/encounters/new/vitals?patient_id={patient}','HIV STAGING','TODO: Transfer in','HIV Reception',NULL,1805,1065,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,3,1,'2010-02-26 13:45:50',0,NULL,NULL,NULL,1,'2010-02-26 13:45:50','7cc4fc2e-22cc-11df-b344-0026181bb84d'), */
  (33,'/encounters/new/vitals?patient_id={patient}','VITALS','PATIENT_PRESENT = YES','HIV Reception',NULL,1805,1065,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,4,1,'2010-02-26 13:45:50',0,NULL,NULL,NULL,1,'2010-02-26 13:45:50','7cc4fc2e-22cc-11df-b344-0026181bb84d'),
-- hiv nurse station
  (41,'/patients/show/{patient}',NULL,'Stop here if ART ELIGIBILITY = UNKNOWN','HIV Nurse Station',NULL,7563,1067,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,1,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),
-- todo: break out of endless loop for dispensing
  /* (42,'/dispensations/new?patient_id={patient}','DISPENSE','If TREATMENT today','HIV Nurse Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TREATMENT',0,6,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL), */
  (43,'/encounters/new/art_visit?show&patient_id={patient}','ART VISIT','In state On ART','HIV Nurse Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,7,NULL,NULL,NULL,NULL,0,7,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),
  (44,'/encounters/new/art_adherence?show&patient_id={patient}','ART ADHERENCE','In state On ART','HIV Nurse Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,7,NULL,NULL,NULL,NULL,0,8,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),
  (45,'/regimens/new?patient_id={patient}','TREATMENT','If ART Visit today AND REFER TO ART CLINICIAN = NO','HIV Nurse Station',NULL,6969,1066,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ART VISIT',0,7,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),
  (46,'/patients/show/{patient}','TREATMENT','If ART Visit today AND REFER TO ART CLINICIAN = YES','HIV Nurse Station',NULL,6969,1066,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ART VISIT',0,8,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),
  (47,'/encounters/new/appointment?patient_id={patient}','APPOINTMENT','If DISPENSE today','HIV Nurse Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'DISPENSE',0,10,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),
-- hiv clinician station
  (51,'/encounters/new/hiv_staging?show&patient_id={patient}','HIV STAGING','Not in state On ART','HIV Clinician Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,7,NULL,NULL,NULL,NULL,1,1,1,'2010-02-26 14:00:23',0,NULL,NULL,NULL,1,'2010-02-26 14:00:23','84dd80dc-22ce-11df-b344-0026181bb84d'),
  (52,'/patients/show/{patient}',NULL,'ART ELIGIBILITY = UNKNOWN','HIV Clinician Station',NULL,7563,1067,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,2,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),
  (53,'/encounters/new/art_visit?show&patient_id={patient}','ART VISIT','NOT ART ELIGIBILITY = UNKNOWN','HIV Clinician Station',NULL,7563,1067,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,3,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),
-- todo: enforce art visit if refered from nurse
--  (55,'/encounters/new/art_visit?show&patient_id={patient}','ART VISIT','REFER TO CLINICIAN = YES','HIV Clinician Station',NULL,6969,1065,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,6,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),
  (54,'/regimens/new?patient_id={patient}','TREATMENT','ART VISIT today','HIV Clinician Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ART VISIT',0,5,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL);

-- Deactivated for now as Dispensing is not fully thought through 
-- (14,'/encounters/new/appointment?patient_id={patient}','APPOINTMENT','Always give out a new appointment','HIV Nurse Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,7,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),
-- (15,'/dispensations/new?patient_id={patient}','DISPENSE','Dispense','HIV Nurse Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,6,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL);

/*!40000 ALTER TABLE `task` ENABLE KEYS */;
UNLOCK TABLES;
