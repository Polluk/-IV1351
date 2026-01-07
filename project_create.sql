-- create tables
DROP TABLE IF EXISTS allocated_activity CASCADE;
CREATE TABLE allocated_activity (
	employee_id INT NOT NULL,
	course_instance_id INT NOT NULL,
	teaching_activity_id INT NOT NULL,
	allocated_hours INT NOT NULL,
	PRIMARY KEY (employee_id, course_instance_id, teaching_activity_id)
);

DROP TABLE IF EXISTS course_instance CASCADE;
CREATE TABLE course_instance (
	id SERIAL UNIQUE NOT NULL,
	instance_id VARCHAR (11) UNIQUE NOT NULL,
	num_students INT NOT NULL,
	study_period VARCHAR (2) NOT NULL,
	study_year VARCHAR (4) NOT NULL,
	course_layout_id INT NOT NULL,
	PRIMARY KEY (id)
);

DROP TABLE IF EXISTS course_layout CASCADE;
CREATE TABLE course_layout (
	id SERIAL UNIQUE NOT NULL,
	course_code VARCHAR (6) UNIQUE NOT NULL,
	course_name VARCHAR (50) NOT NULL,
	min_students INT NOT NULL,
	max_students INT NOT NULL,
	hp DECIMAL (3, 1) NOT NULL,
	PRIMARY KEY (id)
);

DROP TABLE IF EXISTS department CASCADE;
CREATE TABLE department (
	id SERIAL UNIQUE NOT NULL,
	department_name VARCHAR (50) UNIQUE NOT NULL,
	manager_employee_id INT,
	PRIMARY KEY (id)
);

DROP TABLE IF EXISTS employee CASCADE;
CREATE TABLE employee (
	id SERIAL UNIQUE NOT NULL,
	employee_number VARCHAR (6) UNIQUE NOT NULL,
	salary INT DEFAULT 0,
	supervisor_employee_id INT DEFAULT NULL,
	person_id INT NOT NULL,
	department_id INT NOT NULL,
	job_title_id INT NOT NULL,
	PRIMARY KEY (id)
);

DROP TABLE IF EXISTS job_title CASCADE;
CREATE TABLE job_title (
	id SERIAL UNIQUE NOT NULL,
	job_title VARCHAR (50) UNIQUE NOT NULL,
	PRIMARY KEY (id)
);

DROP TABLE IF EXISTS person CASCADE;
CREATE TABLE person (
	id SERIAL UNIQUE NOT NULL,
	personal_number VARCHAR (12) UNIQUE NOT NULL,
	first_name VARCHAR (50) NOT NULL,
	last_name VARCHAR (50) NOT NULL,
	address VARCHAR (50) DEFAULT NULL,
	PRIMARY KEY (id)
);

DROP TABLE IF EXISTS phone_number CASCADE;
CREATE TABLE phone_number (
	number VARCHAR (20) NOT NULL,
	person_id INT NOT NULL,
	PRIMARY KEY (number, person_id)
);

DROP TABLE IF EXISTS planned_activity CASCADE;
CREATE TABLE planned_activity (
	course_instance_id INT NOT NULL,
	teaching_activity_id INT NOT NULL,
	planned_hours INT DEFAULT 0,
	PRIMARY KEY (course_instance_id, teaching_activity_id)
);

DROP TABLE IF EXISTS settings CASCADE;
CREATE TABLE settings (
	id SERIAL UNIQUE NOT NULL,
	var_name VARCHAR (50) NOT NULL,
	var DECIMAL (5, 3) NOT NULL,
	PRIMARY KEY (id)
);

DROP TABLE IF EXISTS skill_set CASCADE;
CREATE TABLE skill_set (
	skill VARCHAR (50) NOT NULL,
	employee_id INT NOT NULL,
	PRIMARY KEY (skill, employee_id)
);

DROP TABLE IF EXISTS study_period CASCADE;
CREATE TABLE study_period (
	period VARCHAR (2) UNIQUE NOT NULL,
	PRIMARY KEY (period)
);

DROP TABLE IF EXISTS study_year CASCADE;
CREATE TABLE study_year (
	year VARCHAR (4) UNIQUE NOT NULL,
	PRIMARY KEY (year)
);

DROP TABLE IF EXISTS teaching_activity CASCADE;
CREATE TABLE teaching_activity (
	id SERIAL UNIQUE NOT NULL,
	activity_name VARCHAR (50) UNIQUE NOT NULL,
	factor DECIMAL (4, 3) DEFAULT 1,
	PRIMARY KEY (id)
);

-- set foreign keys
ALTER TABLE allocated_activity
	ADD CONSTRAINT fk_employee
	FOREIGN KEY (employee_id)
	REFERENCES employee (id)
	ON DELETE CASCADE,
	
	ADD CONSTRAINT fk_planned_activity
	FOREIGN KEY (course_instance_id, teaching_activity_id)
	REFERENCES planned_activity (course_instance_id, teaching_activity_id)
	ON DELETE CASCADE;

ALTER TABLE course_instance
	ADD CONSTRAINT fk_study_period
	FOREIGN KEY (study_period)
	REFERENCES study_period (period)
	ON DELETE RESTRICT,
	
	ADD CONSTRAINT fk__study_year
	FOREIGN KEY (study_year)
	REFERENCES study_year (year)
	ON DELETE RESTRICT,
	
	ADD CONSTRAINT fk_course_layout
	FOREIGN KEY (course_layout_id)
	REFERENCES course_layout (id)
	ON DELETE RESTRICT;

ALTER TABLE department
	ADD CONSTRAINT fk_manager_employee_id
	FOREIGN KEY (manager_employee_id)
	REFERENCES employee (id)
	ON DELETE SET NULL;

ALTER TABLE employee
	ADD CONSTRAINT fk_employee
	FOREIGN KEY (supervisor_employee_id)
	REFERENCES employee (id)
	ON DELETE SET NULL,

	ADD CONSTRAINT fk_person
	FOREIGN KEY (person_id)
	REFERENCES person (id)
	ON DELETE RESTRICT,

	ADD CONSTRAINT fk_department
	FOREIGN KEY (department_id)
	REFERENCES department (id)
	ON DELETE RESTRICT,

	ADD CONSTRAINT fk_job_title
	FOREIGN KEY (job_title_id)
	REFERENCES job_title (id)
	ON DELETE RESTRICT;

ALTER TABLE phone_number
	ADD CONSTRAINT fk_person
	FOREIGN KEY (person_id)
	REFERENCES person (id)
	ON DELETE CASCADE;

ALTER TABLE planned_activity
	ADD CONSTRAINT fk_course_instance
	FOREIGN KEY (course_instance_id)
	REFERENCES course_instance (id)
	ON DELETE CASCADE,

	ADD CONSTRAINT fk_teaching_activity
	FOREIGN KEY (teaching_activity_id)
	REFERENCES teaching_activity (id)
	ON DELETE RESTRICT;

ALTER TABLE skill_set
	ADD CONSTRAINT fk_employee
	FOREIGN KEY (employee_id)
	REFERENCES employee (id)
	ON DELETE CASCADE;

-- calculate planned hours for administration
DROP FUNCTION IF EXISTS calculate_admin CASCADE;
CREATE FUNCTION calculate_admin(new_stu INT, new_hp DECIMAL) RETURNS integer AS $$
	DECLARE
		admin_var1 DECIMAL(5, 3);
		admin_var2 DECIMAL(5, 3);
		admin_var3 DECIMAL(5, 3);
	BEGIN
		SELECT var
		FROM settings
		WHERE var_name = 'admin_var1'
		INTO admin_var1;

		SELECT var
		FROM settings
		WHERE var_name = 'admin_var2'
		INTO admin_var2;

		SELECT var
		FROM settings
		WHERE var_name = 'admin_var3'
		INTO admin_var3;

		RETURN admin_var1 * new_hp + admin_var2 + admin_var3 * new_stu;
	END;
$$ LANGUAGE plpgsql;

-- calculate planned hours for examination
DROP FUNCTION IF EXISTS calculate_examination CASCADE;
CREATE FUNCTION calculate_examination(new_stu INT) RETURNS integer AS $$
	DECLARE
		examination_var1 DECIMAL(5, 3);
		examination_var2 DECIMAL(5, 3);
	BEGIN
		SELECT var
		FROM settings
		WHERE var_name = 'examination_var1'
		INTO examination_var1;

		SELECT var
		FROM settings
		WHERE var_name = 'examination_var2'
		INTO examination_var2;

		RETURN examination_var1 + examination_var2 * new_stu;
	END;
$$ LANGUAGE plpgsql;

-- insert exam and admin planning when a course instance is created
DROP FUNCTION IF EXISTS insert_planned_activity_function CASCADE;
CREATE FUNCTION insert_planned_activity_function() RETURNS TRIGGER AS $$
	DECLARE
		hp DECIMAL;
	BEGIN
		SELECT cl.hp
		FROM course_layout cl
		WHERE cl.id = NEW.course_layout_id
		INTO hp;
	
		INSERT INTO planned_activity
		VALUES (NEW.id,
				(SELECT id
				FROM teaching_activity
				WHERE activity_name = 'Administration'),
				calculate_admin(NEW.num_students, hp));

		INSERT INTO planned_activity
		VALUES (NEW.id,
				(SELECT id
				FROM teaching_activity
				WHERE activity_name = 'Examination'),
				calculate_examination(NEW.num_students));

		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER insert_planned_activity
	AFTER INSERT ON course_instance
	FOR EACH ROW
	EXECUTE FUNCTION insert_planned_activity_function();

-- update planned admin hours for a course instance
DROP FUNCTION IF EXISTS update_admin CASCADE;
CREATE FUNCTION update_admin(new_ci INT, new_stu INT, new_hp DECIMAL) RETURNS void AS $$
	BEGIN
		UPDATE planned_activity
		SET planned_hours = calculate_admin(new_stu, new_hp)
		WHERE course_instance_id = new_ci
		AND teaching_activity_id = (SELECT id
									FROM teaching_activity
									WHERE activity_name = 'Administration');
	END;
$$ LANGUAGE plpgsql;

-- update planned examination hours for a course instance
DROP FUNCTION IF EXISTS update_examination CASCADE;
CREATE FUNCTION update_examination(new_ci INT, new_stu INT) RETURNS void AS $$
	BEGIN
		UPDATE planned_activity
		SET planned_hours = calculate_examination(new_stu)
		WHERE course_instance_id = new_ci
		AND teaching_activity_id = (SELECT id
									FROM teaching_activity
									WHERE activity_name = 'Examination');
	END;
$$ LANGUAGE plpgsql;

-- update planned administration hours for all instances related to a course layout with new hp
DROP FUNCTION IF EXISTS update_hp_function CASCADE;
CREATE FUNCTION update_hp_function() RETURNS TRIGGER AS $$
	DECLARE
		ci RECORD;
	BEGIN
		FOR ci IN SELECT id, num_students
					FROM course_instance
					WHERE course_layout_id = NEW.id
		LOOP
			EXECUTE update_admin(ci.id, ci.num_students, NEW.hp);
		END LOOP;

		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_hp
	AFTER UPDATE OF hp ON course_layout
	FOR EACH ROW
	EXECUTE FUNCTION update_hp_function();

-- update planned examination and admin hours for a course instance with new number of students
DROP FUNCTION IF EXISTS update_num_students_function CASCADE;
CREATE FUNCTION update_num_students_function() RETURNS TRIGGER AS $$
	DECLARE
	 hp INT;
	BEGIN
		SELECT cl.hp
		FROM course_layout cl
		WHERE id = NEW.course_layout_id
		INTO hp;

		EXECUTE update_admin(NEW.id, NEW.num_students, hp);
		EXECUTE update_examination(NEW.id, NEW.num_students);

		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_num_students
	AFTER UPDATE OF num_students ON course_instance
	FOR EACH ROW
	EXECUTE FUNCTION update_num_students_function();