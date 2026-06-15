-- Create and use the database
CREATE DATABASE IF NOT EXISTS timetable_db;
USE timetable_db;

-- 1. DROP ALL TABLES SAFELY
-- We temporarily disable foreign key checks to delete all tables without errors
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS generated_timetable;
DROP TABLE IF EXISTS timetable_slots;
DROP TABLE IF EXISTS subject_assignments;
DROP TABLE IF EXISTS timeslots;
DROP TABLE IF EXISTS subjects;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS teacher_availability;
DROP TABLE IF EXISTS teachers;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS sections;
DROP TABLE IF EXISTS programs;
DROP TABLE IF EXISTS users;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- 2. CREATE ALL TABLES
-- (Parents first, then children)

-- Users table (with plain text password)
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    `password` VARCHAR(100) NOT NULL,
    role ENUM('student', 'teacher', 'coordinator', 'admin') NOT NULL
);

-- Programs table
CREATE TABLE programs (
    program_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Sections table
CREATE TABLE sections (
    section_id INT AUTO_INCREMENT PRIMARY KEY,
    section_name VARCHAR(100) NOT NULL,
    program_id INT,
    year INT NOT NULL,
    size INT NOT NULL,
    FOREIGN KEY (program_id) REFERENCES programs(program_id)
);

-- Students table
CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    section_id INT,
    name VARCHAR(100) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (section_id) REFERENCES sections(section_id) ON DELETE SET NULL
);

-- Teachers table
CREATE TABLE teachers (
    teacher_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Teacher Availability table
CREATE TABLE teacher_availability (
    avail_id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
    start_time TIME,
    end_time TIME,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE
);

-- Rooms table
CREATE TABLE rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    capacity INT NOT NULL,
    type ENUM('LECTURE', 'LAB') NOT NULL
);

-- Subjects table
CREATE TABLE subjects (
    subject_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    requires_room_type ENUM('LECTURE', 'LAB') DEFAULT NULL
);

-- Session Types table
CREATE TABLE session_types (
    session_type_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(200),
    color VARCHAR(7) DEFAULT '#007bff' -- Hex color code
);

-- Master Timeslots table
CREATE TABLE timeslots (
    timeslot_id INT AUTO_INCREMENT PRIMARY KEY,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    session_type_id INT DEFAULT NULL,
    FOREIGN KEY (session_type_id) REFERENCES session_types(session_type_id) ON DELETE SET NULL,
    UNIQUE(day_of_week, start_time)
);

-- Subject Assignments table
CREATE TABLE subject_assignments (
    assign_id INT AUTO_INCREMENT PRIMARY KEY,
    subject_id INT,
    teacher_id INT,
    section_id INT,
    hours_per_week INT NOT NULL,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id),
    FOREIGN KEY (section_id) REFERENCES sections(section_id)
);

-- Teacher Qualifications table
CREATE TABLE teacher_qualifications (
    qual_id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT,
    subject_id INT,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE,
    UNIQUE(teacher_id, subject_id)
);

-- Curriculum table
CREATE TABLE curriculum (
    curr_id INT AUTO_INCREMENT PRIMARY KEY,
    program_id INT,
    year INT NOT NULL,
    subject_id INT,
    FOREIGN KEY (program_id) REFERENCES programs(program_id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE,
    UNIQUE(program_id, year, subject_id)
);

-- Timetable Slots table (Your primary output table)
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
    FOREIGN KEY (room_id) REFERENCES rooms(room_id)
);

-- Generated Timetable table (Your redundant output table)
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
    FOREIGN KEY (section_id) REFERENCES sections(section_id)
);
