# Timetable Generator - Setup Guide

## Prerequisites

- Python 3.8 or higher
- MySQL 5.7 or higher
- pip (Python package manager)

## Step 1: Database Setup

1. **Create MySQL Database**
   ```sql
   CREATE DATABASE timetable_db;
   ```

2. **Run Base Schema**
   ```bash
   mysql -u root -p timetable_db < create_database.sql
   ```

3. **Run Database Updates (for new features)**
   ```bash
   mysql -u root -p timetable_db < database_updates.sql
   ```

4. **Insert Sample Data (Optional)**
   ```bash
   mysql -u root -p timetable_db < insert_sample_data.sql
   ```

## Step 2: Python Environment Setup

1. **Create Virtual Environment (Recommended)**
   ```bash
   python -m venv venv
   
   # On Windows
   venv\Scripts\activate
   
   # On Linux/Mac
   source venv/bin/activate
   ```

2. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

## Step 3: Configuration

1. **Update Database Configuration**
   
   Edit `db_config.py` with your MySQL credentials:
   ```python
   def get_db_connection():
       return mysql.connector.connect(
           host="localhost",
           user="your_username",
           password="your_password",
           database="timetable_db"
       )
   ```

2. **Update Flask Secret Key**
   
   Edit `app.py` and change the secret key:
   ```python
   app.secret_key = 'your-secret-key-change-in-production'
   ```

## Step 4: Create Export Directory

```bash
mkdir exports
```

This directory will store exported files (PDF, Excel, CSV, iCal).

## Step 5: Run the Application

```bash
python app.py
```

The application will start on `http://localhost:5000`

## Step 6: Initial Login

Use the default credentials from your sample data, or create a new admin user:

```sql
INSERT INTO users (username, password, role) 
VALUES ('admin', '$2b$12$hashed_password', 'admin');
```

**Note**: Use `hash_passwords.py` to generate bcrypt hashes for passwords.

## Step 7: First Time Setup

1. **Login** as admin or coordinator
2. **Add Teachers** - Go to Teachers section
3. **Add Rooms** - Go to Rooms section
4. **Add Subjects** - Go to Subjects section
5. **Add Programs & Sections** - Go to Classes section
6. **Create Subject Assignments** - Go to Subject Assignments section
7. **Generate Timeslot Structure** - Go to Timeslots section
8. **Generate Timetable** - Go to Generate Timetable section

## Troubleshooting

### Database Connection Issues
- Verify MySQL is running
- Check credentials in `db_config.py`
- Ensure database exists

### Import Errors
- Make sure all dependencies are installed: `pip install -r requirements.txt`
- Check Python version: `python --version` (should be 3.8+)

### Export Errors
- Ensure `exports` directory exists and is writable
- For PDF export, ensure `reportlab` is installed
- For Excel export, ensure `openpyxl` is installed

### Port Already in Use
- Change port in `app.py`: `app.run(debug=True, port=5001)`

## Production Deployment

1. **Disable Debug Mode**
   ```python
   app.run(debug=False)
   ```

2. **Use Production WSGI Server**
   ```bash
   pip install gunicorn
   gunicorn -w 4 -b 0.0.0.0:5000 app:app
   ```

3. **Set Up Reverse Proxy** (Nginx recommended)

4. **Use Environment Variables** for sensitive data:
   ```python
   import os
   app.secret_key = os.environ.get('SECRET_KEY')
   ```

5. **Enable HTTPS** for secure connections

6. **Set Up Database Backups**

## File Structure

```
Time Table/
├── app.py                 # Main Flask application
├── db_config.py           # Database configuration
├── generator.py           # Basic timetable generator
├── test_generator.py       # Advanced timetable generator
├── conflict_detector.py    # Conflict detection system
├── export_manager.py       # Export functionality
├── quality_metrics.py      # Quality metrics calculator
├── create_database.sql     # Base database schema
├── database_updates.sql    # Additional schema for new features
├── requirements.txt        # Python dependencies
├── static/
│   ├── css/
│   │   └── styles.css      # All styles
│   ├── js/
│   │   ├── script.js       # Main JavaScript
│   │   └── advanced_features.js  # Advanced features JS
│   └── index.html         # Main HTML
└── exports/               # Export files directory
```

## Next Steps

1. Review `FEATURES.md` for complete feature list
2. Customize the system for your institution
3. Add your data (teachers, rooms, subjects, etc.)
4. Generate your first timetable!




