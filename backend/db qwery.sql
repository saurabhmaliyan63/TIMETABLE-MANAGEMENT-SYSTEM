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

-- 3. INSERT TEST DATA

-- Insert Users
INSERT INTO users (username, `password`, role) VALUES
('admin', 'admin_pass123', 'admin'),
('coordinator', 'coord_pass123', 'coordinator'),
('prof_einstein', 'teacher_pass1', 'teacher'),
('prof_curie', 'teacher_pass2', 'teacher'),
('prof_turing', 'teacher_pass3', 'teacher'),
('prof_sharma', 'teacher_pass4', 'teacher'),
('prof_khan', 'teacher_pass5', 'teacher'),
('student_alice', 'student_pass1', 'student'),
('student_bob', 'student_pass2', 'student'),
('student_charlie', 'student_pass3', 'student'),
('student_dave', 'student_pass4', 'student'),
('student_eve', 'student_pass5', 'student'),
('student_frank', 'student_pass6', 'student'),
('student_grace', 'student_pass7', 'student'),
('student_heidi', 'student_pass8', 'student');

-- Insert Programs
INSERT INTO programs (name, short_code, department, duration_years) VALUES
('Bachelor of Computer Applications', 'BCA', 'School of Computing', 3),
('Bachelor of Technology', 'B.Tech', 'School of Engineering', 4),
('Bachelor of Business Administration', 'BBA', 'School of Management', 3),
('Master of Technology', 'M.Tech', 'School of Engineering', 2);

-- Insert Sections
INSERT INTO sections (program_id, year, section_name, size) VALUES
(1, 1, 'A', 45), -- BCA 1A
(1, 1, 'B', 50), -- BCA 1B
(1, 2, 'A', 40), -- BCA 2A
(2, 1, 'A', 60), -- B.Tech 1A
(2, 2, 'A', 55), -- B.Tech 2A
(3, 1, 'A', 70); -- BBA 1A

-- Insert Students (FIXED: Correct user_ids)
-- user_ids: alice=8, bob=9, charlie=10, dave=11, eve=12, frank=13, grace=14, heidi=15
INSERT INTO students (user_id, section_id, name) VALUES
(8, 1, 'Alice Smith'),    -- FIXED: was 6, now 8
(9, 1, 'Bob Johnson'),    -- FIXED: was 7, now 9
(10, 2, 'Charlie Brown'),
(11, 2, 'Dave Davis'),
(12, 3, 'Eve Williams'),
(13, 4, 'Frank Miller'),
(14, 5, 'Grace Lee'),     -- FIXED: was 12, now 14
(15, 6, 'Heidi Wilson'); -- FIXED: was 13, now 15

-- Insert Teachers
INSERT INTO teachers (user_id, name, email) VALUES
(3, 'Albert Einstein', 'einstein@uni.com'),
(4, 'Marie Curie', 'curie@uni.com'),
(5, 'Alan Turing', 'turing@uni.com'),
(6, 'Rohan Sharma', 'sharma@uni.com'),
(7, 'Ayesha Khan', 'khan@uni.com');

-- Insert Teacher Availability
INSERT INTO teacher_availability (teacher_id, day_of_week, start_time, end_time) VALUES
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
(5, 'Wednesday', '09:00:00', '17:00:00');

-- Insert Rooms
INSERT INTO rooms (name, capacity, type) VALUES
('Main Hall (A-101)', 65, 'LECTURE'),
('West Wing (W-202)', 45, 'LECTURE'),
('Computer Lab (CS-01)', 50, 'LAB'),
('Auditorium', 150, 'AUDITORIUM'),
('Seminar Hall (S-101)', 75, 'SEMINAR'),
('Computer Lab (CS-02)', 50, 'LAB');

-- Insert Subjects
INSERT INTO subjects (name, requires_room_type) VALUES
('Physics 101', NULL),
('History of Science', NULL),
('Calculus I', NULL),
('Data Structures', 'LAB'),
('Intro to Engineering', 'LECTURE'),
('Database Systems', 'LAB'),
('Business Management 101', 'SEMINAR'),
('Advanced Algorithms', 'SEMINAR');

-- Insert Teacher Qualifications
INSERT INTO teacher_qualifications (teacher_id, subject_id) VALUES
(1, 1), (1, 3), -- Einstein: Physics, Calculus
(2, 2), -- Curie: History
(3, 4), (3, 8), -- Turing: Data Structures, Advanced Algorithms
(4, 5), (4, 1), -- Sharma: Engineering, Physics
(5, 6), (5, 7); -- Khan: DBMS, Business

-- Insert Curriculum
INSERT INTO curriculum (program_id, year, subject_id) VALUES
(1, 1, 3), (1, 1, 4), -- BCA 1: Calculus, Data Structures
(1, 2, 6), (1, 2, 8), -- BCA 2: DBMS, Advanced Algorithms
(2, 1, 5), (2, 1, 3), -- B.Tech 1: Engineering, Calculus
(2, 2, 1), (2, 2, 2), -- B.Tech 2: Physics, History
(3, 1, 7); -- BBA 1: Business Management

-- Insert Master Timeslots (FIXED: typo corrected)
INSERT INTO timeslots (day_of_week, start_time, end_time) VALUES
('Monday', '09:00:00', '10:00:00'),
('Monday', '10:00:00', '11:00:00'),
('Monday', '11:00:00', '12:00:00'),
('Monday', '13:00:00', '14:00:00'),
('Tuesday', '09:00:00', '10:00:00'),
('Tuesday', '10:00:00', '11:00:00'),
('Tuesday', '11:00:00', '12:00:00'),
('Tuesday', '13:00:00', '14:00:00'),
('Wednesday', '09:00:00', '10:00:00'),
('Wednesday', '10:00:00', '11:00:00'),
('Wednesday', '11:00:00', '12:00:00'),
('Wednesday', '13:00:00', '14:00:00'),
('Thursday', '09:00:00', '10:00:00'),
('Thursday', '10:00:00', '11:00:00'),
('Thursday', '11:00:00', '12:00:00'),
('Thursday', '13:00:00', '14:00:00'),
('Friday', '09:00:00', '10:00:00'),
('Friday', '10:00:00', '11:00:00'), -- FIXED: was '11:0Am 00'
('Friday', '11:00:00', '12:00:00'),
('Friday', '13:00:00', '14:00:00');

-- Insert Subject Assignments
INSERT INTO subject_assignments (subject_id, teacher_id, section_id, hours_per_week) VALUES
(3, 1, 1, 2), -- Einstein teaches Calculus to BCA 1A (2 hours)
(4, 3, 1, 3), -- Turing teaches Data Structures to BCA 1A (3 hours)
(3, 1, 2, 2), -- Einstein teaches Calculus to BCA 1B (2 hours)
(4, 3, 2, 3), -- Turing teaches Data Structures to BCA 1B (3 hours)
(6, 5, 3, 3), -- Khan teaches DBMS to BCA 2A (3 hours)
(8, 3, 3, 2), -- Turing teaches Adv. Algorithms to BCA 2A (2 hours)
(5, 4, 4, 3), -- Sharma teaches Engineering to B.Tech 1A (3 hours)
(1, 1, 5, 3), -- Einstein teaches Physics to B.Tech 2A (3 hours)
(2, 2, 5, 2), -- Curie teaches History to B.Tech 2A (2 hours)
(7, 5, 6, 3); -- Khan teaches Business to BBA 1A (3 hours)

-- 4. FINAL CHECK
SELECT 'Database successfully reset and populated with FIXED dataset.' AS status;
