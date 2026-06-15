USE timetable_db;

-- ==================================================================
-- 1. CLEAN SLATE FOR ASSIGNMENTS (To ensure exactly 7 per course)
-- ==================================================================
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE subject_assignments;
TRUNCATE TABLE curriculum;
TRUNCATE TABLE teacher_qualifications; 
-- We truncate qualifications to rebuild them cleanly for the new subjects
SET FOREIGN_KEY_CHECKS = 1;

-- ==================================================================
-- 2. ENSURE ALL REQUIRED SUBJECTS EXIST
-- ==================================================================
-- We will insert any missing subjects needed to reach 7 per course.
-- Duplicate names will be skipped due to logic or handled by IDs.
-- Note: We are truncating subjects to ensure clean IDs for this batch, 
-- or you can run this on top. To be safe, let's keep existing and add new.

INSERT INTO subjects (name, code, requires_room_type, credits) VALUES
-- BCA Year 1
('C Programming', 'BCA102', 'LAB', 4),
('Digital Logic', 'BCA103', 'LECTURE', 3),
('Communication Skills', 'HU101', 'SEMINAR', 2),
('PC Software & Automation', 'BCA104', 'LAB', 3),
('Environmental Science', 'EV101', 'LECTURE', 2),
('Foundation Mathematics', 'MATH102', 'LECTURE', 4),

-- BCA Year 2 (Adding to existing OS, Web, etc.)
('Software Engineering', 'CS305', 'LECTURE', 3),
('Python Programming', 'CS306', 'LAB', 3),

-- B.Tech Year 1
('Engineering Chemistry', 'CH101', 'LAB', 4),
('Basic Electrical Eng', 'EE101', 'LAB', 4),
('Engineering Mechanics', 'ME101', 'LECTURE', 3),
('Workshop Practice', 'ME102', 'LAB', 2),
('Computer Programming', 'CS101', 'LAB', 4),

-- B.Tech Year 2
('Engineering Math III', 'MATH201', 'LECTURE', 4),
('Analog Electronics', 'EC202', 'LAB', 4),
('Signals & Systems', 'EC203', 'LECTURE', 3),
('Circuit Theory', 'EE201', 'LECTURE', 3),
('Economics for Engineers', 'HU201', 'LECTURE', 2),

-- BBA Year 1
('Principles of Management', 'BBA102', 'LECTURE', 3),
('Business Economics', 'BBA103', 'LECTURE', 3),
('Business Mathematics', 'BBA104', 'LECTURE', 4),
('Computer Applications', 'BBA105', 'LAB', 3),
('Business Communication', 'BBA106', 'SEMINAR', 2),

-- BBA Year 2
('Human Resource Mgmt', 'BBA204', 'LECTURE', 3),
('Business Law', 'BBA205', 'LECTURE', 3),
('Cost Accounting', 'BBA206', 'LECTURE', 4),
('Macroeconomics', 'BBA207', 'LECTURE', 3),
('Business Ethics', 'BBA208', 'SEMINAR', 2);

-- ==================================================================
-- 3. MAP TEACHERS TO THESE NEW SUBJECTS
-- ==================================================================
-- We map teachers based on the subjects we just decided on.

-- Helper procedure to safely insert qualification if not exists
DROP PROCEDURE IF EXISTS AddQual;
DELIMITER //
CREATE PROCEDURE AddQual(IN t_email VARCHAR(100), IN s_name VARCHAR(100), IN lvl VARCHAR(20))
BEGIN
    INSERT IGNORE INTO teacher_qualifications (teacher_id, subject_id, proficiency_level)
    SELECT t.teacher_id, s.subject_id, lvl
    FROM teachers t, subjects s
    WHERE t.email = t_email AND s.name = s_name;
END //
DELIMITER ;

-- BCA 1 Teachers
CALL AddQual('einstein@uni.com', 'Calculus I', 'EXPERT');
CALL AddQual('hopper@uni.com', 'C Programming', 'EXPERT');
CALL AddQual('maxwell@uni.com', 'Digital Logic', 'ADVANCED');
CALL AddQual('curie@uni.com', 'Communication Skills', 'INTERMEDIATE');
CALL AddQual('hopper@uni.com', 'PC Software & Automation', 'EXPERT');
CALL AddQual('curie@uni.com', 'Environmental Science', 'ADVANCED');
CALL AddQual('nash@uni.com', 'Foundation Mathematics', 'EXPERT');

-- BCA 2 Teachers
CALL AddQual('turing@uni.com', 'Data Structures', 'EXPERT');
CALL AddQual('khan@uni.com', 'Database Systems', 'ADVANCED');
CALL AddQual('knuth@uni.com', 'Operating Systems', 'EXPERT');
CALL AddQual('hopper@uni.com', 'Computer Networks', 'EXPERT');
CALL AddQual('nash@uni.com', 'Discrete Mathematics', 'EXPERT');
CALL AddQual('hopper@uni.com', 'Web Technologies', 'EXPERT');
CALL AddQual('knuth@uni.com', 'Software Engineering', 'EXPERT');

-- B.Tech 1 Teachers
CALL AddQual('einstein@uni.com', 'Intro to Engineering', 'EXPERT');
CALL AddQual('nash@uni.com', 'Calculus I', 'ADVANCED');
CALL AddQual('curie@uni.com', 'Engineering Chemistry', 'EXPERT');
CALL AddQual('maxwell@uni.com', 'Basic Electrical Eng', 'EXPERT');
CALL AddQual('sharma@uni.com', 'Engineering Mechanics', 'EXPERT');
CALL AddQual('turing@uni.com', 'Computer Programming', 'EXPERT');
CALL AddQual('sharma@uni.com', 'Workshop Practice', 'ADVANCED');

-- B.Tech 2 Teachers
CALL AddQual('nash@uni.com', 'Engineering Math III', 'EXPERT');
CALL AddQual('maxwell@uni.com', 'Analog Electronics', 'EXPERT');
CALL AddQual('maxwell@uni.com', 'Digital Electronics', 'EXPERT');
CALL AddQual('maxwell@uni.com', 'Thermodynamics', 'ADVANCED');
CALL AddQual('hopper@uni.com', 'Signals & Systems', 'ADVANCED');
CALL AddQual('sharma@uni.com', 'Circuit Theory', 'EXPERT');
CALL AddQual('khan@uni.com', 'Economics for Engineers', 'ADVANCED');

-- BBA 1 Teachers
CALL AddQual('khan@uni.com', 'Business Management 101', 'EXPERT');
CALL AddQual('kotler@uni.com', 'Principles of Management', 'EXPERT');
CALL AddQual('khan@uni.com', 'Business Economics', 'EXPERT');
CALL AddQual('nash@uni.com', 'Financial Accounting', 'ADVANCED'); -- Nash is good at math/numbers
CALL AddQual('nash@uni.com', 'Business Mathematics', 'EXPERT');
CALL AddQual('turing@uni.com', 'Computer Applications', 'INTERMEDIATE');
CALL AddQual('kotler@uni.com', 'Business Communication', 'EXPERT');

-- BBA 2 Teachers
CALL AddQual('kotler@uni.com', 'Marketing Management', 'EXPERT');
CALL AddQual('kotler@uni.com', 'Organizational Behavior', 'EXPERT');
CALL AddQual('nash@uni.com', 'Financial Accounting', 'EXPERT'); -- Reusing Fin Acct subject or creating specialized
CALL AddQual('kotler@uni.com', 'Human Resource Mgmt', 'EXPERT');
CALL AddQual('khan@uni.com', 'Business Law', 'ADVANCED');
CALL AddQual('nash@uni.com', 'Cost Accounting', 'ADVANCED');
CALL AddQual('khan@uni.com', 'Macroeconomics', 'EXPERT');

-- ==================================================================
-- 4. INSERT CURRICULUM & ASSIGNMENTS (7 SUBJECTS PER COURSE)
-- ==================================================================

-- Helper procedure to assign a subject to a program, year, and section
DROP PROCEDURE IF EXISTS AssignCourse;
DELIMITER //
CREATE PROCEDURE AssignCourse(
    IN prog_code VARCHAR(10), 
    IN yr INT, 
    IN sub_name VARCHAR(100), 
    IN teach_email VARCHAR(100), 
    IN hours INT,
    IN sec_name VARCHAR(10)
)
BEGIN
    DECLARE p_id INT;
    DECLARE s_id INT;
    DECLARE t_id INT;
    DECLARE sec_id INT;
    DECLARE sem_id INT;

    SELECT program_id INTO p_id FROM programs WHERE short_code = prog_code;
    SELECT subject_id INTO s_id FROM subjects WHERE name = sub_name LIMIT 1;
    SELECT teacher_id INTO t_id FROM teachers WHERE email = teach_email;
    SELECT section_id INTO sec_id FROM sections WHERE program_id = p_id AND year = yr AND section_name = sec_name LIMIT 1;
    SELECT semester_id INTO sem_id FROM sections WHERE section_id = sec_id;

    -- Add to Curriculum (if not exists)
    INSERT IGNORE INTO curriculum (program_id, year, subject_id, is_core) VALUES (p_id, yr, s_id, TRUE);

    -- Add to Assignments
    INSERT INTO subject_assignments (subject_id, teacher_id, section_id, hours_per_week, semester_id) 
    VALUES (s_id, t_id, sec_id, hours, sem_id);
END //
DELIMITER ;

-- ------------------------------------------------------------------
-- BCA 1 (Section A) - 7 Subjects
-- ------------------------------------------------------------------
CALL AssignCourse('BCA', 1, 'Calculus I', 'einstein@uni.com', 4, 'A');
CALL AssignCourse('BCA', 1, 'C Programming', 'hopper@uni.com', 4, 'A');
CALL AssignCourse('BCA', 1, 'Digital Logic', 'maxwell@uni.com', 3, 'A');
CALL AssignCourse('BCA', 1, 'Communication Skills', 'curie@uni.com', 2, 'A');
CALL AssignCourse('BCA', 1, 'PC Software & Automation', 'hopper@uni.com', 3, 'A');
CALL AssignCourse('BCA', 1, 'Environmental Science', 'curie@uni.com', 2, 'A');
CALL AssignCourse('BCA', 1, 'Foundation Mathematics', 'nash@uni.com', 4, 'A');

-- ------------------------------------------------------------------
-- BCA 2 (Section A) - 7 Subjects
-- ------------------------------------------------------------------
CALL AssignCourse('BCA', 2, 'Data Structures', 'turing@uni.com', 4, 'A');
CALL AssignCourse('BCA', 2, 'Database Systems', 'khan@uni.com', 4, 'A');
CALL AssignCourse('BCA', 2, 'Operating Systems', 'knuth@uni.com', 3, 'A');
CALL AssignCourse('BCA', 2, 'Computer Networks', 'hopper@uni.com', 3, 'A');
CALL AssignCourse('BCA', 2, 'Discrete Mathematics', 'nash@uni.com', 4, 'A');
CALL AssignCourse('BCA', 2, 'Web Technologies', 'hopper@uni.com', 3, 'A');
CALL AssignCourse('BCA', 2, 'Software Engineering', 'knuth@uni.com', 3, 'A');

-- ------------------------------------------------------------------
-- B.Tech 1 (Section A) - 7 Subjects
-- ------------------------------------------------------------------
CALL AssignCourse('B.Tech', 1, 'Intro to Engineering', 'einstein@uni.com', 2, 'A');
CALL AssignCourse('B.Tech', 1, 'Calculus I', 'nash@uni.com', 4, 'A');
CALL AssignCourse('B.Tech', 1, 'Engineering Chemistry', 'curie@uni.com', 3, 'A');
CALL AssignCourse('B.Tech', 1, 'Basic Electrical Eng', 'maxwell@uni.com', 3, 'A');
CALL AssignCourse('B.Tech', 1, 'Engineering Mechanics', 'sharma@uni.com', 3, 'A');
CALL AssignCourse('B.Tech', 1, 'Computer Programming', 'turing@uni.com', 4, 'A');
CALL AssignCourse('B.Tech', 1, 'Workshop Practice', 'sharma@uni.com', 3, 'A');

-- ------------------------------------------------------------------
-- B.Tech 2 (Section A) - 7 Subjects
-- ------------------------------------------------------------------
CALL AssignCourse('B.Tech', 2, 'Engineering Math III', 'nash@uni.com', 4, 'A');
CALL AssignCourse('B.Tech', 2, 'Analog Electronics', 'maxwell@uni.com', 3, 'A');
CALL AssignCourse('B.Tech', 2, 'Digital Electronics', 'maxwell@uni.com', 3, 'A');
CALL AssignCourse('B.Tech', 2, 'Thermodynamics', 'maxwell@uni.com', 3, 'A');
CALL AssignCourse('B.Tech', 2, 'Signals & Systems', 'hopper@uni.com', 3, 'A');
CALL AssignCourse('B.Tech', 2, 'Circuit Theory', 'sharma@uni.com', 3, 'A');
CALL AssignCourse('B.Tech', 2, 'Economics for Engineers', 'khan@uni.com', 2, 'A');

-- ------------------------------------------------------------------
-- BBA 1 (Section A) - 7 Subjects
-- ------------------------------------------------------------------
CALL AssignCourse('BBA', 1, 'Business Management 101', 'khan@uni.com', 3, 'A');
CALL AssignCourse('BBA', 1, 'Principles of Management', 'kotler@uni.com', 3, 'A');
CALL AssignCourse('BBA', 1, 'Business Economics', 'khan@uni.com', 3, 'A');
CALL AssignCourse('BBA', 1, 'Financial Accounting', 'nash@uni.com', 4, 'A');
CALL AssignCourse('BBA', 1, 'Business Mathematics', 'nash@uni.com', 3, 'A');
CALL AssignCourse('BBA', 1, 'Computer Applications', 'turing@uni.com', 3, 'A');
CALL AssignCourse('BBA', 1, 'Business Communication', 'kotler@uni.com', 2, 'A');

-- ------------------------------------------------------------------
-- BBA 2 (Section A) - 7 Subjects
-- ------------------------------------------------------------------
CALL AssignCourse('BBA', 2, 'Marketing Management', 'kotler@uni.com', 3, 'A');
CALL AssignCourse('BBA', 2, 'Organizational Behavior', 'kotler@uni.com', 3, 'A');
CALL AssignCourse('BBA', 2, 'Cost Accounting', 'nash@uni.com', 4, 'A'); -- Using Cost Acct for variety
CALL AssignCourse('BBA', 2, 'Human Resource Mgmt', 'kotler@uni.com', 3, 'A');
CALL AssignCourse('BBA', 2, 'Business Law', 'khan@uni.com', 3, 'A');
CALL AssignCourse('BBA', 2, 'Macroeconomics', 'khan@uni.com', 3, 'A');
CALL AssignCourse('BBA', 2, 'Business Ethics', 'khan@uni.com', 2, 'A'); -- Filler seminar

-- ==================================================================
-- 5. FINAL VERIFICATION
-- ==================================================================
SELECT 
    p.short_code AS Program,
    sec.year AS Year,
    sec.section_name AS Section,
    COUNT(sa.subject_id) AS Subject_Count
FROM subject_assignments sa
JOIN sections sec ON sa.section_id = sec.section_id
JOIN programs p ON sec.program_id = p.program_id
GROUP BY p.short_code, sec.year, sec.section_name
ORDER BY Subject_Count DESC;


USE timetable_db;

-- 1. ADD THE MISSING SPECIALIZED TEACHERS
INSERT IGNORE INTO teachers (user_id, name, email, employee_id, department) VALUES
(NULL, 'Prof. Donald Knuth', 'knuth@uni.com', 'EMP006', 'Computer Science'),
(NULL, 'Prof. James Maxwell', 'maxwell@uni.com', 'EMP007', 'Electronics'),
(NULL, 'Prof. John Nash', 'nash@uni.com', 'EMP008', 'Mathematics'),
(NULL, 'Prof. Grace Hopper', 'hopper@uni.com', 'EMP009', 'Computer Science'),
(NULL, 'Prof. Philip Kotler', 'kotler@uni.com', 'EMP010', 'Management');

-- 2. ADD AVAILABILITY FOR THESE NEW TEACHERS (Standard 9-5)
INSERT IGNORE INTO teacher_availability (teacher_id, day_of_week, start_time, end_time) 
SELECT teacher_id, day, '09:00:00', '17:00:00'
FROM teachers t
CROSS JOIN (
    SELECT 'Monday' as day UNION SELECT 'Tuesday' UNION SELECT 'Wednesday' 
    UNION SELECT 'Thursday' UNION SELECT 'Friday'
) d
WHERE t.email IN ('knuth@uni.com', 'maxwell@uni.com', 'nash@uni.com', 'hopper@uni.com', 'kotler@uni.com');

SELECT 'Teachers added successfully. You can now run the previous assignment script.' as status;