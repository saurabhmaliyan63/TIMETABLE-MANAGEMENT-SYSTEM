-- Database schema updates for enhanced timetable features
-- Run this after the base schema is created

USE timetable_db;

-- 1. Teacher Preferences Table
CREATE TABLE IF NOT EXISTS teacher_preferences (
    pref_id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
    start_time TIME,
    end_time TIME,
    preference_type ENUM('PREFERRED', 'AVOID', 'BLOCKED') NOT NULL DEFAULT 'PREFERRED',
    weight INT DEFAULT 1, -- 1-10, higher = more important
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    INDEX idx_teacher_pref (teacher_id, day_of_week)
);

-- 2. Timetable Versions Table
CREATE TABLE IF NOT EXISTS timetable_versions (
    version_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INT, -- user_id
    quality_score DECIMAL(5,2),
    FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_active (is_active)
);

-- 3. Timetable Version Slots (for versioning)
CREATE TABLE IF NOT EXISTS timetable_version_slots (
    version_slot_id INT AUTO_INCREMENT PRIMARY KEY,
    version_id INT NOT NULL,
    slot_id INT, -- reference to timetable_slots
    timeslot_id INT,
    subject_id INT,
    teacher_id INT,
    section_id INT,
    room_id INT,
    FOREIGN KEY (version_id) REFERENCES timetable_versions(version_id) ON DELETE CASCADE,
    FOREIGN KEY (timeslot_id) REFERENCES timeslots(timeslot_id),
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id),
    FOREIGN KEY (section_id) REFERENCES sections(section_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    INDEX idx_version (version_id)
);

-- 4. Conflicts Table
CREATE TABLE IF NOT EXISTS conflicts (
    conflict_id INT AUTO_INCREMENT PRIMARY KEY,
    conflict_type ENUM('TEACHER', 'ROOM', 'SECTION', 'CAPACITY', 'AVAILABILITY', 'PREFERENCE') NOT NULL,
    severity ENUM('ERROR', 'WARNING', 'INFO') DEFAULT 'WARNING',
    slot_id INT, -- reference to timetable_slots
    description TEXT,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP NULL,
    resolved_by INT, -- user_id
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (slot_id) REFERENCES timetable_slots(slot_id) ON DELETE CASCADE,
    FOREIGN KEY (resolved_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_resolved (resolved),
    INDEX idx_type (conflict_type)
);

-- 5. Timetable Comments/Notes
CREATE TABLE IF NOT EXISTS timetable_comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    slot_id INT,
    user_id INT,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (slot_id) REFERENCES timetable_slots(slot_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_slot (slot_id)
);

-- 6. Change Requests Table
CREATE TABLE IF NOT EXISTS change_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    requested_by INT, -- user_id (teacher)
    slot_id INT, -- current slot
    requested_timeslot_id INT,
    requested_room_id INT,
    reason TEXT,
    status ENUM('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED') DEFAULT 'PENDING',
    reviewed_by INT, -- user_id (coordinator/admin)
    reviewed_at TIMESTAMP NULL,
    review_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (requested_by) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (slot_id) REFERENCES timetable_slots(slot_id) ON DELETE CASCADE,
    FOREIGN KEY (requested_timeslot_id) REFERENCES timeslots(timeslot_id),
    FOREIGN KEY (requested_room_id) REFERENCES rooms(room_id),
    FOREIGN KEY (reviewed_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_status (status),
    INDEX idx_requested_by (requested_by)
);

-- 7. Academic Years/Semesters Table
CREATE TABLE IF NOT EXISTS academic_years (
    year_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(name),
    INDEX idx_active (is_active)
);

-- 8. Semesters Table
CREATE TABLE IF NOT EXISTS semesters (
    semester_id INT AUTO_INCREMENT PRIMARY KEY,
    year_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (year_id) REFERENCES academic_years(year_id) ON DELETE CASCADE,
    INDEX idx_active (is_active)
);

-- 9. Link timetable to semesters
ALTER TABLE timetable_slots 
ADD COLUMN IF NOT EXISTS semester_id INT,
ADD FOREIGN KEY IF NOT EXISTS fk_semester (semester_id) REFERENCES semesters(semester_id) ON DELETE SET NULL;

ALTER TABLE timetable_versions
ADD COLUMN IF NOT EXISTS semester_id INT,
ADD FOREIGN KEY IF NOT EXISTS fk_version_semester (semester_id) REFERENCES semesters(semester_id) ON DELETE SET NULL;

-- 10. Templates/Patterns Table
CREATE TABLE IF NOT EXISTS timetable_templates (
    template_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    template_data JSON, -- Store pattern data
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- 11. Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    type ENUM('CONFLICT', 'CHANGE', 'APPROVAL', 'REMINDER', 'SYSTEM') NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT,
    read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    link_url VARCHAR(500), -- Link to relevant page
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_read (user_id, read),
    INDEX idx_created (created_at)
);

-- 12. Quality Metrics Table
CREATE TABLE IF NOT EXISTS timetable_quality_metrics (
    metric_id INT AUTO_INCREMENT PRIMARY KEY,
    version_id INT,
    metric_type VARCHAR(50) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(10,2),
    target_value DECIMAL(10,2),
    status ENUM('PASS', 'WARNING', 'FAIL') DEFAULT 'PASS',
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (version_id) REFERENCES timetable_versions(version_id) ON DELETE CASCADE,
    INDEX idx_version (version_id)
);

-- 13. Room Preferences Table
CREATE TABLE IF NOT EXISTS room_preferences (
    pref_id INT AUTO_INCREMENT PRIMARY KEY,
    subject_id INT,
    room_id INT,
    preference_type ENUM('PREFERRED', 'AVOID') DEFAULT 'PREFERRED',
    weight INT DEFAULT 1,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE,
    FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE CASCADE
);

-- 14. Scheduling Constraints Table
CREATE TABLE IF NOT EXISTS scheduling_constraints (
    constraint_id INT AUTO_INCREMENT PRIMARY KEY,
    constraint_type ENUM('NO_CONSECUTIVE_LABS', 'MAX_DAILY_HOURS', 'MIN_BREAK_TIME', 'PREFERRED_TIME_SLOT') NOT NULL,
    entity_type ENUM('TEACHER', 'SECTION', 'SUBJECT', 'GLOBAL') NOT NULL,
    entity_id INT, -- ID of teacher/section/subject, NULL for global
    constraint_value VARCHAR(200), -- JSON or value
    is_hard_constraint BOOLEAN DEFAULT TRUE,
    weight INT DEFAULT 10, -- 1-10, only for soft constraints
    FOREIGN KEY (entity_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    INDEX idx_type (constraint_type, entity_type)
);

-- 15. Export History Table
CREATE TABLE IF NOT EXISTS export_history (
    export_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    export_type ENUM('PDF', 'EXCEL', 'CSV', 'ICAL') NOT NULL,
    export_scope ENUM('FULL', 'TEACHER', 'SECTION', 'ROOM', 'CUSTOM') NOT NULL,
    scope_id INT, -- teacher_id, section_id, etc.
    file_path VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- 16. Statistics Cache Table
CREATE TABLE IF NOT EXISTS statistics_cache (
    stat_id INT AUTO_INCREMENT PRIMARY KEY,
    stat_type VARCHAR(50) NOT NULL,
    stat_key VARCHAR(100) NOT NULL,
    stat_value JSON,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    UNIQUE KEY unique_stat (stat_type, stat_key),
    INDEX idx_expires (expires_at)
);

-- 17. Add metadata to timetable_slots
ALTER TABLE timetable_slots
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS color VARCHAR(7) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS created_by INT,
ADD COLUMN IF NOT EXISTS updated_by INT,
ADD FOREIGN KEY IF NOT EXISTS fk_created_by (created_by) REFERENCES users(user_id) ON DELETE SET NULL,
ADD FOREIGN KEY IF NOT EXISTS fk_updated_by (updated_by) REFERENCES users(user_id) ON DELETE SET NULL;

-- 18. Add building/location to rooms
ALTER TABLE rooms
ADD COLUMN IF NOT EXISTS building VARCHAR(100),
ADD COLUMN IF NOT EXISTS floor INT,
ADD COLUMN IF NOT EXISTS location_description TEXT;

-- 19. Add email to users for notifications
ALTER TABLE users
ADD COLUMN IF NOT EXISTS email VARCHAR(100),
ADD COLUMN IF NOT EXISTS notification_preferences JSON DEFAULT '{"email": true, "in_app": true}';

-- 20. Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_timetable_teacher ON timetable_slots(teacher_id);
CREATE INDEX IF NOT EXISTS idx_timetable_section ON timetable_slots(section_id);
CREATE INDEX IF NOT EXISTS idx_timetable_room ON timetable_slots(room_id);
CREATE INDEX IF NOT EXISTS idx_timetable_timeslot ON timetable_slots(timeslot_id);
CREATE INDEX IF NOT EXISTS idx_timeslot_day ON timeslots(day_of_week, start_time);

