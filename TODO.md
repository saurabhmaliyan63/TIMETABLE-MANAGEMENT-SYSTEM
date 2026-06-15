# Subject-Class Assignments on Manage Subjects Page
Status: PLANNING

## Steps:
### 1. DB Migration ✅ [COMPLETED]
- Created subject_sections table
- Populated from subject_assignments
- Create subject_sections table: subject_id, section_id (FKs)
- Migrate existing data from subject_assignments
- Add indexes

### 2. Backend API ✅ [PARTIAL]\n- Updated /api/subjects GET: Shows assigned_classes column
- Update /api/subjects: JOIN subject_sections → assigned_classes array
- New endpoints: /api/subjects/<id>/classes POST/PUT/DELETE

### 3. Frontend Subjects Page ⚠️ [PARTIAL - Needs Edit Form Upgrade]
- index.html #subjects table: Add 'Assigned Classes' column
- script.js loadSubjects(): Show comma-separated classes
- Edit modal: Multi-select classes checkbox

### 4. Testing [PENDING]
- Verify subjects page shows class assignments
- Test add/edit/remove classes per subject
- Check subject_assignments sync (if needed)

**Next: Create/run DB migration**
