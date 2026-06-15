-- Use the database
USE timetable_db;

-- 1. Clear all existing data in the correct order
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE timetable_slots;
TRUNCATE TABLE subject_assignments;
TRUNCATE TABLE timeslots;
TRUNCATE TABLE subjects;
TRUNCATE TABLE rooms;
TRUNCATE TABLE teacher_availability;
TRUNCATE TABLE teachers;
TRUNCATE TABLE students;
TRUNCATE TABLE sections;
TRUNCATE TABLE programs;
TRUNCATE TABLE users;
SET FOREIGN_KEY_CHECKS = 1;

-- 2. Insert Users (MODIFIED for plain text)
-- The 'password_hash' column is renamed to 'password'
DROP TABLE IF EXISTS users; -- Drop old table first
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    `password` VARCHAR(100) NOT NULL, -- <-- CHANGED
    role ENUM('student', 'teacher', 'coordinator', 'admin') NOT NULL
);

-- Insert users with plain-text passwords
INSERT INTO users (username, `password`, role) VALUES
('admin', 'admin_pass123', 'admin'),
('coordinator', 'coord_pass123', 'coordinator'),
('prof_einstein', 'teacher_pass1', 'teacher'),
('prof_curie', 'teacher_pass2', 'teacher'),
('prof_turing', 'teacher_pass3', 'teacher'),
('student_alice', 'student_pass1', 'student'),
('student_bob', 'student_pass2', 'student'),
('student_charlie', 'student_pass3', 'student'),
('student_dave', 'student_pass4', 'student');

-- 3. Insert Programs
INSERT INTO programs (name, short_code, department) VALUES
('Bachelor of Computer Applications', 'BCA', 'School of Computing'),
('Bachelor of Technology', 'B.Tech', 'School of Engineering');

-- 4. Insert Sections
-- (program