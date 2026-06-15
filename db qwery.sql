-- ============================================================================
-- UPDATED TIMETABLE DATABASE SCHEMA
-- Comprehensive schema with all features and improvements
-- ============================================================================

-- Create and use the database
CREATE DATABASE IF NOT EXISTS timetable_db;
USE timetable_db;

-- ============================================================================
-- 1. DROP ALL TABLES SAFELY (in correct order to respect foreign keys)
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS timetable_version_slots;
DROP TABLE IF EXISTS timetable_quality_metrics;
DROP TABLE IF EXISTS timetable_comments;
DROP TABLE IF EXISTS change_requests;
DROP TABLE IF EXISTS conflicts;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS export_history;
DROP TABLE IF EXISTS statistics_cache;
DROP TABLE IF EXISTS timetable_templates;
DROP TABLE IF EXISTS timetable_versions;
DROP TABLE IF EXISTS room_preferences;
DROP TABLE IF EXISTS scheduling_constraints;
DROP TABLE IF EXISTS teacher_preferences;
DROP TABLE IF EXISTS generated_timetable;
DROP TABLE IF EXISTS timetable_slots;
DROP TABLE IF EXISTS subject_assignments;
DROP TABLE IF EXISTS curriculum;
DROP TABLE IF EXISTS teacher_qualifications;
DROP TABLE IF EXISTS timeslots;
DROP TABLE IF EXISTS session_types;
DROP TABLE IF EXISTS subjects;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS teacher_availability;
DROP TABLE IF EXISTS teachers;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS sections;
DROP TABLE IF EXISTS programs;
DROP TABLE IF EXISTS semesters;
DROP TABLE IF EXISTS academic_years;
DROP TABLE IF EXISTS users;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- 2. CREATE ALL TABLES (with comprehensive improvements)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Users table (Enhanced)
-- ----------------------------------------------------------------------------
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    `password` VARCHAR(255) NOT NULL, -- Increased for hashed passwords
    email VARCHAR(100) UNIQUE,
    role ENUM('student', 'teacher', 'coordinator', 'admin') NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    notification_preferences JSON DEFAULT ('{"email": true, "in_app": true}'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_active (is_active)
);

-- ----------------------------------------------------------------------------
-- Programs table
-- ----------------------------------------------------------------------------
CREATE TABLE programs (
    program_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    short_code VARCHAR(10) UNIQUE,
    department VARCHAR(100),
    duration_years INT CHECK (duration_years > 0),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_short_code (short_code),
    INDEX idx_active (is_active)
);

-- ----------------------------------------------------------------------------
-- Academic Years table
-- ----------------------------------------------------------------------------
CREATE TABLE academic_years (
    year_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (end_date > start_date),
    INDEX idx_active (is_active)
);

-- ----------------------------------------------------------------------------
-- Semesters table
-- ----------------------------------------------------------------------------
CREATE TABLE semesters (
    semester_id INT AUTO_INCREMENT PRIMARY KEY,
    year_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (year_id) REFERENCES academic_years(year_id) ON DELETE CASCADE,
    CHECK (end_date > start_date),
    INDEX idx_active (is_active),
    INDEX idx_year_id (year_id)
);

-- ----------------------------------------------------------------------------
-- Sections table (Enhanced)
-- ----------------------------------------------------------------------------
CREATE TABLE sections (
    section_id INT AUTO_INCREMENT PRIMARY KEY,
    section_name VARCHAR(100) NOT NULL,
    program_id INT,
    year INT NOT NULL CHECK (year > 0),
    size INT NOT NULL CHECK (size > 0),
    semester_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (program_id) REFERENCES programs(program_id) ON DELETE SET NULL,
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id) ON DELETE SET NULL,
    UNIQUE(program_id, year, section_name, semester_id),
    INDEX idx_program_id (program_id),
    INDEX idx_semester_id (semester_id),
    INDEX idx_active (is_active)
);

-- ----------------------------------------------------------------------------
-- Students table (Enhanced)
-- ----------------------------------------------------------------------------
CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    section_id INT,
    name VARCHAR(100) NOT NULL,
    student_code VARCHAR(50) UNIQUE,
    enrollment_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (section_id) REFERENCES sections(section_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_section_id (section_id),
    INDEX idx_student_code (student_code),
    INDEX idx_active (is_active)
);

-- ----------------------------------------------------------------------------
-- Teachers table (Enhanced)
-- ----------------------------------------------------------------------------
CREATE TABLE teachers (
    teacher_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    employee_id VARCHAR(50) UNIQUE,
    department VARCHAR(100),
    designation VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_email (email),
    INDEX idx_employee_id (employee_id),
    INDEX idx_active (is_active)
);

-- ----------------------------------------------------------------------------
-- Teacher Availability table (Enhanced)
-- ----------------------------------------------------------------------------
CREATE TABLE teacher_availability (
    avail_id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_preferred BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    UNIQUE(teacher_id, day_of_week, start_time, end_time),
    CHECK (end_time > start_time),
    INDEX idx_teacher_id (teacher_id),
    INDEX idx_day (day_of_week)
);

-- ----------------------------------------------------------------------------
-- Teacher Preferences table
-- ----------------------------------------------------------------------------
CREATE TABLE teacher_preferences (
    pref_id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
    start_time TIME,
    end_time TIME,
    preference_type ENUM('PREFERRED', 'AVOID', 'BLOCKED') NOT NULL DEFAULT 'PREFERRED',
    weight INT DEFAULT 1 CHECK (weight >= 1 AND weight <= 10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    INDEX idx_teacher_pref (teacher_id, day_of_week),
    INDEX idx_preference_type (preference_type)
);

-- ----------------------------------------------------------------------------
-- Rooms table (Enhanced)
-- ----------------------------------------------------------------------------
CREATE TABLE rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    type ENUM('LECTURE', 'LAB', 'SEMINAR', 'AUDITORIUM') NOT NULL,
    building VARCHAR(100),
    floor INT,
    location_description TEXT,
    equipment JSON, -- Store equipment list as JSON
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (type),
    INDEX idx_building (building),
    INDEX idx_active (is_active)
);

-- ----------------------------------------------------------------------------
-- Subjects table (Enhanced)
-- ----------------------------------------------------------------------------
CREATE TABLE subjects (
    subject_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE,
    requires_room_type ENUM('LECTURE', 'LAB', 'SEMINAR') DEFAULT NULL,
    credits INT DEFAULT 0 CHECK (credits >= 0),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_code (code),
    INDEX idx_room_type (requires_room_type),
    INDEX idx_active (is_active)
);

-- ----------------------------------------------------------------------------
-- Room Preferences table
-- ----------------------------------------------------------------------------
CREATE TABLE room_preferences (
    pref_id INT AUTO_INCREMENT PRIMARY KEY,
    subject_id INT,
    room_id INT,
    preference_type ENUM('PREFERRED', 'AVOID') DEFAULT 'PREFERRED',
    weight INT DEFAULT 1 CHECK (weight >= 1 AND weight <= 10),
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE,
    FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE CASCADE,
    UNIQUE(subject_id, room_id),
    INDEX idx_subject_id (subject_id),
    INDEX idx_room_id (room_id)
);

-- ----------------------------------------------------------------------------
-- Session Types table
-- ----------------------------------------------------------------------------
CREATE TABLE session_types (
    session_type_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(200),
    color VARCHAR(7) DEFAULT '#007bff', -- Hex color code
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_active (is_active)
);

-- ----------------------------------------------------------------------------
-- Teacher Qualifications table
-- ----------------------------------------------------------------------------
CREATE TABLE teacher_qualifications (
    qualification_id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    subject_id INT NOT NULL,
    proficiency_level ENUM('BASIC', 'INTERMEDIATE', 'ADVANCED', 'EXPERT') DEFAULT 'INTERMEDIATE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE,
    UNIQUE(teacher_id, subject_id),
    INDEX idx_teacher_id (teacher_id),
    INDEX idx_subject_id (subject_id)
);

-- ----------------------------------------------------------------------------
-- Curriculum table (Enhanced)
-- ----------------------------------------------------------------------------
CREATE TABLE curriculum (
    curriculum_id INT AUTO_INCREMENT PRIMARY KEY,
    program_id INT NOT NULL,
    year INT NOT NULL CHECK (year > 0),
    subject_id INT NOT NULL,
    is_core BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (program_id) REFERENCES programs(program_id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE,
    UNIQUE(program_id, year, subject_id),
    INDEX idx_program_year (program_id, year),
    INDEX idx_subject_id (subject_id)
);

-- ----------------------------------------------------------------------------
-- Master Timeslots table (Enhanced)
-- ----------------------------------------------------------------------------
CREATE TABLE timeslots (
    timeslot_id INT AUTO_INCREMENT PRIMARY KEY,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    session_type_id INT DEFAULT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_type_id) REFERENCES session_types(session_type_id) ON DELETE SET NULL,
    UNIQUE(day_of_week, start_time),
    CHECK (end_time > start_time),
    INDEX idx_day_time (day_of_week, start_time),
    INDEX idx_session_type (session_type_id),
    INDEX idx_active (is_active)
);

-- ----------------------------------------------------------------------------
-- Subject Assignments table (Enhanced)
-- ----------------------------------------------------------------------------
CREATE TABLE subject_assignments (
    assign_id INT AUTO_INCREMENT PRIMARY KEY,
    subject_id INT NOT NULL,
    teacher_id INT NOT NULL,
    section_id INT NOT NULL,
    hours_per_week INT NOT NULL CHECK (hours_per_week > 0),
    semester_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES sections(section_id) ON DELETE CASCADE,
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id) ON DELETE SET NULL,
    INDEX idx_teacher_id (teacher_id),
    INDEX idx_section_id (section_id),
    INDEX idx_subject_id (subject_id),
    INDEX idx_semester_id (semester_id)
);

-- ----------------------------------------------------------------------------
-- Scheduling Constraints table
-- ----------------------------------------------------------------------------
CREATE TABLE scheduling_constraints (
    constraint_id INT AUTO_INCREMENT PRIMARY KEY,
    constraint_type ENUM('NO_CONSECUTIVE_LABS', 'MAX_DAILY_HOURS', 'MIN_BREAK_TIME', 'PREFERRED_TIME_SLOT', 'NO_BACK_TO_BACK') NOT NULL,
    entity_type ENUM('TEACHER', 'SECTION', 'SUBJECT', 'GLOBAL') NOT NULL,
    entity_id INT, -- ID of teacher/section/subject, NULL for global
    constraint_value VARCHAR(500), -- JSON or value
    is_hard_constraint BOOLEAN DEFAULT TRUE,
    weight INT DEFAULT 10 CHECK (weight >= 1 AND weight <= 10), -- Only for soft constraints
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (constraint_type, entity_type),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_active (is_active)
);

-- ----------------------------------------------------------------------------
-- Timetable Slots table (Enhanced)
-- ----------------------------------------------------------------------------
CREATE TABLE timetable_slots (
    slot_id INT AUTO_INCREMENT PRIMARY KEY,
    timeslot_id INT NOT NULL,
    subject_id INT NOT NULL,
    teacher_id INT NOT NULL,
    section_id INT NOT NULL,
    room_id INT NOT NULL,
    semester_id INT,
    notes TEXT,
    color VARCHAR(7) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    updated_by INT,
    FOREIGN KEY (timeslot_id) REFERENCES timeslots(timeslot_id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES sections(section_id) ON DELETE CASCADE,
    FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE CASCADE,
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(user_id) ON DELETE SET NULL,
    -- Prevent duplicate assignments
    UNIQUE(timeslot_id, teacher_id, section_id),
    UNIQUE(timeslot_id, room_id, section_id),
    INDEX idx_timeslot_id (timeslot_id),
    INDEX idx_teacher_id (teacher_id),
    INDEX idx_room_id (room_id),
    INDEX idx_section_id (section_id),
    INDEX idx_semester_id (semester_id)
);

-- ----------------------------------------------------------------------------
-- Generated Timetable table (Legacy - kept for compatibility)
-- ----------------------------------------------------------------------------
CREATE TABLE generated_timetable (
    id INT AUTO_INCREMENT PRIMARY KEY,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    timeslot_id INT,
    room_id INT,
    teacher_id INT,
    subject_id INT,
    section_id INT,
    semester_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (timeslot_id) REFERENCES timeslots(timeslot_id) ON DELETE CASCADE,
    FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES sections(section_id) ON DELETE CASCADE,
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id) ON DELETE SET NULL,
    INDEX idx_timeslot_id (timeslot_id),
    INDEX idx_teacher_id (teacher_id),
    INDEX idx_room_id (room_id),
    INDEX idx_section_id (section_id),
    INDEX idx_day (day_of_week),
    INDEX idx_semester_id (semester_id)
);

-- ----------------------------------------------------------------------------
-- Timetable Versions table
-- ----------------------------------------------------------------------------
CREATE TABLE timetable_versions (
    version_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    semester_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INT,
    quality_score DECIMAL(5,2),
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_active (is_active),
    INDEX idx_semester_id (semester_id),
    INDEX idx_created_by (created_by)
);

-- ----------------------------------------------------------------------------
-- Timetable Version Slots table
-- ----------------------------------------------------------------------------
CREATE TABLE timetable_version_slots (
    version_slot_id INT AUTO_INCREMENT PRIMARY KEY,
    version_id INT NOT NULL,
    slot_id INT, -- Reference to timetable_slots
    timeslot_id INT NOT NULL,
    subject_id INT NOT NULL,
    teacher_id INT NOT NULL,
    section_id INT NOT NULL,
    room_id INT NOT NULL,
    FOREIGN KEY (version_id) REFERENCES timetable_versions(version_id) ON DELETE CASCADE,
    FOREIGN KEY (timeslot_id) REFERENCES timeslots(timeslot_id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES sections(section_id) ON DELETE CASCADE,
    FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE CASCADE,
    INDEX idx_version (version_id),
    INDEX idx_timeslot_id (timeslot_id),
    INDEX idx_teacher_id (teacher_id),
    INDEX idx_section_id (section_id)
);

-- ----------------------------------------------------------------------------
-- Conflicts table
-- ----------------------------------------------------------------------------
CREATE TABLE conflicts (
    conflict_id INT AUTO_INCREMENT PRIMARY KEY,
    conflict_type ENUM('TEACHER', 'ROOM', 'SECTION', 'CAPACITY', 'AVAILABILITY', 'PREFERENCE', 'CONSTRAINT') NOT NULL,
    severity ENUM('ERROR', 'WARNING', 'INFO') DEFAULT 'WARNING',
    slot_id INT,
    version_id INT,
    description TEXT,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP NULL,
    resolved_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (slot_id) REFERENCES timetable_slots(slot_id) ON DELETE CASCADE,
    FOREIGN KEY (version_id) REFERENCES timetable_versions(version_id) ON DELETE CASCADE,
    FOREIGN KEY (resolved_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_resolved (resolved),
    INDEX idx_type (conflict_type),
    INDEX idx_severity (severity),
    INDEX idx_slot_id (slot_id),
    INDEX idx_version_id (version_id)
);

-- ----------------------------------------------------------------------------
-- Timetable Comments/Notes table
-- ----------------------------------------------------------------------------
CREATE TABLE timetable_comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    slot_id INT,
    user_id INT NOT NULL,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (slot_id) REFERENCES timetable_slots(slot_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_slot (slot_id),
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at)
);

-- ----------------------------------------------------------------------------
-- Change Requests table
-- ----------------------------------------------------------------------------
CREATE TABLE change_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    requested_by INT NOT NULL,
    slot_id INT,
    requested_timeslot_id INT,
    requested_room_id INT,
    reason TEXT,
    status ENUM('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED') DEFAULT 'PENDING',
    reviewed_by INT,
    reviewed_at TIMESTAMP NULL,
    review_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (requested_by) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (slot_id) REFERENCES timetable_slots(slot_id) ON DELETE CASCADE,
    FOREIGN KEY (requested_timeslot_id) REFERENCES timeslots(timeslot_id) ON DELETE SET NULL,
    FOREIGN KEY (requested_room_id) REFERENCES rooms(room_id) ON DELETE SET NULL,
    FOREIGN KEY (reviewed_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_status (status),
    INDEX idx_requested_by (requested_by),
    INDEX idx_created_at (created_at)
);

-- ----------------------------------------------------------------------------
-- Templates/Patterns table
-- ----------------------------------------------------------------------------
CREATE TABLE timetable_templates (
    template_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    template_data JSON,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_active (is_active),
    INDEX idx_created_by (created_by)
);

-- ----------------------------------------------------------------------------
-- Notifications table
-- ----------------------------------------------------------------------------
CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    type ENUM('CONFLICT', 'CHANGE', 'APPROVAL', 'REMINDER', 'SYSTEM', 'UPDATE') NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT,
    `read` BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    link_url VARCHAR(500),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_read (user_id, `read`),
    INDEX idx_created (created_at),
    INDEX idx_type (type)
);

-- ----------------------------------------------------------------------------
-- Quality Metrics table
-- ----------------------------------------------------------------------------
CREATE TABLE timetable_quality_metrics (
    metric_id INT AUTO_INCREMENT PRIMARY KEY,
    version_id INT,
    metric_type VARCHAR(50) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(10,2),
    target_value DECIMAL(10,2),
    status ENUM('PASS', 'WARNING', 'FAIL') DEFAULT 'PASS',
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (version_id) REFERENCES timetable_versions(version_id) ON DELETE CASCADE,
    INDEX idx_version (version_id),
    INDEX idx_status (status),
    INDEX idx_metric_type (metric_type)
);

-- ----------------------------------------------------------------------------
-- Export History table
-- ----------------------------------------------------------------------------
CREATE TABLE export_history (
    export_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    export_type ENUM('PDF', 'EXCEL', 'CSV', 'ICAL', 'JSON') NOT NULL,
    export_scope ENUM('FULL', 'TEACHER', 'SECTION', 'ROOM', 'CUSTOM') NOT NULL,
    scope_id INT,
    file_path VARCHAR(500),
    file_size BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_export_type (export_type),
    INDEX idx_created_at (created_at)
);

-- ----------------------------------------------------------------------------
-- Statistics Cache table
-- ----------------------------------------------------------------------------
CREATE TABLE statistics_cache (
    stat_id INT AUTO_INCREMENT PRIMARY KEY,
    stat_type VARCHAR(50) NOT NULL,
    stat_key VARCHAR(100) NOT NULL,
    stat_value JSON,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    UNIQUE KEY unique_stat (stat_type, stat_key),
    INDEX idx_expires (expires_at),
    INDEX idx_stat_type (stat_type)
);

-- ============================================================================
-- 3. INSERT TEST DATA
-- ============================================================================

-- Insert Users (with placeholder hashed passwords - replace in production)
INSERT INTO users (username, `password`, email, role, first_name, last_name) VALUES
('admin', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'admin@uni.com', 'admin', 'Admin', 'User'),
('coordinator', '$2b$12$Vh3oasRtTFrnff6q93RN8uEWae0py7e4sIi8Lio12kA/RPDNHWiTa', 'coordinator@uni.com', 'coordinator', 'Coordinator', 'User'),
('prof_einstein', '$2b$12$ZOr5fIVHpO9YyE.nRZjHfOpus9cgiKacPE4Kn8w4r43LU2n2w6/AC', 'einstein@uni.com', 'teacher', 'Albert', 'Einstein'),
('prof_curie', '$2b$12$7JrvV75fTuxaObvio62VB.VzKKnmxvfY.Zua.piEYEgIEidyihBiO', 'curie@uni.com', 'teacher', 'Marie', 'Curie'),
('prof_turing', '$2b$12$r1Nx3k.LYFyCK4Bc6.rhD.xNfw6hT48T8ExrccExVtysAbklpjReO', 'turing@uni.com', 'teacher', 'Alan', 'Turing'),
('prof_sharma', '$2b$12$8vmnb.1bqerY3krxVwx5NeGbA9FSa1J25ePYnf.nk0szxrvb.xZIy', 'sharma@uni.com', 'teacher', 'Rohan', 'Sharma'),
('prof_khan', '$2b$12$QNy2uCAEWfU0z0iQQ19e.ORp9dX211cHjXHoCE0xWL.mM7iRK0Vgy', 'khan@uni.com', 'teacher', 'Ayesha', 'Khan'),
('student_alice', '$2b$12$H9GMjuA4pLIv4rjXtfSczOTs0A6zzuxdEfy6qhDiaoMH6Rm0IH4/u', 'alice@uni.com', 'student', 'Alice', 'Smith'),
('student_bob', '$2b$12$qBhlfKNEO8o5eCgJlqGxp.AcCoFvdBrn7dhjIU3iD37pqdsWCkKp.', 'bob@uni.com', 'student', 'Bob', 'Johnson'),
('student_charlie', '$2b$12$ZW9gN9GAWyvPN.u0c7tIve/uh78Rg.8ME0/8G4HQN5k0gCrYKKNCC', 'charlie@uni.com', 'student', 'Charlie', 'Brown'),
('student_dave', '$2b$12$MtBuy8RRbe6u16OOqggE.epO/tfpxZdwCampHYXQCJpmsbRUJbyJ.', 'dave@uni.com', 'student', 'Dave', 'Davis'),
('student_eve', '$2b$12$B87kgZO6F8YIcp6Qma1jeubeS7YekCjf2sYWAQR2zr3Jj0P/eNlku', 'eve@uni.com', 'student', 'Eve', 'Williams'),
('student_frank', '$2b$12$GwnStnaZPlBEtOK4G/r85u81AhKPOInQMKzmZ0bhAOq7ehtqcEfVG', 'frank@uni.com', 'student', 'Frank', 'Miller'),
('student_grace', '$2b$12$xjE/ZFCs23/p6Tb/xRDzLutC7eRzHrd9y0by9MGxuET9d2cfgDGAO', 'grace@uni.com', 'student', 'Grace', 'Lee'),
('student_heidi', '$2b$12$E4Ge84fExpuicQwVvTxFyenVVBj8.Nlm9vwqyyFXFoydyvhOXnh4O', 'heidi@uni.com', 'student', 'Heidi', 'Wilson');

-- Insert Programs
INSERT INTO programs (name, short_code, department, duration_years) VALUES
('Bachelor of Computer Applications', 'BCA', 'School of Computing', 3),
('Bachelor of Technology', 'B.Tech', 'School of Engineering', 4),
('Bachelor of Business Administration', 'BBA', 'School of Management', 3),
('Master of Technology', 'M.Tech', 'School of Engineering', 2);

-- Insert Academic Year
INSERT INTO academic_years (name, start_date, end_date, is_active) VALUES
('2024-2025', '2024-08-01', '2025-07-31', TRUE);

-- Insert Semesters
INSERT INTO semesters (year_id, name, start_date, end_date, is_active) VALUES
(1, 'Fall 2024', '2024-08-01', '2024-12-31', TRUE),
(1, 'Spring 2025', '2025-01-01', '2025-05-31', FALSE);

-- Insert Sections
INSERT INTO sections (program_id, year, section_name, size, semester_id) VALUES
(1, 1, 'A', 45, 1), -- BCA 1A
(1, 1, 'B', 50, 1), -- BCA 1B
(1, 2, 'A', 40, 1), -- BCA 2A
(2, 1, 'A', 60, 1), -- B.Tech 1A
(2, 2, 'A', 55, 1), -- B.Tech 2A
(3, 1, 'A', 70, 1); -- BBA 1A

-- Insert Students (CORRECTED user_ids)
INSERT INTO students (user_id, section_id, name, student_code) VALUES
(8, 1, 'Alice Smith', 'BCA001'),
(9, 1, 'Bob Johnson', 'BCA002'),
(10, 2, 'Charlie Brown', 'BCA003'),
(11, 2, 'Dave Davis', 'BCA004'),
(12, 3, 'Eve Williams', 'BCA005'),
(13, 4, 'Frank Miller', 'BT001'),
(14, 5, 'Grace Lee', 'BT002'),
(15, 6, 'Heidi Wilson', 'BBA001');

-- Insert Teachers
INSERT INTO teachers (user_id, name, email, employee_id, department) VALUES
(3, 'Albert Einstein', 'einstein@uni.com', 'EMP001', 'Physics'),
(4, 'Marie Curie', 'curie@uni.com', 'EMP002', 'History'),
(5, 'Alan Turing', 'turing@uni.com', 'EMP003', 'Computer Science'),
(6, 'Rohan Sharma', 'sharma@uni.com', 'EMP004', 'Engineering'),
(7, 'Ayesha Khan', 'khan@uni.com', 'EMP005', 'Business');

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
INSERT INTO rooms (name, capacity, type, building, floor) VALUES
('Main Hall (A-101)', 65, 'LECTURE', 'Building A', 1),
('West Wing (W-202)', 45, 'LECTURE', 'Building W', 2),
('Computer Lab (CS-01)', 50, 'LAB', 'Building CS', 1),
('Auditorium', 150, 'AUDITORIUM', 'Main Building', 1),
('Seminar Hall (S-101)', 75, 'SEMINAR', 'Building S', 1),
('Computer Lab (CS-02)', 50, 'LAB', 'Building CS', 1);

-- Insert Subjects
INSERT INTO subjects (name, code, requires_room_type, credits) VALUES
('Physics 101', 'PHY101', NULL, 3),
('History of Science', 'HIS201', NULL, 2),
('Calculus I', 'MATH101', NULL, 4),
('Data Structures', 'CS201', 'LAB', 3),
('Intro to Engineering', 'ENG101', 'LECTURE', 3),
('Database Systems', 'CS301', 'LAB', 3),
('Business Management 101', 'BBA101', 'SEMINAR', 3),
('Advanced Algorithms', 'CS401', 'SEMINAR', 3);

-- Insert Session Types
INSERT INTO session_types (name, description, color) VALUES
('Lecture', 'Regular lecture session', '#007bff'),
('Break', 'Break time between sessions', '#28a745'),
('Seminar', 'Seminar or workshop session', '#ffc107'),
('Lab', 'Laboratory session', '#dc3545'),
('Exam', 'Examination period', '#6f42c1');

-- Insert Teacher Qualifications
INSERT INTO teacher_qualifications (teacher_id, subject_id, proficiency_level) VALUES
(1, 1, 'EXPERT'), (1, 3, 'ADVANCED'), -- Einstein: Physics, Calculus
(2, 2, 'EXPERT'), -- Curie: History
(3, 4, 'EXPERT'), (3, 8, 'EXPERT'), -- Turing: Data Structures, Advanced Algorithms
(4, 5, 'ADVANCED'), (4, 1, 'INTERMEDIATE'), -- Sharma: Engineering, Physics
(5, 6, 'ADVANCED'), (5, 7, 'ADVANCED'); -- Khan: DBMS, Business

-- Insert Curriculum
INSERT INTO curriculum (program_id, year, subject_id, is_core) VALUES
(1, 1, 3, TRUE), (1, 1, 4, TRUE), -- BCA 1: Calculus, Data Structures
(1, 2, 6, TRUE), (1, 2, 8, TRUE), -- BCA 2: DBMS, Advanced Algorithms
(2, 1, 5, TRUE), (2, 1, 3, TRUE), -- B.Tech 1: Engineering, Calculus
(2, 2, 1, TRUE), (2, 2, 2, TRUE), -- B.Tech 2: Physics, History
(3, 1, 7, TRUE); -- BBA 1: Business Management

-- Insert Master Timeslots
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
('Friday', '10:00:00', '11:00:00'),
('Friday', '11:00:00', '12:00:00'),
('Friday', '13:00:00', '14:00:00');

-- Insert Subject Assignments
INSERT INTO subject_assignments (subject_id, teacher_id, section_id, hours_per_week, semester_id) VALUES
(3, 1, 1, 2, 1), -- Einstein teaches Calculus to BCA 1A (2 hours)
(4, 3, 1, 3, 1), -- Turing teaches Data Structures to BCA 1A (3 hours)
(3, 1, 2, 2, 1), -- Einstein teaches Calculus to BCA 1B (2 hours)
(4, 3, 2, 3, 1), -- Turing teaches Data Structures to BCA 1B (3 hours)
(6, 5, 3, 3, 1), -- Khan teaches DBMS to BCA 2A (3 hours)
(8, 3, 3, 2, 1), -- Turing teaches Adv. Algorithms to BCA 2A (2 hours)
(5, 4, 4, 3, 1), -- Sharma teaches Engineering to B.Tech 1A (3 hours)
(1, 1, 5, 3, 1), -- Einstein teaches Physics to B.Tech 2A (3 hours)
(2, 2, 5, 2, 1), -- Curie teaches History to B.Tech 2A (2 hours)
(7, 5, 6, 3, 1); -- Khan teaches Business to BBA 1A (3 hours)

-- Insert Sample Scheduling Constraints
INSERT INTO scheduling_constraints (constraint_type, entity_type, constraint_value, is_hard_constraint, description) VALUES
('MAX_DAILY_HOURS', 'TEACHER', '6', TRUE, 'Teachers should not teach more than 6 hours per day'),
('MIN_BREAK_TIME', 'GLOBAL', '30', TRUE, 'Minimum 30 minutes break between consecutive classes'),
('NO_CONSECUTIVE_LABS', 'SECTION', '2', TRUE, 'Sections should not have more than 2 consecutive lab sessions');

-- ============================================================================
-- 4. FINAL CHECK
-- ============================================================================

SELECT 'Database successfully created and populated with updated comprehensive schema.' AS status;
SELECT COUNT(*) AS total_tables FROM information_schema.tables WHERE table_schema = 'timetable_db';
SELECT COUNT(*) AS total_users FROM users;
SELECT COUNT(*) AS total_programs FROM programs;
SELECT COUNT(*) AS total_teachers FROM teachers;
SELECT COUNT(*) AS total_students FROM students;

