-- ============================================================================
-- BCA TEST DATA SCRIPT (Updated with Comprehensive Schema)
-- Creates schema and populates data for BCA (3 Years, 3 Sections/Year, 6 Subjects/Year)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS timetable_db;
USE timetable_db;

-- ============================================================================
-- 1. DROP ALL TABLES SAFELY
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
-- 2. CREATE ALL TABLES (Comprehensive Schema)
-- ============================================================================

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

CREATE TABLE rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    type ENUM('LECTURE', 'LAB', 'SEMINAR', 'AUDITORIUM') NOT NULL,
    building VARCHAR(100),
    floor INT,
    location_description TEXT,
    equipment JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (type),
    INDEX idx_building (building),
    INDEX idx_active (is_active)
);

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

CREATE TABLE session_types (
    session_type_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(200),
    color VARCHAR(7) DEFAULT '#007bff',
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_active (is_active)
);

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

CREATE TABLE scheduling_constraints (
    constraint_id INT AUTO_INCREMENT PRIMARY KEY,
    constraint_type ENUM('NO_CONSECUTIVE_LABS', 'MAX_DAILY_HOURS', 'MIN_BREAK_TIME', 'PREFERRED_TIME_SLOT', 'NO_BACK_TO_BACK') NOT NULL,
    entity_type ENUM('TEACHER', 'SECTION', 'SUBJECT', 'GLOBAL') NOT NULL,
    entity_id INT,
    constraint_value VARCHAR(500),
    is_hard_constraint BOOLEAN DEFAULT TRUE,
    weight INT DEFAULT 10 CHECK (weight >= 1 AND weight <= 10),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (constraint_type, entity_type),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_active (is_active)
);

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
    UNIQUE(timeslot_id, teacher_id, section_id),
    UNIQUE(timeslot_id, room_id, section_id),
    INDEX idx_timeslot_id (timeslot_id),
    INDEX idx_teacher_id (teacher_id),
    INDEX idx_room_id (room_id),
    INDEX idx_section_id (section_id),
    INDEX idx_semester_id (semester_id)
);

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

CREATE TABLE timetable_version_slots (
    version_slot_id INT AUTO_INCREMENT PRIMARY KEY,
    version_id INT NOT NULL,
    slot_id INT,
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

-- 3. DATA POPULATION

-- Users (Admin + 15 Teachers)
INSERT INTO users (username, `password`, email, role, first_name, last_name) VALUES
('admin', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'admin@bca.edu', 'admin', 'System', 'Admin'),
('t_math1', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'math1@bca.edu', 'teacher', 'John', 'Nash'),
('t_cs1', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'cs1@bca.edu', 'teacher', 'Alan', 'Turing'),
('t_cs2', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'cs2@bca.edu', 'teacher', 'Grace', 'Hopper'),
('t_eng', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'eng@bca.edu', 'teacher', 'William', 'Shakespeare'),
('t_elec', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'elec@bca.edu', 'teacher', 'Nikola', 'Tesla'),
('t_math2', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'math2@bca.edu', 'teacher', 'Ada', 'Lovelace'),
('t_web', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'web@bca.edu', 'teacher', 'Tim', 'Berners-Lee'),
('t_java', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'java@bca.edu', 'teacher', 'James', 'Gosling'),
('t_dbms', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'dbms@bca.edu', 'teacher', 'Edgar', 'Codd'),
('t_net', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'net@bca.edu', 'teacher', 'Vint', 'Cerf'),
('t_py', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'py@bca.edu', 'teacher', 'Guido', 'Van Rossum'),
('t_lab1', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'lab1@bca.edu', 'teacher', 'Linus', 'Torvalds'),
('t_lab2', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'lab2@bca.edu', 'teacher', 'Dennis', 'Ritchie'),
('t_mgmt', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'mgmt@bca.edu', 'teacher', 'Peter', 'Drucker'),
('t_env', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'env@bca.edu', 'teacher', 'Rachel', 'Carson'),
('t_new1', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'new1@bca.edu', 'teacher', 'Isaac', 'Newton'),
('t_new2', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'new2@bca.edu', 'teacher', 'Galileo', 'Galilei'),
('t_new3', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'new3@bca.edu', 'teacher', 'Charles', 'Darwin'),
('t_new4', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'new4@bca.edu', 'teacher', 'Stephen', 'Hawking'),
('t_new5', '$2b$12$uQAEzhX4WL2yzog2hY6XvOGs61ytRr541WWhOmMquDkoJF0tR63vW', 'new5@bca.edu', 'teacher', 'Niels', 'Bohr');

-- Teachers Table
INSERT INTO teachers (user_id, name, email, department) VALUES
(2, 'Prof. John Nash', 'math1@bca.edu', 'Mathematics'),
(3, 'Prof. Alan Turing', 'cs1@bca.edu', 'Computer Science'),
(4, 'Prof. Grace Hopper', 'cs2@bca.edu', 'Computer Science'),
(5, 'Prof. William Shakespeare', 'eng@bca.edu', 'Humanities'),
(6, 'Prof. Nikola Tesla', 'elec@bca.edu', 'Electronics'),
(7, 'Prof. Ada Lovelace', 'math2@bca.edu', 'Mathematics'),
(8, 'Prof. Tim Berners-Lee', 'web@bca.edu', 'Computer Science'),
(9, 'Prof. James Gosling', 'java@bca.edu', 'Computer Science'),
(10, 'Prof. Edgar Codd', 'dbms@bca.edu', 'Computer Science'),
(11, 'Prof. Vint Cerf', 'net@bca.edu', 'Computer Science'),
(12, 'Prof. Guido Van Rossum', 'py@bca.edu', 'Computer Science'),
(13, 'Prof. Linus Torvalds', 'lab1@bca.edu', 'Computer Science'),
(14, 'Prof. Dennis Ritchie', 'lab2@bca.edu', 'Computer Science'),
(15, 'Prof. Peter Drucker', 'mgmt@bca.edu', 'Management'),
(16, 'Prof. Rachel Carson', 'env@bca.edu', 'Environmental Science'),
(17, 'Prof. Isaac Newton', 'new1@bca.edu', 'Physics'),
(18, 'Prof. Galileo Galilei', 'new2@bca.edu', 'Physics'),
(19, 'Prof. Charles Darwin', 'new3@bca.edu', 'Biology'),
(20, 'Prof. Stephen Hawking', 'new4@bca.edu', 'Physics'),
(21, 'Prof. Niels Bohr', 'new5@bca.edu', 'Physics');

-- Rooms (10 Lecture Halls, 4 Labs)
INSERT INTO rooms (name, capacity, type) VALUES
('LH-101', 70, 'LECTURE'), ('LH-102', 70, 'LECTURE'), ('LH-103', 70, 'LECTURE'),
('LH-201', 70, 'LECTURE'), ('LH-202', 70, 'LECTURE'), ('LH-203', 70, 'LECTURE'),
('LH-301', 70, 'LECTURE'), ('LH-302', 70, 'LECTURE'), ('LH-303', 70, 'LECTURE'),
('LH-304', 70, 'LECTURE'),
('Computer Lab 1', 40, 'LAB'), ('Computer Lab 2', 40, 'LAB'),
('Electronics Lab', 40, 'LAB'), ('Language Lab', 40, 'LAB'),
-- New Rooms for better capacity
('LH-104', 70, 'LECTURE'), ('LH-105', 70, 'LECTURE'),
('LH-204', 70, 'LECTURE'), ('LH-205', 70, 'LECTURE'),
('Computer Lab 3', 40, 'LAB'), ('Physics Lab 2', 40, 'LAB');

-- Program
INSERT INTO programs (name, short_code, department, duration_years) VALUES 
('Bachelor of Computer Applications', 'BCA', 'Computer Science', 3);

-- Academic Year & Semester
INSERT INTO academic_years (name, start_date, end_date, is_active) VALUES 
('2024-2025', '2024-06-01', '2025-05-31', TRUE);

INSERT INTO semesters (year_id, name, start_date, end_date, is_active) VALUES 
(1, 'Odd Semester 2024', '2024-07-01', '2024-12-15', TRUE);

-- Sections (3 Years * 3 Sections = 9 Sections)
INSERT INTO sections (section_name, program_id, year, size, semester_id) VALUES
('A', 1, 1, 60, 1), ('B', 1, 1, 60, 1), ('C', 1, 1, 60, 1), -- Year 1
('A', 1, 2, 60, 1), ('B', 1, 2, 60, 1), ('C', 1, 2, 60, 1), -- Year 2
('A', 1, 3, 60, 1), ('B', 1, 3, 60, 1), ('C', 1, 3, 60, 1); -- Year 3

-- Subjects (6 per year)
INSERT INTO subjects (name, code, requires_room_type, credits) VALUES
-- Year 1
('Mathematics-I', 'BCA101', 'LECTURE', 4),
('Computer Fundamentals', 'BCA102', 'LECTURE', 4),
('C Programming', 'BCA103', 'LECTURE', 4),
('Communication Skills', 'BCA104', 'LECTURE', 3),
('Digital Electronics', 'BCA105', 'LECTURE', 4),
('C Programming Lab', 'BCA106', 'LAB', 2),
-- Year 2
('Mathematics-II', 'BCA201', 'LECTURE', 4),
('Data Structures', 'BCA202', 'LECTURE', 4),
('Object Oriented Prog (C++)', 'BCA203', 'LECTURE', 4),
('Operating Systems', 'BCA204', 'LECTURE', 4),
('Database Mgmt Systems', 'BCA205', 'LECTURE', 4),
('DS & C++ Lab', 'BCA206', 'LAB', 2),
-- Year 3
('Software Engineering', 'BCA301', 'LECTURE', 4),
('Computer Networks', 'BCA302', 'LECTURE', 4),
('Web Technologies', 'BCA303', 'LECTURE', 4),
('Java Programming', 'BCA304', 'LECTURE', 4),
('Python Programming', 'BCA305', 'LECTURE', 4),
('Web & Java Lab', 'BCA306', 'LAB', 2);

-- Session Types
INSERT INTO session_types (name, color) VALUES 
('Lecture', '#007bff'), ('Lab', '#dc3545'), ('Break', '#28a745');

-- Timeslots (Mon-Fri, 9:00 - 16:00, with Lunch at 12:00)
INSERT INTO timeslots (day_of_week, start_time, end_time, session_type_id) VALUES
-- Monday
('Monday', '09:00:00', '10:00:00', 1), ('Monday', '10:00:00', '11:00:00', 1), ('Monday', '11:00:00', '12:00:00', 1),
('Monday', '12:00:00', '13:00:00', 3), -- Lunch
('Monday', '13:00:00', '14:00:00', 1), ('Monday', '14:00:00', '15:00:00', 1), ('Monday', '15:00:00', '16:00:00', 1),
-- Tuesday
('Tuesday', '09:00:00', '10:00:00', 1), ('Tuesday', '10:00:00', '11:00:00', 1), ('Tuesday', '11:00:00', '12:00:00', 1),
('Tuesday', '12:00:00', '13:00:00', 3),
('Tuesday', '13:00:00', '14:00:00', 1), ('Tuesday', '14:00:00', '15:00:00', 1), ('Tuesday', '15:00:00', '16:00:00', 1),
-- Wednesday
('Wednesday', '09:00:00', '10:00:00', 1), ('Wednesday', '10:00:00', '11:00:00', 1), ('Wednesday', '11:00:00', '12:00:00', 1),
('Wednesday', '12:00:00', '13:00:00', 3),
('Wednesday', '13:00:00', '14:00:00', 1), ('Wednesday', '14:00:00', '15:00:00', 1), ('Wednesday', '15:00:00', '16:00:00', 1),
-- Thursday
('Thursday', '09:00:00', '10:00:00', 1), ('Thursday', '10:00:00', '11:00:00', 1), ('Thursday', '11:00:00', '12:00:00', 1),
('Thursday', '12:00:00', '13:00:00', 3),
('Thursday', '13:00:00', '14:00:00', 1), ('Thursday', '14:00:00', '15:00:00', 1), ('Thursday', '15:00:00', '16:00:00', 1),
-- Friday
('Friday', '09:00:00', '10:00:00', 1), ('Friday', '10:00:00', '11:00:00', 1), ('Friday', '11:00:00', '12:00:00', 1),
('Friday', '12:00:00', '13:00:00', 3),
('Friday', '13:00:00', '14:00:00', 1), ('Friday', '14:00:00', '15:00:00', 1), ('Friday', '15:00:00', '16:00:00', 1);

-- Subject Assignments (Distributing subjects to teachers and sections)
-- Hours per week: 4 for lectures, 3 for labs

-- YEAR 1 (Sections 1, 2, 3)
-- Subjects: 1-6
INSERT INTO subject_assignments (subject_id, teacher_id, section_id, hours_per_week) VALUES
-- Section A (ID 1)
(1, 1, 1, 4), -- Math-I (Nash)
(2, 2, 1, 4), -- Fundamentals (Turing)
(3, 3, 1, 4), -- C Prog (Hopper)
(4, 4, 1, 3), -- Comm Skills (Shakespeare)
(5, 5, 1, 4), -- Digital Elec (Tesla)
(6, 12, 1, 3), -- C Lab (Torvalds)
-- Section B (ID 2)
(1, 1, 2, 4), -- Math-I (Nash)
(2, 2, 2, 4), -- Fundamentals (Turing)
(3, 3, 2, 4), -- C Prog (Hopper)
(4, 4, 2, 3), -- Comm Skills (Shakespeare)
(5, 5, 2, 4), -- Digital Elec (Tesla)
(6, 12, 2, 3), -- C Lab (Torvalds)
-- Section C (ID 3)
(1, 6, 3, 4), -- Math-I (Lovelace)
(2, 16, 3, 4), -- Fundamentals (Newton)
(3, 17, 3, 4), -- C Prog (Galileo)
(4, 4, 3, 3), -- Comm Skills (Shakespeare)
(5, 5, 3, 4), -- Digital Elec (Tesla)
(6, 13, 3, 3); -- C Lab (Ritchie)

-- YEAR 2 (Sections 4, 5, 6)
-- Subjects: 7-12
INSERT INTO subject_assignments (subject_id, teacher_id, section_id, hours_per_week) VALUES
-- Section A (ID 4)
(7, 6, 4, 4), -- Math-II (Lovelace)
(8, 2, 4, 4), -- DS (Turing)
(9, 3, 4, 4), -- C++ (Hopper)
(10, 12, 4, 4), -- OS (Torvalds)
(11, 9, 4, 4), -- DBMS (Codd)
(12, 13, 4, 3), -- DS Lab (Ritchie)
-- Section B (ID 5)
(7, 6, 5, 4), -- Math-II (Lovelace)
(8, 2, 5, 4), -- DS (Turing)
(9, 3, 5, 4), -- C++ (Hopper)
(10, 12, 5, 4), -- OS (Torvalds)
(11, 9, 5, 4), -- DBMS (Codd)
(12, 13, 5, 3), -- DS Lab (Ritchie)
-- Section C (ID 6)
(7, 1, 6, 4), -- Math-II (Nash)
(8, 16, 6, 4), -- DS (Newton)
(9, 17, 6, 4), -- C++ (Galileo)
(10, 19, 6, 4), -- OS (Hawking)
(11, 9, 6, 4), -- DBMS (Codd)
(12, 13, 6, 3); -- DS Lab (Ritchie)

-- YEAR 3 (Sections 7, 8, 9)
-- Subjects: 13-18
INSERT INTO subject_assignments (subject_id, teacher_id, section_id, hours_per_week) VALUES
-- Section A (ID 7)
(13, 4, 7, 4), -- SE (Hopper)
(14, 10, 7, 4), -- Networks (Cerf)
(15, 7, 7, 4), -- Web (Berners-Lee)
(16, 8, 7, 4), -- Java (Gosling)
(17, 11, 7, 4), -- Python (Van Rossum)
(18, 7, 7, 3), -- Web Lab (Berners-Lee)
-- Section B (ID 8)
(13, 4, 8, 4), -- SE (Hopper)
(14, 10, 8, 4), -- Networks (Cerf)
(15, 7, 8, 4), -- Web (Berners-Lee)
(16, 8, 8, 4), -- Java (Gosling)
(17, 11, 8, 4), -- Python (Van Rossum)
(18, 8, 8, 3), -- Web Lab (Gosling)
-- Section C (ID 9)
(13, 18, 9, 4), -- SE (Darwin)
(14, 10, 9, 4), -- Networks (Cerf)
(15, 7, 9, 4), -- Web (Berners-Lee)
(16, 20, 9, 4), -- Java (Bohr)
(17, 11, 9, 4), -- Python (Van Rossum)
(18, 11, 9, 3); -- Web Lab (Van Rossum)

-- 4. VERIFICATION
SELECT 'Database successfully populated with BCA test data.' AS status;
SELECT COUNT(*) AS total_sections FROM sections;
SELECT COUNT(*) AS total_subjects FROM subjects;
SELECT COUNT(*) AS total_assignments FROM subject_assignments;