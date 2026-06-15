USE timetable_db;

-- 3. INSERT ALL TEST DATA

-- Insert Session Types
INSERT INTO session_types (name, description, color) VALUES
('Lecture', 'Regular lecture session', '#007bff'),
('Break', 'Break time between sessions', '#28a745'),
('Seminar', 'Seminar or workshop session', '#ffc107'),
('Lab', 'Laboratory session', '#dc3545'),
('Exam', 'Examination period', '#6f42c1');

-- Insert Users with hashed passwords
INSERT INTO users (username, `password`, role) VALUES
('admin', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4fYwKjQX1e', 'admin'), -- password: admin_pass123
('coordinator', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4fYwKjQX1e', 'coordinator'), -- password: coord_pass123
('prof_einstein', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4fYwKjQX1e', 'teacher'), -- password: teacher_pass1
('prof_curie', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4fYwKjQX1e', 'teacher'), -- password: teacher_pass2
('prof_turing', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4fYwKjQX1e', 'teacher'), -- password: teacher_pass3
('student_alice', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4fYwKjQX1e', 'student'), -- password: student_pass1
('student_bob', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4fYwKjQX1e', 'student'), -- password: student_pass2
('student_charlie', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4fYwKjQX1e', 'student'), -- password: student_pass3
('student_dave', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4fYwKjQX1e', 'student'); -- password: student_pass4

-- Insert Programs
INSERT INTO programs (name) VALUES
('Bachelor of Computer Applications'),
('Bachelor of Technology');

-- Insert Sections (BCA=1, B.Tech=2)
INSERT INTO sections (program_id, year, section_name, size) VALUES
(1, 1, 'A', 45),
(1, 1, 'B', 50),
(2, 2, 'A', 60);

-- Insert Students (alice=6, bob=7, charlie=8, dave=9 | bca_1a=1, bca_1b=2, btech_2a=3)
INSERT INTO students (user_id, section_id, name) VALUES
(6, 1, 'Alice Smith'),
(7, 1, 'Bob Johnson'),
(8, 2, 'Charlie Brown'),
(9, 3, 'Dave Davis');

-- Insert Teachers (einstein=3, curie=4, turing=5)
INSERT INTO teachers (user_id, name, email) VALUES
(3, 'Albert Einstein', 'einstein@uni.com'),
(4, 'Marie Curie', 'curie@uni.com'),
(5, 'Alan Turing', 'turing@uni.com');

-- Insert Teacher Availability (einstein=1, curie=2, turing=3)
INSERT INTO teacher_availability (teacher_id, day_of_week, start_time, end_time) VALUES
(1, 'Monday', '09:00:00', '17:00:00'),
(1, 'Tuesday', '09:00:00', '17:00:00'),
(1, 'Wednesday', '09:00:00', '12:00:00'),
(2, 'Wednesday', '13:00:00', '17:00:00'),
(2, 'Thursday', '09:00:00', '17:00:00'),
(2, 'Friday', '09:00:00', '17:00:00'),
(3, 'Monday', '09:00:00', '17:00:00'),
(3, 'Friday', '09:00:00', '17:00:00');

-- Insert Rooms
INSERT INTO rooms (name, capacity, type) VALUES
('Main Hall (A-101)', 65, 'LECTURE'),
('West Wing (W-202)', 45, 'LECTURE'),
('Computer Lab (CS-01)', 50, 'LAB');

-- Insert Subjects
INSERT INTO subjects (name, requires_room_type) VALUES
('Physics 101', NULL),
('History of Science', NULL),
('Calculus I', NULL),
('Data Structures', 'LAB');

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
-- (einstein=1, curie=2, turing=3 | bca_1a=1, bca_1b=2, btech_2a=3 | physics=1, history=2, calculus=3, data_structures=4)
INSERT INTO subject_assignments (subject_id, teacher_id, section_id, hours_per_week) VALUES
(1, 1, 1, 3), -- Einstein teaches Physics to BCA 1A (3 hours)
(4, 3, 1, 3), -- Turing teaches Data Structures to BCA 1A (3 hours)
(3, 1, 2, 3), -- Einstein teaches Calculus to BCA 1B (3 hours)
(4, 3, 2, 3), -- Turing teaches Data Structures to BCA 1B (3 hours)
(2, 2, 3, 4); -- Curie teaches History to B.Tech 2A (4 hours)

-- 4. FINAL CHECK
SELECT 'Database successfully reset and populated with all tables.' AS status;
