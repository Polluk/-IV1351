
-- create a joint table which contains all data needed for the tasks
DROP VIEW IF EXISTS collected_data CASCADE;
CREATE OR REPLACE VIEW collected_data AS
    SELECT
        cl.course_code AS "Course Code",
        cl.hp AS "HP",
        ci.instance_id AS "Course Instance ID",
        ci.study_period AS "Period",
        ci.study_year,
        ci.num_students AS "# Students",
        pa.course_instance_id,
        pa.teaching_activity_id,
        pa.planned_hours,
        ta.activity_name,
        ta.factor,
        aa.employee_id AS "Employment ID",
        aa.allocated_hours,
        e.person_id,
        jt.job_title AS "Designation",
        p.first_name || ' ' || p.last_name AS "Teacher's Name"

    FROM 
        course_layout cl
        JOIN course_instance ci ON  ci.course_layout_id = cl.id
        JOIN planned_activity pa ON ci.id = pa.course_instance_id
        JOIN teaching_activity ta ON pa.teaching_activity_id = ta.id
        LEFT JOIN allocated_activity aa ON pa.course_instance_id = aa.course_instance_id
            AND pa.teaching_activity_id = aa.teaching_activity_id
        JOIN employee e ON aa.employee_id = e.id
        JOIN job_title jt ON e.job_title_id = jt.id
        JOIN person p ON e.person_id = p.id;

-- calculate planned hours for course instances in a specific year
DROP VIEW IF EXISTS query1 CASCADE;
CREATE VIEW query1 AS
    SELECT
        "Course Code",
        "Course Instance ID",
        "HP",
        "Period",
        "# Students",

        COALESCE(SUM(ROUND(planned_hours * factor)) FILTER (WHERE teaching_activity_id = 1), 0) AS "Lecture Hours",
        COALESCE(SUM(ROUND(planned_hours * factor)) FILTER (WHERE teaching_activity_id = 2), 0) AS "Tutorial Hours",
        COALESCE(SUM(ROUND(planned_hours * factor)) FILTER (WHERE teaching_activity_id = 3), 0) AS "Lab Hours",
        COALESCE(SUM(ROUND(planned_hours * factor)) FILTER (WHERE teaching_activity_id = 4), 0) AS "Seminar Hours",
        COALESCE(SUM(ROUND(planned_hours * factor)) FILTER (WHERE teaching_activity_id = 5), 0) AS "Other Overhead Hours",
        COALESCE(SUM(ROUND(planned_hours * factor)) FILTER (WHERE teaching_activity_id = 6), 0) AS "Admin",
        COALESCE(SUM(ROUND(planned_hours * factor)) FILTER (WHERE teaching_activity_id = 7), 0) AS "Exam",

        COALESCE(SUM(ROUND(planned_hours * factor)) FILTER (WHERE teaching_activity_id = 1), 0) +
        COALESCE(SUM(ROUND(planned_hours * factor)) FILTER (WHERE teaching_activity_id = 2), 0) +
        COALESCE(SUM(ROUND(planned_hours * factor)) FILTER (WHERE teaching_activity_id = 3), 0) +
        COALESCE(SUM(ROUND(planned_hours * factor)) FILTER (WHERE teaching_activity_id = 4), 0) +
        COALESCE(SUM(ROUND(planned_hours * factor)) FILTER (WHERE teaching_activity_id = 5), 0) +
        COALESCE(SUM(ROUND(planned_hours * factor)) FILTER (WHERE teaching_activity_id = 6), 0) +
        COALESCE(SUM(ROUND(planned_hours * factor)) FILTER (WHERE teaching_activity_id = 7), 0) AS "Total Hours"

    FROM
        collected_data

    WHERE
        study_year = '2025'

    GROUP BY
        "Course Code",
        "Course Instance ID",
        "HP",
        "Period", 
        "# Students";

-- calculate hours allocated for a course
DROP VIEW IF EXISTS query2 CASCADE;
CREATE VIEW query2 AS
    SELECT
        "Course Code", 
        "Course Instance ID", 
        "HP", 
        "Teacher's Name",
        "Designation",

        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 1), 0) AS "Lecture Hours",
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 2), 0) AS "Tutorial Hours",
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 3), 0) AS "Lab Hours",
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 4), 0) AS "Seminar Hours",
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 5), 0) AS "Other Overhead Hours",
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 6), 0) AS "Admin",
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 7), 0) AS "Exam",

        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 1), 0) +
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 2), 0) +
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 3), 0) +
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 4), 0) +
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 5), 0) +
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 6), 0) +
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 7), 0) AS "Total"

        FROM
            collected_data

        WHERE
            course_instance_id = 4

        GROUP BY
            "Course Code", 
            "Course Instance ID", 
            "HP", 
            "Teacher's Name",
            "Designation";

-- calculate hours allocated to a teacher over a year
DROP VIEW IF EXISTS query3 CASCADE;
CREATE VIEW query3 AS
    SELECT
        "Course Code",
        "Course Instance ID", 
        "HP",
        "Period",
        "Teacher's Name",

        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 1), 0) AS "Lecture Hours",
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 2), 0) AS "Tutorial Hours",
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 3), 0) AS "Lab Hours",
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 4), 0) AS "Seminar Hours",
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 5), 0) AS "Other Overhead Hours",
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 6), 0) AS "Admin",
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 7), 0) AS "Exam",

        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 1), 0) +
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 2), 0) +
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 3), 0) +
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 4), 0) +
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 5), 0) +
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 6), 0) +
        COALESCE(SUM(ROUND(allocated_hours * factor)) FILTER (WHERE teaching_activity_id = 7), 0) AS "Total"

    FROM 
        collected_data

    WHERE
        person_id = 120 AND study_year = '2025'

    GROUP BY
        "Course Code",
        "Course Instance ID",
        "HP",
        "Period",
        "Teacher's Name";

-- show the teacher's that have been allocated to more courses than the threshold in a specific period
DROP VIEW IF EXISTS query4 CASCADE;
CREATE VIEW query4 AS
    SELECT
        "Employment ID",
        "Teacher's Name",
        "Period",
        COUNT (DISTINCT course_instance_id) AS "No of courses"
    
    FROM 
        collected_data

    WHERE 
        "Period" = 'P3' AND study_year = '2025'

    GROUP BY
        "Employment ID",
        "Teacher's Name",
        "Period"
    HAVING COUNT (DISTINCT course_instance_id) > 0;
