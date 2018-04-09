USE hw3_1;

DROP TABLE IF EXISTS `type`;
CREATE TABLE `type` (
  `type_code` char(1) NOT NULL,
  `type_name` varchar(45) NOT NULL,
  PRIMARY KEY (`type_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `department`;
CREATE TABLE `department` (
  `code` char(4) NOT NULL,
  `name` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`code`),
  UNIQUE KEY `name_UNIQUE` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `Person`;
CREATE TABLE `Person` (
  `UNI` varchar(12) NOT NULL,
  `type` char(1) NOT NULL,
  `Address` varchar(60) DEFAULT NULL,
  PRIMARY KEY (`UNI`),
  KEY `person_type` (`type`),
  CONSTRAINT `person_type` FOREIGN KEY (`type`) 
	REFERENCES `type` (`type_code`) 
	ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `student`;
CREATE TABLE `student` (
  `UNI` varchar(12) NOT NULL,
  `last_name` varchar(45) NOT NULL,
  `first_name` varchar(45) NOT NULL,
  `year` int(11) DEFAULT NULL,
  `department` char(4) DEFAULT NULL,
  PRIMARY KEY (`UNI`),
  KEY `student_dept` (`department`),
  CONSTRAINT `student_dept` FOREIGN KEY (`department`)
	 REFERENCES `department` (`code`) 
	ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `student_id` FOREIGN KEY (`UNI`) 
	REFERENCES `Person` (`UNI`) 
	ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `faculty`;
CREATE TABLE `faculty` (
  `UNI` varchar(12) NOT NULL,
  `last_name` varchar(45) NOT NULL,
  `first_name` varchar(45) NOT NULL,
  `pay_grade` varchar(45) DEFAULT NULL,
  `title` varchar(45) DEFAULT NULL,
  `department` char(4) NOT NULL,
  PRIMARY KEY (`UNI`),
  KEY `faculty_dept` (`department`),
  CONSTRAINT `faculty_dept` FOREIGN KEY (`department`) 
	REFERENCES `department` (`code`) 
	ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `faculty_id` FOREIGN KEY (`UNI`) 
	REFERENCES `Person` (`UNI`) 
	ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;




DROP TABLE IF EXISTS `courses`;
CREATE TABLE `courses` (
  `dept_code` char(4) NOT NULL,
  `faculty_code` enum('BC','C','E','F','G','V','W','X') NOT NULL,
  `level` enum('0','1','2','3','4','6','8','9') NOT NULL,
  `number` char(3) NOT NULL,
  `title` varchar(32) NOT NULL,
  `description` varchar(128) NOT NULL,
  `course_id` varchar(12) GENERATED ALWAYS AS (concat(`dept_code`,`faculty_code`,`level`,`number`)) STORED,
  `full_number` char(4) GENERATED ALWAYS AS (concat(`level`,`number`)) VIRTUAL,
  PRIMARY KEY (`dept_code`,`faculty_code`,`level`,`number`),
  UNIQUE KEY `course_id` (`course_id`),
  FULLTEXT KEY `keywords` (`title`,`description`),
  CONSTRAINT `course2_dept_fk` FOREIGN KEY (`dept_code`) REFERENCES `department` (`code`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `sections`;
CREATE TABLE `sections` (
  `call_no` char(5) NOT NULL,
  `course_id` varchar(12) NOT NULL,
  `section_no` varchar(45) NOT NULL,
  `year` int(11) NOT NULL,
  `semester` enum('1','2','3','4') NOT NULL,
  `section_key` varchar(45) GENERATED ALWAYS AS (concat(`year`,`semester`,`course_id`,`section_no`)) STORED,
  `max_limit` int(11) NOT NULL,
  PRIMARY KEY (`call_no`),
  UNIQUE KEY `unique` (`course_id`,`section_no`,`year`,`semester`),
  CONSTRAINT `section_course_fk` FOREIGN KEY (`course_id`) REFERENCES `courses` (`course_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `course_prereqs`;
CREATE TABLE `course_prereqs` (
  `course_id` varchar(12) NOT NULL,
  `prereq_id` varchar(12) NOT NULL,
  PRIMARY KEY (`course_id`,`prereq_id`),
  KEY `prereq_prereq_fk` (`prereq_id`),
  CONSTRAINT `prereq_course_fk` FOREIGN KEY (`course_id`) 
	REFERENCES `courses` (`course_id`) 
	ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `prereq_prereq_fk` FOREIGN KEY (`prereq_id`) 
	REFERENCES `courses` (`course_id`) 
	ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `course_participant`;
CREATE TABLE `course_participant` (
  `UNI` varchar(12) NOT NULL,
  `section_call_no` char(5) NOT NULL,
  `role` enum('Student','Instructor') NOT NULL,
  PRIMARY KEY (`UNI`,`section_call_no`),
  KEY `cp_section_fk` (`section_call_no`),
  CONSTRAINT `cp_participant_fk` FOREIGN KEY (`UNI`) REFERENCES `Person` (`UNI`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `cp_section_fk` FOREIGN KEY (`section_call_no`) REFERENCES `sections` (`call_no`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP FUNCTION IF EXISTS generate_uni;
DELIMITER $$
CREATE FUNCTION generate_uni (lastname VARCHAR(20), firstname VARCHAR(20)) 
RETURNS VARCHAR(12) 
DETERMINISTIC
BEGIN
	DECLARE prefix CHAR(5);
    DECLARE c1 CHAR(1);
    DECLARE c2 CHAR(1);
    DECLARE unicount INT;
    DECLARE newuni VARCHAR(12);
    
    SET c1 = UPPER(SUBSTR(lastname, 1, 1));
    SET c2 = UPPER(SUBSTR(firstname, 1, 1));
    SET prefix = CONCAT(c1, c2, '%');
    
    SELECT COUNT(UNI) INTO unicount FROM Person WHERE UNI LIKE prefix;
    
    SET newuni = CONCAT(c1, c2, unicount + 1);
    # If an UNI has been used (even if it is deleted now), it will not be used in the future.
	WHILE newuni IN (SELECT UNI FROM Person) DO
		SET newuni = CONCAT(c1, c2, unicount + 1);
        SET unicount = unicount + 1;

	END WHILE;
    
    
RETURN newuni;
END$$
DELIMITER ;


-- A function return a timestamp for a section holding in a particular year and semester
DROP FUNCTION IF EXISTS section_time;
DELIMITER $$
CREATE FUNCTION section_time (section_call_no CHAR(5)) 
RETURNS DATE 
DETERMINISTIC
BEGIN
	DECLARE section_year INT(11);
    DECLARE section_semester INT(11);
    DECLARE day VARCHAR(12);
    DECLARE output DATE;

    
    SELECT year INTO section_year FROM sections WHERE call_no = section_call_no;
    SELECT semester INTO section_semester FROM sections WHERE call_no = section_call_no;
    
    IF section_semester = '1' THEN 
		SET day = '31/12';
	ELSEIF section_semester = '2' THEN
		SET day = '18/5';
	ELSEIF section_semester = '3' THEN
		SET day = '30/6' ;
	ELSE
		SET day = '30/8' ;
	END IF;
    
    SET output =  STR_TO_DATE( CONCAT( day, '/', section_year),'%d/%m/%Y');
    
RETURN output;
END$$
DELIMITER ;



DROP FUNCTION IF EXISTS section_time2;
DELIMITER $$
CREATE FUNCTION section_time2 (section_call_no CHAR(5)) 
RETURNS DATE 
DETERMINISTIC
BEGIN
	DECLARE section_year INT(11);
    DECLARE section_semester INT(11);
    DECLARE day VARCHAR(12);
    DECLARE output DATE;

    
    SELECT year INTO section_year FROM sections WHERE call_no = section_call_no;
    SELECT semester INTO section_semester FROM sections WHERE call_no = section_call_no;
    
    IF section_semester = '1' THEN 
		SET day = '1/9';
	ELSEIF section_semester = '2' THEN
		SET day = '1/2';
	ELSEIF section_semester = '3' THEN
		SET day = '1/6' ;
	ELSE
		SET day = '15/7' ;
	END IF;
    
    SET output =  STR_TO_DATE( CONCAT( day, '/', section_year),'%d/%m/%Y');
    
RETURN output;
END$$
DELIMITER ;



DROP FUNCTION IF EXISTS get_semester;
DELIMITER $$
CREATE FUNCTION get_semester (semester INT(11)) 
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN

    DECLARE output VARCHAR(10);

    IF semester = '1' THEN 
		SET output= 'Fall';
	ELSEIF semester = '2' THEN
		SET output= 'Spring';
	ELSEIF semester = '3' THEN
		SET output = 'Summer1' ;
	ELSE
		SET output = 'Summer2' ;
	END IF;
    
RETURN output;
END$$
DELIMITER ;

-- Inerst/Update/Delete Student
	
DROP PROCEDURE IF EXISTS insert_student;

DELIMITER $$
CREATE PROCEDURE insert_student (
IN lastname VARCHAR(45), IN firstname VARCHAR(45), IN year INT, IN department CHAR(4), IN address VARCHAR(60))
BEGIN
	DECLARE uni VARCHAR(12);
    
	IF (lastname IS NULL) OR (firstname IS NULL)
		THEN SIGNAL SQLSTATE '45100'
			SET MESSAGE_TEXT = 'Name can not be null';
	
    ELSE
		SET uni = generate_uni(lastname, firstname);
        INSERT INTO Person (UNI, Address, type) VALUES (uni, address, "S");
		INSERT INTO student (UNI, last_name, first_name, department, year) VALUES (uni, lastname, firstname, department, year);
	END IF;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS update_student;
DELIMITER $$
CREATE PROCEDURE update_student (
IN uni VARCHAR(12), IN new_lastname VARCHAR(45), IN new_firstname VARCHAR(45), IN new_year INT, IN new_department CHAR(4), IN new_address VARCHAR(60))
BEGIN

    IF (uni NOT IN (SELECT UNI FROM student))
		THEN SIGNAL SQLSTATE '45100'
			SET MESSAGE_TEXT = 'UNI is not found';		
    
	ELSE
		UPDATE student 
			SET last_name = new_lastname, first_name = new_firstname, year= new_year, department = new_department
            WHERE student.UNI = uni;
		UPDATE Person
			SET Address = new_address WHERE Person.UNI = uni;
	END IF;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS delete_student;
DELIMITER $$
CREATE PROCEDURE delete_student (
IN uni VARCHAR(12))
BEGIN

    IF (uni NOT IN (SELECT UNI FROM student))
		THEN SIGNAL SQLSTATE '45100'
			SET MESSAGE_TEXT = 'UNI is not found';		
    
	ELSE
		DELETE FROM course_participant WHERE course_participant.UNI = uni;
        DELETE FROM student WHERE student.UNI = uni;
        DELETE FROM Person WHERE Person.UNI = uni;
        
	END IF;
END$$
DELIMITER ;

-- Inerst/Update/Delete Student end



-- Inerst/Update/Delete Faculty
	
DROP PROCEDURE IF EXISTS insert_faculty;
DELIMITER $$
CREATE PROCEDURE insert_faculty (
IN lastname VARCHAR(45), IN firstname VARCHAR(45), IN pay_grade VARCHAR(45), IN title VARCHAR(45),IN department CHAR(4), In address VARCHAR(60))
BEGIN
	DECLARE uni VARCHAR(12);
    
	IF (lastname IS NULL) OR (firstname IS NULL)
		THEN SIGNAL SQLSTATE '45100'
			SET MESSAGE_TEXT = 'Name can not be null';
            
	ELSEIF (department IS NULL) 
		THEN SIGNAL SQLSTATE '45100'
			SET MESSAGE_TEXT = 'Department can not be null';
    ELSE
		SET uni = generate_uni(lastname, firstname);
        INSERT INTO Person (UNI, Address, type) VALUES (uni, address, "F");
		INSERT INTO faculty (UNI, last_name, first_name, pay_grade, title, department) VALUES (uni, lastname, firstname, pay_grade, title, department);
	END IF;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS update_faculty;
DELIMITER $$
CREATE PROCEDURE update_faculty (
IN uni VARCHAR(12), IN new_lastname VARCHAR(45), IN new_firstname VARCHAR(45), IN new_title VARCHAR(45), IN new_department CHAR(4), IN new_pay_grade VARCHAR(45), In new_address VARCHAR(60))
BEGIN

    IF (uni NOT IN (SELECT UNI FROM faculty))
		THEN SIGNAL SQLSTATE '45100'
			SET MESSAGE_TEXT = 'UNI is not found';		
    
	ELSE
		UPDATE faculty 
			SET last_name = new_lastname, first_name = new_firstname, title= new_title, department = new_department, pay_grade = new_pay_grade
            WHERE faculty.UNI = uni;
		UPDATE Person
			SET Address = new_address WHERE Person.UNI = uni;
	END IF;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS delete_faculty;
DELIMITER $$
CREATE PROCEDURE delete_faculty (
IN uni VARCHAR(12))
BEGIN
    IF (uni NOT IN (SELECT UNI FROM faculty))
		THEN SIGNAL SQLSTATE '45100'
			SET MESSAGE_TEXT = 'UNI is not found';		
    
	ELSE
		DELETE FROM course_participant WHERE course_participant.UNI = uni;
		DELETE FROM faculty WHERE faculty.UNI = uni;
		DELETE FROM Person WHERE Person.UNI = uni;
        
	END IF;
END$$
DELIMITER ;
-- Inerst/Update/Delete Faculty end



-- section enrollments only for students and faculties
DROP TRIGGER IF EXISTS valid_type_BEFORE_INSERT;
DELIMITER $$
CREATE TRIGGER valid_type_BEFORE_INSERT BEFORE INSERT ON course_participant FOR EACH ROW
BEGIN 
    DECLARE person_type CHAR(1);

    SELECT type INTO person_type FROM Person WHERE Person.UNI = New.UNI;
    
    IF person_type <> 'S' AND person_type <> 'F' 
		THEN SIGNAL SQLSTATE '04022'
			SET MESSAGE_TEXT = 'Invalid person type for enrollment.';

    ELSEIF person_type = 'S' AND New.role <> 'Student'
		THEN SIGNAL SQLSTATE '04022'
			SET MESSAGE_TEXT = 'Invalid person type for enrollment.';
            
            
	ELSEIF person_type = 'F' AND New.role <> 'Instructor'
		THEN SIGNAL SQLSTATE '04022'
			SET MESSAGE_TEXT = 'Invalid person type for enrollment.';
        
	END IF;
END$$
DELIMITER ;
-- section enrollments only for students and faculties



-- section enrollments do not exceed limit
DROP TRIGGER IF EXISTS enrollment_check_BEFORE_INSERT;
DELIMITER $$
CREATE TRIGGER enrollment_check_BEFORE_INSERT BEFORE INSERT ON course_participant FOR EACH ROW
BEGIN 
	DECLARE course_limit INT(11);
    DECLARE enroll_num INT(11);
    
	SELECT sections.max_limit INTO course_limit FROM sections WHERE call_no = New.section_call_no;
    SELECT count(section_call_no) INTO enroll_num FROM course_participant INNER JOIN  Person ON Person.UNI = course_participant.UNI WHERE Person.type = 'S' AND course_participant.section_call_no = New.section_call_no ;
    
    IF course_limit = enroll_num
		THEN SIGNAL SQLSTATE '04022'
			SET MESSAGE_TEXT = 'The section is full';
	END IF;
END$$
DELIMITER ;
-- section enrollments do not exceed limit

-- students cannot enroll in a course for which they have not taken a prereq
DROP TRIGGER IF EXISTS prereq_check_BEFORE_INSERT;
DELIMITER $$
CREATE TRIGGER prereq_check_BEFORE_INSERT BEFORE INSERT ON course_participant FOR EACH ROW
BEGIN 
	DECLARE course VARCHAR(12);
    DECLARE person_type CHAR(1);
    DECLARE current_section_time DATE;
    DECLARE current_section_call_no CHAR(5);
    
    
    SELECT course_id INTO course FROM sections WHERE sections.call_no = NEW.section_call_no;
    SELECT type INTO person_type FROM Person WHERE Person.UNI = New.UNI;
    SET current_section_call_no = New.section_call_no;
    SET current_section_time = section_time(current_section_call_no);
    
    IF person_type = 'S' THEN
		IF EXISTS (
		SELECT * FROM (SELECT prereq_id FROM course_prereqs WHERE course_id = course) A LEFT JOIN
					(SELECT UNI, call_no, course_id FROM course_participant INNER JOIN sections 
						ON course_participant.section_call_no = sections.call_no WHERE UNI = New.UNI
							AND section_time(sections.call_no) < current_section_time) B
					ON A.prereq_id = B.course_id WHERE course_id IS NULL
    
		)
			THEN SIGNAL SQLSTATE'04021'
				SET MESSAGE_TEXT = 'Pre-req is not satisfied';
		END IF;
        
	END IF;
END$$
DELIMITER ;
-- students cannot enroll in a course for which they have not taken a prereq
 
 
-- a faculty member is not allowed to teach more than 3 courses a semester
DROP TRIGGER IF EXISTS faculty_check_BEFORE_INSERT;
DELIMITER $$
CREATE TRIGGER faculty_check_BEFORE_INSERT BEFORE INSERT ON course_participant FOR EACH ROW
BEGIN 

    DECLARE person_type CHAR(1);
    DECLARE current_section_time DATE;
    DECLARE current_section_call_no CHAR(5);
    DECLARE section_count INT;
    
    
    SELECT type INTO person_type FROM Person WHERE Person.UNI = New.UNI;
    SET current_section_call_no = New.section_call_no;
    SET current_section_time = section_time(current_section_call_no);
    
    IF person_type = 'F' THEN
		SELECT COUNT(section_call_no) INTO section_count FROM course_participant 
			WHERE section_time(section_call_no) = current_section_time AND UNI = New.UNI ;
		IF section_count >= 3
			THEN SIGNAL SQLSTATE'04021'
				SET MESSAGE_TEXT = 'Faculties cannot have more than 3 sections in a semester.';
		END IF;

	END IF;
END$$
DELIMITER ;
-- a faculty member is not allowed to teach more than 3 courses a semester


-- a view that supports query of all attributes, including those in the corresponding Person tuple.
DROP VIEW IF EXISTS students;
CREATE VIEW students (UNI, last_name, first_name, year, department, address) AS
select  student.UNI, last_name,
first_name, year, department, Address
FROM student INNER JOIN Person ON student.UNI = Person.UNI WHERE type = 'S';

DROP VIEW IF EXISTS faculties;
CREATE VIEW faculties (UNI, last_name, first_name, title, department, pay_grade, address) AS
select  faculty.UNI, last_name, first_name, title, department, pay_grade, Address
FROM faculty INNER JOIN Person ON faculty.UNI = Person.UNI WHERE type = 'F';
-- a view that supports query of all attributes, including those in the corresponding Person tuple.



-- create view that allow select for courses a student has completed
DROP VIEW IF EXISTS course_completed;
CREATE VIEW course_completed AS 
SELECT course_participant.UNI AS uni, sections.course_id AS course,
	 get_semester(sections.semester) AS semester, year
FROM course_participant INNER JOIN sections ON course_participant.section_call_no = sections.call_no
	INNER JOIN Person ON Person.UNI = course_participant.UNI
WHERE Person.type = 'S' AND section_time(course_participant.section_call_no) < DATE(Now());


-- create view that allow select for courses a student has completed
DROP VIEW IF EXISTS course_taught_or_teaching;
CREATE VIEW course_taught_or_teaching AS 
SELECT  course_participant.UNI AS uni, sections.course_id AS course,
	 get_semester(sections.semester) AS semester, year
FROM course_participant INNER JOIN sections ON course_participant.section_call_no = sections.call_no
	INNER JOIN Person ON Person.UNI = course_participant.UNI
WHERE Person.type = 'F' AND section_time2(course_participant.section_call_no) <= DATE(Now());
-- create view that allow select for courses a student has completed