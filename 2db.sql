USE timetable_db;
CREATE TABLE IF NOT EXISTS admission_applicants (
    applicant_id       INT AUTO_INCREMENT PRIMARY KEY,
    full_name          VARCHAR(150)      NOT NULL,
    email              VARCHAR(120)      NOT NULL,
    phone              VARCHAR(30),
    dob                DATE,
    gender             ENUM('M','F','O') NULL,
    program_id         INT               NOT NULL,
    academic_year_id   INT               NULL,
    status             ENUM('APPLIED','UNDER_REVIEW','ACCEPTED','REJECTED','ENROLLED')
                       DEFAULT 'APPLIED',
    created_at         DATETIME          DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME          DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    notes              TEXT,
    CONSTRAINT fk_applicant_program
        FOREIGN KEY (program_id) REFERENCES programs(program_id),
    CONSTRAINT fk_applicant_year
        FOREIGN KEY (academic_year_id) REFERENCES academic_years(year_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_applicants_status ON admission_applicants(status);
CREATE INDEX idx_applicants_program_year ON admission_applicants(program_id, academic_year_id);

-- =========================================================
-- 2. DEPARTMENTS
-- =========================================================

CREATE TABLE IF NOT EXISTS departments (
    dept_id        INT AUTO_INCREMENT PRIMARY KEY,
    code           VARCHAR(20)  NOT NULL UNIQUE,
    name           VARCHAR(150) NOT NULL,
    location       VARCHAR(150),
    head_teacher_id INT NULL,
    created_at     DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_departments_head_teacher
        FOREIGN KEY (head_teacher_id) REFERENCES teachers(teacher_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 3. STUDENTS
-- =========================================================

CREATE TABLE IF NOT EXISTS students (
    student_id      INT AUTO_INCREMENT PRIMARY KEY,
    enrollment_no   VARCHAR(50)  NOT NULL UNIQUE,
    roll_no         VARCHAR(50),
    first_name      VARCHAR(80)  NOT NULL,
    last_name       VARCHAR(80),
    dob             DATE,
    gender          ENUM('M','F','O') NULL,
    blood_group     VARCHAR(5),
    phone           VARCHAR(30),
    email           VARCHAR(120),
    address         VARCHAR(255),
    dept_id         INT          NULL,
    program_id      INT          NULL,
    section_id      INT          NULL,
    admission_year  INT          NULL,
    status          ENUM('ACTIVE','INACTIVE','ALUMNI') DEFAULT 'ACTIVE',
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_students_dept
        FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
    CONSTRAINT fk_students_program
        FOREIGN KEY (program_id) REFERENCES programs(program_id),
    CONSTRAINT fk_students_section
        FOREIGN KEY (section_id) REFERENCES sections(section_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_students_dept ON students(dept_id);
CREATE INDEX idx_students_program ON students(program_id);
CREATE INDEX idx_students_section ON students(section_id);
CREATE INDEX idx_students_status ON students(status);

-- =========================================================
-- 4. ACADEMICS: EXTEND SUBJECTS AS COURSES
--    (Requires MySQL 8+ for IF NOT EXISTS on columns)
-- =========================================================

ALTER TABLE subjects
    ADD COLUMN IF NOT EXISTS code        VARCHAR(50)  NULL UNIQUE,
    ADD COLUMN IF NOT EXISTS credits     TINYINT      NULL,
    ADD COLUMN IF NOT EXISTS subject_type ENUM('CORE','ELECTIVE','LAB','SEMINAR') NULL,
    ADD COLUMN IF NOT EXISTS max_marks   INT          NULL,
    ADD COLUMN IF NOT EXISTS pass_marks  INT          NULL;

-- Optional index for faster course lookups
CREATE INDEX IF NOT EXISTS idx_subjects_code ON subjects(code);

-- Link subjects to departments and semesters
ALTER TABLE subjects
    ADD COLUMN IF NOT EXISTS dept_id     INT NULL,
    ADD COLUMN IF NOT EXISTS semester_id INT NULL,
    ADD CONSTRAINT fk_subjects_dept
        FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
    ADD CONSTRAINT fk_subjects_semester
        FOREIGN KEY (semester_id) REFERENCES semesters(semester_id);

-- =========================================================
-- 5. ENROLLMENTS (STUDENT–SUBJECT/SECTION)
-- =========================================================

CREATE TABLE IF NOT EXISTS enrollments (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id    INT          NOT NULL,
    subject_id    INT          NOT NULL,
    section_id    INT          NULL,
    semester_id   INT          NULL,
    status        ENUM('ENROLLED','COMPLETED','DROPPED') DEFAULT 'ENROLLED',
    enrolled_at   DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_enroll_student
        FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_enroll_subject
        FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
    CONSTRAINT fk_enroll_section
        FOREIGN KEY (section_id) REFERENCES sections(section_id),
    CONSTRAINT fk_enroll_semester
        FOREIGN KEY (semester_id) REFERENCES semesters(semester_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE UNIQUE INDEX idx_enroll_unique
    ON enrollments(student_id, subject_id, semester_id);

CREATE INDEX idx_enroll_status ON enrollments(status);

-- =========================================================
-- 6. ATTENDANCE MANAGEMENT
-- =========================================================

-- 6.1 Attendance Sessions (metadata per session)
CREATE TABLE IF NOT EXISTS attendance_sessions (
    session_id      INT AUTO_INCREMENT PRIMARY KEY,
    slot_id         INT          NULL,         -- link to timetable_slots if available
    subject_id      INT          NOT NULL,
    section_id      INT          NULL,
    teacher_id      INT          NULL,
    session_date    DATE         NOT NULL,
    start_time      TIME         NULL,
    end_time        TIME         NULL,
    created_by      INT          NOT NULL,     -- users.user_id
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,
    notes           VARCHAR(255),
    CONSTRAINT fk_att_sess_subject
        FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
    CONSTRAINT fk_att_sess_section
        FOREIGN KEY (section_id) REFERENCES sections(section_id),
    CONSTRAINT fk_att_sess_teacher
        FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id),
    CONSTRAINT fk_att_sess_slot
        FOREIGN KEY (slot_id) REFERENCES timetable_slots(slot_id),
    CONSTRAINT fk_att_sess_user
        FOREIGN KEY (created_by) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_att_sess_date ON attendance_sessions(session_date);
CREATE INDEX idx_att_sess_teacher ON attendance_sessions(teacher_id);

-- 6.2 Attendance Records (per student)
CREATE TABLE IF NOT EXISTS attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    session_id    INT          NOT NULL,
    student_id    INT          NOT NULL,
    status        ENUM('PRESENT','ABSENT','LATE','EXCUSED') NOT NULL,
    remark        VARCHAR(255),
    marked_at     DATETIME     DEFAULT CURRENT_TIMESTAMP,
    marked_by     INT          NOT NULL,  -- users.user_id
    CONSTRAINT fk_att_session
        FOREIGN KEY (session_id) REFERENCES attendance_sessions(session_id),
    CONSTRAINT fk_att_student
        FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_att_marked_by
        FOREIGN KEY (marked_by) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE UNIQUE INDEX idx_att_unique
    ON attendance(session_id, student_id);

CREATE INDEX idx_att_student ON attendance(student_id);
CREATE INDEX idx_att_status ON attendance(status);

-- =========================================================
-- 7. EXAMS & GRADES
-- =========================================================

CREATE TABLE IF NOT EXISTS exams (
    exam_id      INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(150) NOT NULL,
    subject_id   INT          NOT NULL,
    section_id   INT          NULL,
    semester_id  INT          NULL,
    exam_date    DATE         NOT NULL,
    start_time   TIME         NULL,
    end_time     TIME         NULL,
    total_marks  INT          DEFAULT 100,
    weightage    DECIMAL(5,2) NULL,
    created_at   DATETIME     DEFAULT CURRENT_TIMESTAMP,
    created_by   INT          NULL,       -- users.user_id
    CONSTRAINT fk_exams_subject
        FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
    CONSTRAINT fk_exams_section
        FOREIGN KEY (section_id) REFERENCES sections(section_id),
    CONSTRAINT fk_exams_semester
        FOREIGN KEY (semester_id) REFERENCES semesters(semester_id),
    CONSTRAINT fk_exams_user
        FOREIGN KEY (created_by) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_exams_subject ON exams(subject_id);
CREATE INDEX idx_exams_date ON exams(exam_date);

CREATE TABLE IF NOT EXISTS exam_results (
    result_id      INT AUTO_INCREMENT PRIMARY KEY,
    exam_id        INT          NOT NULL,
    student_id     INT          NOT NULL,
    marks_obtained DECIMAL(5,2) NOT NULL,
    grade          VARCHAR(5),
    remarks        VARCHAR(255),
    created_at     DATETIME     DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_results_exam
        FOREIGN KEY (exam_id) REFERENCES exams(exam_id),
    CONSTRAINT fk_results_student
        FOREIGN KEY (student_id) REFERENCES students(student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE UNIQUE INDEX idx_results_unique
    ON exam_results(exam_id, student_id);

CREATE INDEX idx_results_student ON exam_results(student_id);

-- =========================================================
-- 8. FINANCE MANAGEMENT
-- =========================================================

-- 8.1 Fee Structures
CREATE TABLE IF NOT EXISTS fee_structures (
    fee_id        INT AUTO_INCREMENT PRIMARY KEY,
    program_id    INT          NOT NULL,
    academic_year_id INT       NULL,
    semester_id   INT          NULL,
    fee_type      VARCHAR(50)  NOT NULL,   -- tuition, exam, library, etc.
    description   VARCHAR(255),
    amount        DECIMAL(10,2) NOT NULL,
    created_at    DATETIME      DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fee_program
        FOREIGN KEY (program_id) REFERENCES programs(program_id),
    CONSTRAINT fk_fee_year
        FOREIGN KEY (academic_year_id) REFERENCES academic_years(year_id),
    CONSTRAINT fk_fee_semester
        FOREIGN KEY (semester_id) REFERENCES semesters(semester_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_fee_program_sem ON fee_structures(program_id, semester_id);

-- 8.2 Invoices
CREATE TABLE IF NOT EXISTS invoices (
    invoice_id   INT AUTO_INCREMENT PRIMARY KEY,
    invoice_no   VARCHAR(50)   NOT NULL UNIQUE,
    student_id   INT           NOT NULL,
    fee_id       INT           NULL,
    issue_date   DATE          NOT NULL,
    due_date     DATE          NOT NULL,
    amount       DECIMAL(10,2) NOT NULL,
    status       ENUM('PENDING','PAID','OVERDUE') DEFAULT 'PENDING',
    created_at   DATETIME      DEFAULT CURRENT_TIMESTAMP,
    created_by   INT           NULL,   -- users.user_id
    CONSTRAINT fk_invoice_student
        FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_invoice_fee
        FOREIGN KEY (fee_id) REFERENCES fee_structures(fee_id),
    CONSTRAINT fk_invoice_user
        FOREIGN KEY (created_by) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_invoices_student ON invoices(student_id);
CREATE INDEX idx_invoices_status ON invoices(status);

-- 8.3 Payments
CREATE TABLE IF NOT EXISTS payments (
    payment_id    INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id    INT           NOT NULL,
    paid_on       DATE          NOT NULL,
    amount        DECIMAL(10,2) NOT NULL,
    mode          VARCHAR(50)   NOT NULL, -- Cash, Cheque, Bank Transfer, etc.
    transaction_id VARCHAR(100),
    created_at    DATETIME      DEFAULT CURRENT_TIMESTAMP,
    created_by    INT           NULL,     -- users.user_id
    CONSTRAINT fk_payment_invoice
        FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id),
    CONSTRAINT fk_payment_user
        FOREIGN KEY (created_by) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_payments_invoice ON payments(invoice_id);

-- 8.4 Vendors (for expenses)
CREATE TABLE IF NOT EXISTS vendors (
    vendor_id   INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(150) NOT NULL,
    contact_person VARCHAR(100),
    phone       VARCHAR(50),
    email       VARCHAR(120),
    address     VARCHAR(255),
    created_at  DATETIME      DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8.5 Expenses
CREATE TABLE IF NOT EXISTS expenses (
    expense_id   INT AUTO_INCREMENT PRIMARY KEY,
    vendor_id    INT           NULL,
    category     VARCHAR(100)  NOT NULL,
    description  VARCHAR(255),
    amount       DECIMAL(10,2) NOT NULL,
    expense_date DATE          NOT NULL,
    created_at   DATETIME      DEFAULT CURRENT_TIMESTAMP,
    created_by   INT           NULL,     -- users.user_id
    CONSTRAINT fk_expense_vendor
        FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id),
    CONSTRAINT fk_expense_user
        FOREIGN KEY (created_by) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_expenses_date ON expenses(expense_date);
CREATE INDEX idx_expenses_category ON expenses(category);

-- =========================================================
-- 9. AUDIT & LOGGING
-- =========================================================

CREATE TABLE IF NOT EXISTS audit_log (
    audit_id     BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT           NULL,
    action       ENUM('INSERT','UPDATE','DELETE','LOGIN','LOGOUT','OTHER') NOT NULL,
    table_name   VARCHAR(100)  NOT NULL,
    record_id    VARCHAR(100)  NULL,
    description  VARCHAR(255)  NULL,
    created_at   DATETIME      DEFAULT CURRENT_TIMESTAMP,
    ip_address   VARCHAR(45),
    CONSTRAINT fk_audit_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_audit_table ON audit_log(table_name);
CREATE INDEX idx_audit_action ON audit_log(action);

COMMIT;