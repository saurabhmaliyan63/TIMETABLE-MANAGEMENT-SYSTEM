-- Create and use the database
CREATE DATABASE IF NOT EXISTS timetable_db;
USE timetable_db;

-- 1. DROP ALL TABLES SAFELY
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS generated_timetable;
DROP TABLE IF EXISTS timetable_slots;
DROP TABLE IF EXISTS subject_assignments;
DROP TABLE IF EXISTS curriculum;
DROP TABLE IF EXISTS teacher_qualifications;
DROP TABLE IF EXISTS timeslots;
DROP TABLE IF EXISTS subjects;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS teacher_availability;
DROP TABLE IF EXISTS teachers;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS sections;
DROP TABLE IF EXISTS programs;
DROP TABLE IF EXISTS users;

SET FOREIGN_KEY_CHECKS = 1;

-- 2. CREATE ALL TABLES (with improvements)

-- Users table
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    `password` VARCHAR(100) NOT NULL,
    role ENUM('student', 'teacher', 'coordinator', 'admin') NOT NULL,
    INDEX idx_username (username)
);

-- Programs table
CREATE TABLE programs (
    program_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    short_code VARCHAR(10) UNIQUE,
    department VARCHAR(100),
    duration_years INT,
    INDEX idx_short_code (short_code)
);

-- Sections table
CREATE TABLE sections (
    section_id INT AUTO_INCREMENT PRIMARY KEY,
    section_name VARCHAR(100) NOT NULL,
    program_id INT,
    year INT NOT NULL,
    size INT NOT NULL CHECK (size > 0),
    FOREIGN KEY (program_id) REFERENCES programs(program_id) ON DELETE SET NULL,
    INDEX idx_program_id (program_id)
);

-- Students table
CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    section_id INT,
    name VARCHAR(100) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (section_id) REFERENCES sections(section_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_section_id (section_id)
);

-- Teachers table
CREATE TABLE teachers (
    teacher_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_email (email)
);

-- Teacher Availability table (with unique constraint and check)
CREATE TABLE teacher_availability (
    avail_id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
    start_time TIME,
    end_time TIME,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    UNIQUE(teacher_id, day_of_week, start_time, end_time),
    CHECK (end_time > start_time),
    INDEX idx_teacher_id (teacher_id)
);

-- Rooms table
CREATE TABLE rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    type ENUM('LECTURE', 'LAB', 'SEMINAR', 'AUDITORIUM') NOT NULL,
    INDEX idx_type (type)
);

-- Subjects table
CREATE TABLE subjects (
    subject_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    requires_room_type ENUM('LECTURE', 'LAB', 'SEMINAR') DEFAULT NULL
);

-- Teacher Qualifications table
CREATE TABLE teacher_qualifications (
    qualification_id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT,
    subject_id INT,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE,
    UNIQUE(teacher_id, subject_id),
    INDEX idx_teacher_id (teacher_id),
    INDEX idx_subject_id (subject_id)
);

-- Curriculum table
CREATE TABLE curriculum (
    curriculum_id INT AUTO_INCREMENT PRIMARY KEY,
    program_id INT,
    year INT NOT NULL,
    subject_id INT,
    FOREIGN KEY (program_id) REFERENCES programs(program_id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE,
    UNIQUE(program_id, year, subject_id),
    INDEX idx_program_year (program_id, year)
);

-- Master Timeslots table (with check constraint)
CREATE TABLE timeslots (
    timeslot_id INT AUTO_INCREMENT PRIMARY KEY,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    UNIQUE(day_of_week, start_time),
    CHECK (end_time > start_time),
    INDEX idx_day_time (day_of_week, start_time)
);

-- Subject Assignments table
CREATE TABLE subject_assignments (
    assign_id INT AUTO_INCREMENT PRIMARY KEY,
    subject_id INT,
    teacher_id INT,
    section_id INT,
    hours_per_week INT NOT NULL CHECK (hours_per_week > 0),
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id),
    FOREIGN KEY (section_id) REFERENCES sections(section_id),
    INDEX idx_teacher_id (teacher_id),
    INDEX idx_section_id (section_id),
    INDEX idx_subject_id (subject_id)
);

-- Timetable Slots table
CREATE TABLE timetable_slots (
    slot_id INT AUTO_INCREMENT PRIMARY KEY,
    timeslot_id INT,
    subject_id INT,
    teacher_id INT,
    section_id INT,
    room_id INT,
    FOREIGN KEY (timeslot_id) REFERENCES timeslots(timeslot_id),
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id),
    FOREIGN KEY (section_id) REFERENCES sections(section_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    INDEX idx_timeslot_id (timeslot_id),
    INDEX idx_teacher_id (teacher_id),
    INDEX idx_room_id (room_id),
    INDEX idx_section_id (section_id)
);

-- Generated Timetable table
CREATE TABLE generated_timetable (
    id INT AUTO_INCREMENT PRIMARY KEY,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    timeslot_id INT,
    room_id INT,
    teacher_id INT,
    subject_id INT,
    section_id INT,
    FOREIGN KEY (timeslot_id) REFERENCES timeslots(timeslot_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id),
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
    FOREIGN KEY (section_id) REFERENCES sections(section_id),
    INDEX idx_timeslot_id (timeslot_id),
    INDEX idx_teacher_id (teacher_id),
    INDEX idx_room_id (room_id),
    INDEX idx_section_id (section_id),
    INDEX idx_day (day_of_week)
);

-- 3. INSERT LARGER TEST DATA

-- Insert Users (45 total)
INSERT INTO users (username, `password`, role) VALUES
-- Admins/Coordinators (1-2)
('admin', 'admin_pass123', 'admin'),
('coordinator', 'coord_pass123', 'coordinator'),
-- Original Teachers (3-7)
('prof_einstein', 'teacher_pass1', 'teacher'),
('prof_curie', 'teacher_pass2', 'teacher'),
('prof_turing', 'teacher_pass3', 'teacher'),
('prof_sharma', 'teacher_pass4', 'teacher'),
('prof_khan', 'teacher_pass5', 'teacher'),
-- Original Students (8-15)
('student_alice', 'student_pass1', 'student'),
('student_bob', 'student_pass2', 'student'),
('student_charlie', 'student_pass3', 'student'),
('student_dave', 'student_pass4', 'student'),
('student_eve', 'student_pass5', 'student'),
('student_frank', 'student_pass6', 'student'),
('student_grace', 'student_pass7', 'student'),
('student_heidi', 'student_pass8', 'student'),
-- New Teachers (16-25)
('prof_davis', 'pass123', 'teacher'),
('prof_lee', 'pass123', 'teacher'),
('prof_chen', 'pass123', 'teacher'),
('prof_patel', 'pass123', 'teacher'),
('prof_bose', 'pass123', 'teacher'),
('prof_singh', 'pass123', 'teacher'),
('prof_murphy', 'pass123', 'teacher'),
('prof_gonzalez', 'pass123', 'teacher'),
('prof_smith', 'pass123', 'teacher'),
('prof_owens', 'pass123', 'teacher'),
-- New Students (26-45)
('student_ivan', 'pass123', 'student'),
('student_julia', 'pass123', 'student'),
('student_karl', 'pass123', 'student'),
('student_laura', 'pass123', 'student'),
('student_mike', 'pass123', 'student'),
('student_nina', 'pass123', 'student'),
('student_oscar', 'pass123', 'student'),
('student_paula', 'pass123', 'student'),
('student_quinn', 'pass123', 'student'),
('student_rachel', 'pass123', 'student'),
('student_sam', 'pass123', 'student'),
('student_tina', 'pass123', 'student'),
('student_umar', 'pass123', 'student'),
('student_vera', 'pass123', 'student'),
('student_will', 'pass123', 'student'),
('student_xena', 'pass123', 'student'),
('student_yara', 'pass123', 'student'),
('student_zack', 'pass123', 'student'),
('student_amy', 'pass123', 'student'),
('student_ben', 'pass123', 'student');

-- Insert Programs (6 total)
INSERT INTO programs (name, short_code, department, duration_years) VALUES
('Bachelor of Computer Applications', 'BCA', 'School of Computing', 3),
('Bachelor of Technology', 'B.Tech', 'School of Engineering', 4),
('Bachelor of Business Administration', 'BBA', 'School of Management', 3),
('Master of Technology', 'M.Tech', 'School of Engineering', 2),
('B.Sc. Physics', 'BSc-PHY', 'School of Sciences', 3),
('Master of Business Administration', 'MBA', 'School of Management', 2);

-- Insert Sections (18 total)
-- program_ids: BCA=1, B.Tech=2, BBA=3, M.Tech=4, BSc-PHY=5, MBA=6
INSERT INTO sections (program_id, year, section_name, size) VALUES
(1, 1, 'A', 45), -- 1: BCA 1A
(1, 1, 'B', 50), -- 2: BCA 1B
(1, 2, 'A', 40), -- 3: BCA 2A
(2, 1, 'A', 60), -- 4: B.Tech 1A
(2, 2, 'A', 55), -- 5: B.Tech 2A
(3, 1, 'A', 70), -- 6: BBA 1A
(1, 2, 'B', 42), -- 7: BCA 2B (New)
(1, 3, 'A', 38), -- 8: BCA 3A (New)
(2, 1, 'B', 60), -- 9: B.Tech 1B (New)
(2, 2, 'B', 58), -- 10: B.Tech 2B (New)
(2, 3, 'A', 50), -- 11: B.Tech 3A (New)
(3, 1, 'B', 70), -- 12: BBA 1B (New)
(3, 2, 'A', 65), -- 13: BBA 2A (New)
(4, 1, 'A', 30), -- 14: M.Tech 1A (New)
(5, 1, 'A', 40), -- 15: BSc-PHY 1A (New)
(5, 2, 'A', 35), -- 16: BSc-PHY 2A (New)
(6, 1, 'A', 60), -- 17: MBA 1A (New)
(6, 1, 'B', 60); -- 18: MBA 1B (New)

-- Insert Students (28 total)
-- user_ids: alice=8...heidi=15 (Original)
-- user_ids: ivan=26...ben=45 (New)
INSERT INTO students (user_id, section_id, name) VALUES
(8, 1, 'Alice Smith'),
(9, 1, 'Bob Johnson'),
(10, 2, 'Charlie Brown'),
(11, 2, 'Dave Davis'),
(12, 3, 'Eve Williams'),
(13, 4, 'Frank Miller'),
(14, 5, 'Grace Lee'),
(15, 6, 'Heidi Wilson'),
-- Populate new sections
(26, 7, 'Ivan Ivanov'),
(27, 7, 'Julia Kims'),
(28, 8, 'Karl Marx'),
(29, 8, 'Laura Moon'),
(30, 9, 'Mike Ross'),
(31, 9, 'Nina Simone'),
(32, 10, 'Oscar Wilde'),
(33, 10, 'Paula Ried'),
(34, 11, 'Quinn Fabray'),
(35, 11, 'Rachel Green'),
(36, 12, 'Sam Tarly'),
(37, 12, 'Tina Cohen'),
(38, 13, 'Umar Akmal'),
(39, 13, 'Vera Wang'),
(40, 14, 'Will Turner'),
(41, 14, 'Xena Warrior'),
(42, 15, 'Yara Greyjoy'),
(43, 16, 'Zack Snyder'),
(44, 17, 'Amy Pond'),
(45, 18, 'Ben Wyatt');

-- Insert Teachers (15 total)
-- user_ids: 3-7 (Original)
-- user_ids: 16-25 (New)
INSERT INTO teachers (user_id, name, email) VALUES
(3, 'Albert Einstein', 'einstein@uni.com'), -- 1
(4, 'Marie Curie', 'curie@uni.com'), 	 -- 2
(5, 'Alan Turing', 'turing@uni.com'), 	 -- 3
(6, 'Rohan Sharma', 'sharma@uni.com'), 	 -- 4
(7, 'Ayesha Khan', 'khan@uni.com'), 		 -- 5
(16, 'Daniel Davis', 'davis@uni.com'), 	 -- 6
(17, 'Emily Lee', 'lee@uni.com'), 		 -- 7
(18, 'Frank Chen', 'chen@uni.com'), 		 -- 8
(19, 'Grace Patel', 'patel@uni.com'), 	 -- 9
(20, 'Henry Bose', 'bose@uni.com'), 		 -- 10
(21, 'Ishaan Singh', 'singh@uni.com'), 	 -- 11
(22, 'Jane Murphy', 'murphy@uni.com'), 	 -- 12
(23, 'Ken Gonzalez', 'gonzalez@uni.com'),-- 13
(24, 'Linda Smith', 'smith@uni.com'), 	 -- 14
(25, 'Mike Owens', 'owens@uni.com'); 	 -- 15

-- Insert Teacher Availability
INSERT INTO teacher_availability (teacher_id, day_of_week, start_time, end_time) VALUES
-- Original 5
(1, 'Monday', '09:00:00', '17:00:00'),
(1, 'Tuesday', '09:00:00', '17:00:00'),
(1, 'Wednesday', '09:00:00', '12:00:00'),
(2, 'Wednesday', '13:00:00', '17:00:00'),
(2, 'Thursday', '09:00:00', '17:00:00'),
(2, 'Friday', '09:00:00', '17:00:00'),
(3, 'Monday', '09:00:00', '17:00:00'),
(3, 'Friday', '09:00:00', '17:00:00'),
(4, 'Tuesday', '09:00:00', '12:00:00'),
(4, 'Thursday', '09:00:00', '12:00:00'),
(5, 'Monday', '13:00:00', '17:00:00'),
(5, 'Tuesday', '13:00:00', '17:00:00'),
(5, 'Wednesday', '09:00:00', '17:00:00'),
-- New 10 (IDs 6-15)
(6, 'Monday', '09:00:00', '11:00:00'),
(6, 'Wednesday', '10:00:00', '12:00:00'),
(7, 'Tuesday', '13:00:00', '17:00:00'),
(7, 'Thursday', '13:00:00', '17:00:00'),
(8, 'Monday', '09:00:00', '17:00:00'),
(8, 'Tuesday', '09:00:00', '17:00:00'),
(9, 'Wednesday', '09:00:00', '17:00:00'),
(9, 'Thursday', '09:00:00', '17:00:00'),
(10, 'Friday', '09:00:00', '14:00:00'),
(11, 'Monday', '09:00:00', '12:00:00'),
(11, 'Tuesday', '09:00:00', '12:00:00'),
(12, 'Wednesday', '13:00:00', '16:00:00'),
(12, 'Thursday', '10:00:00', '14:00:00'),
(13, 'Friday', '09:00:00', '17:00:00'),
(14, 'Monday', '10:00:00', '14:00:00'),
(14, 'Tuesday', '10:00:00', '14:00:00'),
(15, 'Wednesday', '09:00:00', '17:00:00'),
(15, 'Thursday', '09:00:00', '17:00:00');

-- Insert Rooms (15 total)
INSERT INTO rooms (name, capacity, type) VALUES
('Main Hall (A-101)', 65, 'LECTURE'), -- 1
('West Wing (W-202)', 45, 'LECTURE'), -- 2
('Computer Lab (CS-01)', 50, 'LAB'), -- 3
('Auditorium', 150, 'AUDITORIUM'), -- 4
('Seminar Hall (S-101)', 75, 'SEMINAR'), -- 5
('Computer Lab (CS-02)', 50, 'LAB'), -- 6
('East Hall (E-101)', 70, 'LECTURE'), -- 7
('East Hall (E-102)', 70, 'LECTURE'), -- 8
('Main Hall (A-102)', 65, 'LECTURE'), -- 9
('West Wing (W-203)', 50, 'LECTURE'), -- 10
('Physics Lab (PHY-01)', 45, 'LAB'), -- 11
('Electronics Lab (EE-01)', 45, 'LAB'), -- 12
('Seminar Hall (S-102)', 75, 'SEMINAR'), -- 13
('Seminar Hall (S-201)', 80, 'SEMINAR'), -- 14
('M.Tech Lab (CS-M1)', 35, 'LAB'); -- 15

-- Insert Subjects (22 total)
INSERT INTO subjects (name, requires_room_type) VALUES
('Physics 101', NULL), -- 1
('History of Science', NULL), -- 2
('Calculus I', NULL), -- 3
('Data Structures', 'LAB'), -- 4
('Intro to Engineering', 'LECTURE'), -- 5
('Database Systems', 'LAB'), -- 6
('Business Management 101', 'SEMINAR'), -- 7
('Advanced Algorithms', 'SEMINAR'), -- 8
-- New Subjects
('Software Engineering', 'LAB'), -- 9 (BCA 3)
('AI Concepts', 'SEMINAR'), -- 10 (BCA 3)
('Thermodynamics', 'LECTURE'), -- 11 (B.Tech 3)
('Digital Circuits', 'LAB'), -- 12 (B.Tech 3)
('Advanced DBMS', 'LAB'), -- 13 (M.Tech 1)
('Machine Learning', 'LAB'), -- 14 (M.Tech 1)
('Mechanics', 'LECTURE'), -- 15 (BSc-PHY 1)
('Optics Lab', 'LAB'), -- 16 (BSc-PHY 1)
('Quantum Mechanics', 'LECTURE'), -- 17 (BSc-PHY 2)
('Electronics Lab', 'LAB'), -- 18 (BSc-PHY 2)
('Marketing', 'SEMINAR'), -- 19 (BBA 2)
('Managerial Finance', 'SEMINAR'), -- 20 (BBA 2)
('Organizational Behavior', 'SEMINAR'), -- 21 (MBA 1)
('Financial Accounting', 'LECTURE'); -- 22 (MBA 1)

-- Insert Teacher Qualifications
-- Teacher IDs: 1-15
-- Subject IDs: 1-22
INSERT INTO teacher_qualifications (teacher_id, subject_id) VALUES
-- Original
(1, 1), (1, 3), -- Einstein: Physics, Calculus
(2, 2), -- Curie: History
(3, 4), (3, 8), -- Turing: Data Structures, Advanced Algorithms
(4, 5), (4, 1), -- Sharma: Engineering, Physics
(5, 6), (5, 7), -- Khan: DBMS, Business
-- New
(1, 15), (1, 17), -- Einstein also teaches Mechanics, Quantum Mechanics
(3, 14), (3, 10), -- Turing also teaches ML, AI Concepts
(5, 13), -- Khan also teaches Advanced DBMS
(6, 9), (6, 12), -- Davis: Software Eng, Digital Circuits
(7, 11), (7, 5), -- Lee: Thermodynamics, Intro to Eng
(8, 13), (8, 6), -- Chen: Advanced DBMS, Database Systems
(9, 15), (9, 16), -- Patel: Mechanics, Optics Lab
(10, 17), (10, 18), -- Bose: Quantum Mechanics, Electronics Lab
(11, 12), (11, 18), -- Singh: Digital Circuits, Electronics Lab
(12, 19), (12, 21), -- Murphy: Marketing, Org. Behavior
(13, 20), (13, 22), -- Gonzalez: Finance, Accounting
(14, 7), (14, 19), -- Smith: Business Mgmt, Marketing
(15, 21), (15, 20); -- Owens: Org. Behavior, Finance

-- Insert Curriculum
-- Program IDs: BCA=1, B.Tech=2, BBA=3, M.Tech=4, BSc-PHY=5, MBA=6
INSERT INTO curriculum (program_id, year, subject_id) VALUES
-- Original
(1, 1, 3), (1, 1, 4), -- BCA 1: Calculus, Data Structures
(1, 2, 6), (1, 2, 8), -- BCA 2: DBMS, Advanced Algorithms
(2, 1, 5), (2, 1, 3), -- B.Tech 1: Engineering, Calculus
(2, 2, 1), (2, 2, 2), -- B.Tech 2: Physics, History
(3, 1, 7), -- BBA 1: Business Management
-- New
(1, 3, 9), (1, 3, 10), -- BCA 3: Software Eng, AI
(2, 3, 11), (2, 3, 12), -- B.Tech 3: Thermo, Digital Circuits
(3, 2, 19), (3, 2, 20), -- BBA 2: Marketing, Finance
(4, 1, 13), (4, 1, 14), -- M.Tech 1: Adv DBMS, ML
(5, 1, 15), (5, 1, 16), -- BSc-PHY 1: Mechanics, Optics Lab
(5, 2, 17), (5, 2, 18), -- BSc-PHY 2: Quantum, Electronics Lab
(6, 1, 21), (6, 1, 22); -- MBA 1: Org. Behavior, Accounting

-- Insert Master Timeslots
INSERT INTO timeslots (day_of_week, start_time, end_time) VALUES
('Monday', '09:00:00', '10:00:00'),
('Monday', '10:00:00', '11:00:00'),
('Monday', '11:00:00', '12:00:00'),
('Monday', '13:00:00', '14:00:00'),
('Monday', '14:00:00', '15:00:00'), -- Added afternoon slot
('Tuesday', '09:00:00', '10:00:00'),
('Tuesday', '10:00:00', '11:00:00'),
('Tuesday', '11:00:00', '12:00:00'),
('Tuesday', '13:00:00', '14:00:00'),
('Tuesday', '14:00:00', '15:00:00'), -- Added afternoon slot
('Wednesday', '09:00:00', '10:00:00'),
('Wednesday', '10:00:00', '11:00:00'),
('Wednesday', '11:00:00', '12:00:00'),
('Wednesday', '13:00:00', '14:00:00'),
('Wednesday', '14:00:00', '15:00:00'), -- Added afternoon slot
('Thursday', '09:00:00', '10:00:00'),
('Thursday', '10:00:00', '11:00:00'),
('Thursday', '11:00:00', '12:00:00'),
('Thursday', '13:00:00', '14:00:00'),
('Thursday', '14:00:00', '15:00:00'), -- Added afternoon slot
('Friday', '09:00:00', '10:00:00'),
('Friday', '10:00:00', '11:00:00'),
('Friday', '11:00:00', '12:00:00'),
('Friday', '13:00:00', '14:00:00'),
('Friday', '14:00:00', '15:00:00'); -- Added afternoon slot

-- Insert Subject Assignments (32 assignments total)
-- Original 10
INSERT INTO subject_assignments (subject_id, teacher_id, section_id, hours_per_week) VALUES
(3, 1, 1, 2), -- Einstein teaches Calculus to BCA 1A (sec 1)
(4, 3, 1, 3), -- Turing teaches Data Structures to BCA 1A (sec 1)
(3, 1, 2, 2), -- Einstein teaches Calculus to BCA 1B (sec 2)
(4, 3, 2, 3), -- Turing teaches Data Structures to BCA 1B (sec 2)
(6, 5, 3, 3), -- Khan teaches DBMS to BCA 2A (sec 3)
(8, 3, 3, 2), -- Turing teaches Adv. Algorithms to BCA 2A (sec 3)
(5, 4, 4, 3), -- Sharma teaches Engineering to B.Tech 1A (sec 4)
(1, 1, 5, 3), -- Einstein teaches Physics to B.Tech 2A (sec 5)
(2, 2, 5, 2), -- Curie teaches History to B.Tech 2A (sec 5)
(7, 5, 6, 3), -- Khan teaches Business to BBA 1A (sec 6)
-- New 22
(6, 8, 7, 3), -- Chen teaches DBMS to BCA 2B (sec 7)
(8, 3, 7, 2), -- Turing teaches Adv. Algorithms to BCA 2B (sec 7)
(9, 6, 8, 3), -- Davis teaches Software Eng to BCA 3A (sec 8)
(10, 3, 8, 2), -- Turing teaches AI Concepts to BCA 3A (sec 8)
(5, 7, 9, 3), -- Lee teaches Engineering to B.Tech 1B (sec 9)
(3, 1, 9, 2), -- Einstein teaches Calculus to B.Tech 1B (sec 9)
(1, 4, 10, 3), -- Sharma teaches Physics to B.Tech 2B (sec 10)
(2, 2, 10, 2), -- Curie teaches History to B.Tech 2B (sec 10)
(11, 7, 11, 3), -- Lee teaches Thermo to B.Tech 3A (sec 11)
(12, 6, 11, 3), -- Davis teaches Digital Circuits to B.Tech 3A (sec 11)
(7, 14, 12, 3), -- Smith teaches Business to BBA 1B (sec 12)
(19, 12, 13, 3), -- Murphy teaches Marketing to BBA 2A (sec 13)
(20, 13, 13, 3), -- Gonzalez teaches Finance to BBA 2A (sec 13)
(13, 8, 14, 3), -- Chen teaches Adv DBMS to M.Tech 1A (sec 14)
(14, 3, 14, 3), -- Turing teaches ML to M.Tech 1A (sec 14)
(15, 9, 15, 3), -- Patel teaches Mechanics to BSc-PHY 1A (sec 15)
(16, 9, 15, 2), -- Patel teaches Optics Lab to BSc-PHY 1A (sec 15)
(17, 10, 16, 3), -- Bose teaches Quantum to BSc-PHY 2A (sec 16)
(18, 11, 16, 2), -- Singh teaches Electronics Lab to BSc-PHY 2A (sec 16)
(21, 15, 17, 3), -- Owens teaches Org. Behavior to MBA 1A (sec 17)
(22, 13, 17, 2), -- Gonzalez teaches Accounting to MBA 1A (sec 17)
(21, 12, 18, 3), -- Murphy teaches Org. Behavior to MBA 1B (sec 18)
(22, 13, 18, 2); -- Gonzalez teaches Accounting to MBA 1B (sec 18)


-- 4. FINAL CHECK
SELECT 'Database successfully reset and populated with LARGE dataset.' AS status;
