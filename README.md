# 📅 Timetable Management System

A full-stack web application for managing and automatically generating academic timetables for colleges and universities. Built with **Python Flask** and **MySQL**, it supports role-based access, smart scheduling, conflict detection, and multi-format export.

---

## 🚀 Features

### 🔐 Role-Based Access Control
- **Admin** — Full access: manage all data, generate timetables, configure the system
- **Coordinator** — Generate timetables, manage assignments, view conflicts and statistics
- **Teacher** — View personal timetable, set scheduling preferences
- **Student** — View class timetable

### 🧠 Automated Timetable Generation
- Advanced constraint-based scheduling algorithm
- Respects teacher availability, room capacity, and subject requirements
- Automatically avoids scheduling conflicts
- Supports re-generation with overwrite confirmation

### 🏫 Data Management
- **Teachers** — Add, edit, delete teacher records
- **Rooms** — Manage rooms with capacity and type (Lecture / Lab)
- **Subjects** — Define subjects with required room type
- **Classes (Sections)** — Organize by program, year, and section name
- **Subject Assignments** — Assign subjects to teachers and classes with hours/week
- **Session Types** — Define lecture types, break types, lunch periods (with color coding)
- **Timeslots** — Auto-generate full weekly period structure or configure manually

### 📊 Statistics & Analytics
- **Teacher Workload** — Classes, subjects, and sections per teacher
- **Room Utilization** — Usage count and utilization percentage per room
- **Quality Metrics** — Score the generated timetable for balance and efficiency

### ⚠️ Conflict Detection
- Detects double-booked teachers, rooms, or classes
- Severity-based reporting (Error / Warning)
- Mark conflicts as resolved

### 📤 Export Options
- Export timetable as **PDF**, **Excel (.xlsx)**
- Export a single class or all classes at once
- Multi-section Excel export (one sheet per class)

### ✏️ Manual Editing
- Edit individual timetable slots after generation
- Drag-and-drop slot swapping
- Delete individual slots

### 🔔 Notifications & Teacher Preferences
- Notification system per user
- Teachers can set preferred/unavailable time slots

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Python 3, Flask |
| Database | MySQL |
| Frontend | HTML5, CSS3, Vanilla JavaScript |
| Auth | Flask Sessions + bcrypt password hashing |
| Export | openpyxl (Excel), ReportLab (PDF), icalendar (iCal) |
| CORS | Flask-CORS |

---

## 📁 Project Structure

```
TIMETABLE-MANAGEMENT-SYSTEM/
├── app.py                  # Main Flask application & all API routes
├── backend/
│   ├── db_config.py        # Database connection helper
│   ├── test_generator.py   # Timetable generation algorithm
│   ├── conflict_detector.py# Conflict detection logic
│   ├── export_manager.py   # PDF / Excel / CSV / iCal export
│   ├── quality_metrics.py  # Timetable quality scoring
│   ├── bulk_operations.py  # Bulk import/update utilities
│   └── requirements.txt    # Python dependencies
└── frontend/
    ├── index.html          # Main dashboard (single-page app)
    ├── login.html          # Login page
    ├── css/styles.css      # All styling
    └── js/
        ├── script.js       # Core frontend logic
        ├── advanced_features.js  # Conflicts, export, stats, editing
        └── login.js        # Login page logic
```

---

## ⚙️ Setup & Installation

### 1. Clone the repository
```bash
git clone https://github.com/saurabhmaliyan63/TIMETABLE-MANAGEMENT-SYSTEM.git
cd TIMETABLE-MANAGEMENT-SYSTEM
```

### 2. Create and activate a virtual environment
```bash
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate
```

### 3. Install dependencies
```bash
pip install -r backend/requirements.txt
```

### 4. Set up the MySQL database
- Create a MySQL database (e.g., `timetable_db`)
- Run the SQL schema to create all required tables
- Update the database credentials in `backend/db_config.py`

### 5. Run the application
```bash
python app.py
```

Visit **http://localhost:5000** in your browser.

---

## 🔑 Default Login

| Role | Username | Password |
|------|----------|----------|
| Admin | `admin` | *(set during DB setup)* |
| Coordinator | `coordinator` | *(set during DB setup)* |

> Passwords are stored as **bcrypt hashes** — never plain text.

---

## 📖 How to Use

1. **Login** as Admin or Coordinator
2. Go to **Manage Teachers** → Add all teachers
3. Go to **Manage Rooms** → Add rooms with capacity and type
4. Go to **Manage Classes** → Add programs, years, and sections
5. Go to **Manage Subjects** → Add subjects
6. Go to **Assign Subjects** → Link subjects to teachers and classes
7. Go to **Day & Periods** → Generate your weekly timeslot structure
8. Go to **Generate Timetable** → Click **Generate** and let the algorithm do the work
9. Go to **Timetable Viewer** → View, edit, and export the result

---


## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 👤 Author

**Saurabh Maliyan**  
GitHub: [@saurabhmaliyan63](https://github.com/saurabhmaliyan63)
Gmail : saurabhmaliyan63@gmail.com
