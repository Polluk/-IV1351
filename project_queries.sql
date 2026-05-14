-- calculate planned hours for course instances in a specific year
DROP VIEW IF EXISTS query1 CASCADE;
CREATE VIEW query1 AS
    SELECT
        cl.course_code AS "Course Code",
        ci.instance_id AS "Course Instance ID",
        cl.hp AS "HP",
        ci.study_period AS "Period",
        ci.num_students AS "# Students",

        COALESCE(SUM(ROUND(pa.planned_hours * ta.factor)) FILTER (WHERE pa.teaching_activity_id = 1), 0) AS "Lecture Hours",
        COALESCE(SUM(ROUND(pa.planned_hours * ta.factor)) FILTER (WHERE pa.teaching_activity_id = 2), 0) AS "Tutorial Hours",
        COALESCE(SUM(ROUND(pa.planned_hours * ta.factor)) FILTER (WHERE pa.teaching_activity_id = 3), 0) AS "Lab Hours",
        COALESCE(SUM(ROUND(pa.planned_hours * ta.factor)) FILTER (WHERE pa.teaching_activity_id = 4), 0) AS "Seminar Hours",
        COALESCE(SUM(ROUND(pa.planned_hours * ta.factor)) FILTER (WHERE pa.teaching_activity_id = 5), 0) AS "Other Overhead Hours",
        COALESCE(SUM(ROUND(pa.planned_hours * ta.factor)) FILTER (WHERE pa.teaching_activity_id = 6), 0) AS "Admin",
        COALESCE(SUM(ROUND(pa.planned_hours * ta.factor)) FILTER (WHERE pa.teaching_activity_id = 7), 0) AS "Exam",

        COALESCE(SUM(ROUND(pa.planned_hours * ta.factor)) FILTER (WHERE pa.teaching_activity_id = 1), 0) +
        COALESCE(SUM(ROUND(pa.planned_hours * ta.factor)) FILTER (WHERE pa.teaching_activity_id = 2), 0) +
        COALESCE(SUM(ROUND(pa.planned_hours * ta.factor)) FILTER (WHERE pa.teaching_activity_id = 3), 0) +
        COALESCE(SUM(ROUND(pa.planned_hours * ta.factor)) FILTER (WHERE pa.teaching_activity_id = 4), 0) +
        COALESCE(SUM(ROUND(pa.planned_hours * ta.factor)) FILTER (WHERE pa.teaching_activity_id = 5), 0) +
        COALESCE(SUM(ROUND(pa.planned_hours * ta.factor)) FILTER (WHERE pa.teaching_activity_id = 6), 0) +
        COALESCE(SUM(ROUND(pa.planned_hours * ta.factor)) FILTER (WHERE pa.teaching_activity_id = 7), 0) AS "Total Hours"

    FROM 
        course_layout cl
        JOIN course_instance ci ON cl.id = ci.course_layout_id
        JOIN planned_activity pa ON ci.id = pa.course_instance_id
        JOIN teaching_activity ta ON pa.teaching_activity_id = ta.id

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
        cl.course_code AS "Course Code",
        ci.instance_id AS "Course Instance ID",
        cl.hp AS "HP",
        p.first_name || ' ' || p.last_name AS "Teacher's Name",
        jt.job_title AS "Designation",

        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 1), 0) AS "Lecture Hours",
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 2), 0) AS "Tutorial Hours",
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 3), 0) AS "Lab Hours",
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 4), 0) AS "Seminar Hours",
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 5), 0) AS "Other Overhead Hours",
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 6), 0) AS "Admin",
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 7), 0) AS "Exam",

        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 1), 0) +
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 2), 0) +
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 3), 0) +
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 4), 0) +
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 5), 0) +
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 6), 0) +
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 7), 0) AS "Total"

        FROM
            course_layout cl
            JOIN course_instance ci ON cl.id = ci.course_layout_id
            RIGHT JOIN allocated_activity aa ON ci.id = aa.course_instance_id
            JOIN teaching_activity ta ON aa.teaching_activity_id = ta.id
            JOIN employee e ON aa.employee_id = e.id
            JOIN job_title jt ON e.job_title_id = jt.id
            JOIN person p ON e.person_id = p.id

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
        cl.course_code AS "Course Code",
        ci.instance_id AS "Course Instance ID",
        cl.hp AS "HP",
        ci.study_period AS "Period",
        p.first_name || ' ' || p.last_name AS "Teacher's Name",

        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 1), 0) AS "Lecture Hours",
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 2), 0) AS "Tutorial Hours",
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 3), 0) AS "Lab Hours",
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 4), 0) AS "Seminar Hours",
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 5), 0) AS "Other Overhead Hours",
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 6), 0) AS "Admin",
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 7), 0) AS "Exam",

        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 1), 0) +
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 2), 0) +
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 3), 0) +
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 4), 0) +
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 5), 0) +
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 6), 0) +
        COALESCE(SUM(ROUND(aa.allocated_hours * ta.factor)) FILTER (WHERE aa.teaching_activity_id = 7), 0) AS "Total"

    FROM 
        course_layout cl
        JOIN course_instance ci ON cl.id = ci.course_layout_id
        RIGHT JOIN allocated_activity aa ON ci.id = aa.course_instance_id
        JOIN teaching_activity ta ON aa.teaching_activity_id = ta.id
        JOIN employee e ON aa.employee_id = e.id
        JOIN person p ON e.person_id = p.id

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
        aa.employee_id AS "Employment ID",
        p.first_name || ' ' || p.last_name AS "Teacher's Name",
        ci.study_period AS "Period",
        COUNT (DISTINCT aa.course_instance_id) AS "No of courses"
    
    FROM 
        allocated_activity aa
        JOIN employee e ON aa.employee_id = e.id
        JOIN person p ON e.person_id = p.id
        JOIN course_instance ci ON aa.course_instance_id = ci.id

    WHERE 
        study_period = 'P3' AND study_year = '2025'

    GROUP BY
        "Employment ID",
        "Teacher's Name",
        "Period"
    HAVING COUNT (DISTINCT course_instance_id) > 0;
