# Timetable Generation Fixes

## Issues Fixed

### 1. **Teacher Availability Too Strict** ✅ FIXED

**Problem:**
- If `teacher_availability` table was empty or missing records, all teachers were considered unavailable
- This made it impossible to schedule any lectures

**Solution:**
- Made teacher availability **optional**
- If no availability records exist for a teacher, assume they are available
- Only enforce availability if records exist

**Code Change:**
```python
def is_teacher_free_at_time(self, teacher_id, timeslot):
    # If no teacher availability records exist, assume teacher is available
    if not self.teacher_availability:
        return True
    
    # If teacher has no availability records, assume available
    teacher_avail_records = [a for a in self.teacher_availability if a['teacher_id'] == teacher_id]
    if not teacher_avail_records:
        return True
    
    # Only check availability if records exist
    ...
```

---

### 2. **Timeslot Query Too Restrictive** ✅ FIXED

**Problem:**
- Query might miss timeslots if `is_active` field exists but isn't handled
- Only checked `session_type_id IS NULL`

**Solution:**
- Updated query to also check `is_active` field
- Handles cases where `is_active` might be NULL or FALSE

**Code Change:**
```sql
SELECT * FROM timeslots
WHERE (session_type_id IS NULL OR session_type_id = 0)
AND (is_active IS NULL OR is_active = TRUE)
ORDER BY day_of_week, start_time
```

---

### 3. **Missing Teacher Availability Table** ✅ FIXED

**Problem:**
- If `teacher_availability` table doesn't exist, query would fail

**Solution:**
- Added try-except block to handle missing table gracefully
- If table doesn't exist, assume all teachers are available

**Code Change:**
```python
try:
    cursor.execute('SELECT * FROM teacher_availability')
    self.teacher_availability = cursor.fetchall()
except Exception:
    # If table doesn't exist, assume all teachers are available
    self.teacher_availability = []
```

---

### 4. **Better Error Messages** ✅ IMPROVED

**Problem:**
- Generic error messages didn't help diagnose issues
- No diagnostics provided

**Solution:**
- Added detailed error messages with specific information
- Include diagnostics in error responses
- Validate constraints before attempting generation

**New Error Messages:**
- "No timeslots defined. Please create timeslots first. Note: Break/lunch timeslots (with session_type_id) are excluded from scheduling."
- "Not enough days available. Some subjects need X different days (one subject per day constraint), but only Y day(s) have timeslots defined."
- Detailed diagnostics with counts of lectures, timeslots, rooms, days, subjects, sections

---

### 5. **One-Subject-Per-Day Validation** ✅ ADDED

**Problem:**
- No validation to check if enough days exist for the constraint
- Could fail silently if constraint is impossible

**Solution:**
- Pre-validate that enough days exist for one-subject-per-day constraint
- Calculate minimum days needed based on hours per week
- Provide clear error if constraint is impossible

**Validation:**
```python
# Calculate minimum days needed
subject_days_needed = {}
for assignment in self.assignments:
    key = (assignment['section_id'], assignment['subject_id'])
    subject_days_needed[key] = max(subject_days_needed.get(key, 0), assignment['hours_per_week'])

max_days_needed = max(subject_days_needed.values()) if subject_days_needed else 0
unique_days = len(set(t['day_of_week'] for t in self.timeslots))

if max_days_needed > unique_days:
    return error...
```

---

### 6. **Increased Attempts** ✅ IMPROVED

**Problem:**
- Only 3 attempts might not be enough for complex schedules

**Solution:**
- Increased to 5 attempts
- Better random seed generation
- Clear solution on each retry

---

### 7. **Better Random Seed** ✅ IMPROVED

**Problem:**
- Random seed might not be different enough between attempts

**Solution:**
- Use timestamp in milliseconds + attempt number
- Ensures different random sequences each attempt

**Code Change:**
```python
random.seed(int(time.time() * 1000) + attempt)
```

---

## How to Use

### Before Generating Timetable:

1. **Create Timeslots:**
   - Make sure you have timeslots defined
   - Break/lunch timeslots (with `session_type_id`) are automatically excluded
   - You need at least as many days as the maximum hours per week for any subject

2. **Create Rooms:**
   - Make sure rooms have sufficient capacity
   - Room types should match subject requirements (if specified)

3. **Create Subject Assignments:**
   - Assign teachers to subjects for sections
   - Set `hours_per_week` for each assignment

4. **Teacher Availability (Optional):**
   - If you want to restrict when teachers are available, add records to `teacher_availability` table
   - If you don't add any records, all teachers are assumed available

### Example Error Messages:

**If no timeslots:**
```
"No timeslots defined. Please create timeslots first. Note: Break/lunch timeslots (with session_type_id) are excluded from scheduling."
```

**If not enough days:**
```
"Not enough days available. Some subjects need 5 different days (one subject per day constraint), but only 3 day(s) have timeslots defined."
```

**If generation fails:**
```
"No valid timetable could be generated after 5 attempts. Diagnostics: 20 lectures to schedule, 15 timeslots, 5 rooms, 5 unique days, 8 subjects, 3 sections. Possible issues: (1) One-subject-per-day constraint may be too strict for available days, (2) Teacher availability conflicts, (3) Room capacity/type constraints, or (4) Insufficient timeslots for the number of lectures."
```

---

## Testing Checklist

- [x] Teacher availability is optional
- [x] Timeslot query handles is_active field
- [x] Missing teacher_availability table handled gracefully
- [x] Better error messages with diagnostics
- [x] One-subject-per-day validation
- [x] Increased attempts (5 instead of 3)
- [x] Better random seed generation
- [x] Solution cleared on retry

---

## Common Issues and Solutions

### Issue: "No timeslots defined"
**Solution:** Create timeslots using the timeslot management interface. Make sure they don't have `session_type_id` set (unless you want them excluded).

### Issue: "Not enough days available"
**Solution:** 
- Add more days with timeslots (e.g., add Saturday if needed)
- OR reduce hours per week for subjects that need many days
- Remember: one subject per day constraint means a subject with 5 hours/week needs 5 different days

### Issue: "No valid timetable could be generated"
**Solution:**
- Check room capacities match class sizes
- Check room types match subject requirements
- Check teacher availability (if set)
- Reduce number of lectures or add more timeslots/rooms
- Consider if one-subject-per-day constraint is too strict

---

## Summary

The timetable generator is now more robust and provides better feedback when issues occur. The main improvements are:

1. ✅ Teacher availability is optional (won't block generation)
2. ✅ Better timeslot query handling
3. ✅ Graceful handling of missing tables
4. ✅ Detailed error messages with diagnostics
5. ✅ Pre-validation of constraints
6. ✅ More attempts with better randomization

The generator should now work in most scenarios and provide helpful feedback when it can't generate a timetable.



