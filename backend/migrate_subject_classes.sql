-- Migration: Add Subject-Class direct relationship for Manage Subjects page
USE timetable_db;

-- 1. Create new subject_sections table (direct subject-class mapping)
CREATE TABLE IF NOT EXISTS subject_sections (
    id INT AUTO_INCREMENT PRIMARY KEY,
    subject_id INT NOT NULL,
    section_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_subject_section (subject_id, section_id),
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES sections(section_id) ON DELETE CASCADE,
    INDEX idx_subject (subject_id),
    INDEX idx_section (section_id)
);

-- 2. Populate from existing subject_assignments (distinct subject-section pairs)
INSERT IGNORE INTO subject_sections (subject_id, section_id)
SELECT DISTINCT subject_id, section_id 
FROM subject_assignments 
WHERE subject_id IS NOT NULL AND section_id IS NOT NULL;

-- 3. Verify data
SELECT 'Migration complete' AS status;
SELECT COUNT(*) as new_records FROM subject_sections;
SELECT COUNT(DISTINCT sa.subject_id, sa.section_id) as source_records FROM subject_assignments sa;
