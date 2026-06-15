# Timetable Generation Algorithm Analysis

## Overview

The timetable generation system uses a **Backtracking Algorithm with Constraint Satisfaction Problem (CSP)** approach. The implementation is found in `test_generator.py` with the `AdvancedTimetableGenerator` class.

**Last Updated:** Improved version with enhanced constraints and optimizations.

## Key Features

✅ **One Subject Per Day Constraint** - Each subject is taught only once per day per section  
✅ **Smart Heuristics** - Difficulty-based sorting and preference-based placement  
✅ **Progress Tracking** - Monitors backtracking and placement attempts  
✅ **Multiple Attempts** - Retries with different random seeds if first attempt fails  
✅ **Better Error Messages** - Provides detailed diagnostics when generation fails

---

## Algorithm Type

**Backtracking with Constraint Satisfaction Problem (CSP)**
- A recursive depth-first search algorithm
- Uses constraint checking to validate placements
- Implements backtracking when no valid solution is found
- Includes heuristic optimizations for better performance

---

## Algorithm Flow

### Phase 1: Data Loading (`load_data()`)

The algorithm first loads all necessary data from the database:

1. **Teachers** - All available teachers
2. **Rooms** - All available rooms with capacity and type
3. **Subjects** - All subjects with their requirements
4. **Sections/Groups** - All class sections with sizes
5. **Subject Assignments** - Teacher-subject-section assignments with hours per week
6. **Timeslots** - Available time slots (excluding breaks/lunch)
7. **Teacher Availability** - When teachers are available

**Key Query:**
```sql
SELECT sa.*, t.name as teacher_name, s.name as subject_name,
       sec.section_name as group_name, sec.size as group_size,
       p.name as program_name, sec.year, s.requires_room_type
FROM subject_assignments sa
JOIN teachers t ON sa.teacher_id = t.teacher_id
JOIN subjects s ON sa.subject_id = s.subject_id
JOIN sections sec ON sa.section_id = sec.section_id
JOIN programs p ON sec.program_id = p.program_id
```

---

### Phase 2: Master Lecture List Creation (`create_master_lecture_list()`)

Converts subject assignments into individual lecture instances:

- For each assignment with `hours_per_week = N`, creates N `Lecture` objects
- Each lecture represents one class session that needs to be scheduled
- Example: If "Mathematics" is assigned 3 hours/week, creates 3 lecture objects

**Pseudocode:**
```
FOR each assignment:
    FOR i = 1 to hours_per_week:
        CREATE Lecture(assignment)
        ADD to master_lecture_list
```

---

### Phase 3: Schedule Initialization (`initialize_hash_maps()`)

Creates hash maps to track availability:

1. **`teacher_schedule`** - `{teacher_id: {timeslot_id: "FREE"/"BUSY"}}`
2. **`section_schedule`** - `{section_id: {timeslot_id: "FREE"/"BUSY"}}`
3. **`room_schedule`** - `{room_id: {timeslot_id: "FREE"/"BUSY"}}`
4. **`section_subject_day`** - `{(section_id, day_of_week): set of subject_ids}` ⭐ **NEW**

All slots are initially marked as "FREE". The `section_subject_day` map tracks which subjects have already been scheduled for each section on each day to enforce the "one subject per day" constraint.

---

### Phase 4: Difficulty-Based Sorting (`sort_lectures_by_difficulty()`)

**Heuristic Optimization:** Sorts lectures by difficulty score (hardest first)

The `difficulty_score()` function calculates:
1. **Room Type Constraint** (0-100 points)
   - If lecture requires specific room type (e.g., "Lab")
   - Score = 10 / number of suitable rooms
   - Higher score = fewer suitable rooms = harder to schedule

2. **Section Size Constraint** (0-100 points)
   - Score = 10 / number of rooms with sufficient capacity
   - Larger classes = fewer suitable rooms = harder

3. **Teacher Availability** (0-100 points)
   - Score = 10 / number of available time slots for teacher
   - Less available teachers = harder to schedule

4. **Remaining Hours** ⭐ **NEW**
   - Score += remaining_hours × 5
   - Subjects with more remaining hours get slightly higher priority
   - Helps distribute subjects evenly across the week

**Why this helps:**
- Schedule difficult lectures first when more options are available
- Reduces backtracking by handling constraints early
- Improves success rate and performance
- Better distribution of subjects across days

---

### Phase 5: Backtracking Solution (`solve(lecture_index)`)

This is the core recursive backtracking algorithm:

#### Algorithm Structure:

```
solve(lecture_index):
    IF lecture_index == total_lectures:
        RETURN True  // All lectures placed successfully
    
    current_lecture = master_lecture_list[lecture_index]
    
    // Shuffle for randomness (avoids same solution every time)
    shuffled_timeslots = shuffle(timeslots)
    shuffled_rooms = shuffle(rooms)
    
    FOR each timeslot in shuffled_timeslots:
        FOR each room in shuffled_rooms:
            IF is_valid(current_lecture, timeslot, room):
                place_lecture(lecture_index, timeslot, room)
                
                IF solve(lecture_index + 1):  // Recurse
                    RETURN True  // Found solution
                
                unplace_lecture(lecture_index, timeslot, room)  // Backtrack
    
    RETURN False  // No valid placement found
```

#### Key Features:

1. **Recursive Depth-First Search**
   - Tries to place all lectures recursively
   - Goes deep before backtracking

2. **Randomization**
   - Shuffles timeslots and rooms to avoid deterministic solutions
   - Each run may produce different valid timetables

3. **Backtracking**
   - If a placement leads to dead-end, unplaces and tries next option
   - Systematically explores all possibilities

---

### Phase 6: Constraint Validation (`is_valid()`)

Before placing a lecture, checks all hard constraints:

#### Hard Constraints (Must Pass):

1. **Teacher Conflict Check**
   ```python
   if teacher_schedule[teacher_id][timeslot_id] == "BUSY":
       return False
   ```
   - Teacher cannot be in two places at once

2. **Section Conflict Check**
   ```python
   if section_schedule[section_id][timeslot_id] == "BUSY":
       return False
   ```
   - Section cannot have two classes simultaneously

3. **Room Conflict Check**
   ```python
   if room_schedule[room_id][timeslot_id] == "BUSY":
       return False
   ```
   - Room cannot be double-booked

4. **Teacher Availability Check**
   ```python
   if not is_teacher_free_at_time(teacher_id, timeslot):
       return False
   ```
   - Teacher must be available during the timeslot
   - Checks `teacher_availability` table

5. **Room Capacity Check**
   ```python
   if room['capacity'] < lecture.group_size:
       return False
   ```
   - Room must accommodate class size

6. **Room Type Check**
   ```python
   if lecture.requires_room_type and 
      lecture.requires_room_type != room['type']:
       return False
   ```
   - Room type must match subject requirements (e.g., Lab for lab classes)

7. **One Subject Per Day Constraint** ⭐ **NEW**
   ```python
   key = (lecture.section_id, day)
   if key in section_subject_day and 
      lecture.subject_id in section_subject_day[key]:
       return False
   ```
   - **Each subject can only be taught once per day per section**
   - Prevents duplicate subjects on the same day
   - Ensures better subject distribution across the week

**All constraints must pass for a valid placement.**

---

### Phase 7: Placement Operations

#### `place_lecture(lecture_index, timeslot, room)`
- Marks teacher as BUSY at timeslot
- Marks section as BUSY at timeslot
- Marks room as BUSY at timeslot
- ⭐ **NEW:** Adds subject_id to `section_subject_day[(section_id, day)]` set
- Stores solution: `solution[lecture_index] = (timeslot_id, room_id)`

#### `unplace_lecture(lecture_index, timeslot, room)`
- Marks teacher as FREE at timeslot
- Marks section as FREE at timeslot
- Marks room as FREE at timeslot
- ⭐ **NEW:** Removes subject_id from `section_subject_day[(section_id, day)]` set
- Removes from solution dictionary
- Increments backtrack counter for progress tracking

---

### Phase 8: Solution Formatting (`format_timetable()`)

Converts the internal solution representation to a structured format:

```
{
    "Monday": {
        "09:00:00-10:00:00": {
            "Room A": {
                "teacher": "Dr. Smith",
                "subject": "Mathematics",
                "group": "CS-101",
                "room_type": "Lecture"
            }
        }
    },
    ...
}
```

---

### Phase 9: Database Persistence (`save_timetable()`)

1. Clears existing timetable: `DELETE FROM timetable_slots`
2. Inserts new timetable entries:
   ```sql
   INSERT INTO timetable_slots
   (timeslot_id, room_id, teacher_id, subject_id, section_id)
   VALUES (%s, %s, %s, %s, %s)
   ```

---

## Algorithm Characteristics

### Time Complexity

- **Worst Case:** O(b^d) where:
  - `b` = branching factor (timeslots × rooms)
  - `d` = depth (number of lectures)
- **Best Case:** O(d) if first path is valid
- **Average Case:** Depends on constraint density

### Space Complexity

- O(n × m) where:
  - `n` = number of entities (teachers/sections/rooms)
  - `m` = number of timeslots
- Stores schedule state for all entities

### Success Factors

1. **Constraint Density:** More constraints = harder to solve
2. **Resource Availability:** More timeslots/rooms = easier
3. **Lecture Ordering:** Difficulty-based sorting helps significantly
4. **Randomization:** Helps find solutions when multiple exist

---

## Strengths

1. ✅ **Guaranteed Constraint Satisfaction**
   - All hard constraints are enforced
   - No conflicts in final solution
   - ⭐ **NEW:** One subject per day constraint enforced

2. ✅ **Complete Search**
   - Explores all possibilities
   - Will find solution if one exists
   - ⭐ **NEW:** Multiple attempts with different random seeds

3. ✅ **Heuristic Optimization**
   - Difficulty-based sorting improves efficiency
   - Reduces backtracking
   - ⭐ **NEW:** Smart timeslot and room prioritization

4. ✅ **Flexible**
   - Handles various constraints
   - Works with different data sizes

5. ✅ **Progress Tracking** ⭐ **NEW**
   - Monitors backtrack count
   - Tracks placement attempts
   - Provides generation statistics

6. ✅ **Better Error Handling** ⭐ **NEW**
   - Validates input before solving
   - Provides detailed error messages
   - Includes statistics in response

---

## Limitations

1. ⚠️ **Exponential Time Complexity**
   - Can be slow for large problems
   - May timeout with many lectures
   - ⭐ **IMPROVED:** Backtrack limit prevents infinite loops

2. ⚠️ **No Soft Constraints**
   - Only enforces hard constraints
   - Doesn't optimize for preferences
   - ⭐ **IMPROVED:** Better heuristics help with preferences

3. ⚠️ **No Partial Solutions**
   - Either finds complete solution or fails
   - No graceful degradation
   - ⭐ **IMPROVED:** Multiple attempts increase success rate

4. ⚠️ **Limited Conflict Reporting**
   - ⭐ **IMPROVED:** Better error messages with statistics
   - Still doesn't explain specific constraint violations

5. ⚠️ **Single Solution**
   - Returns first valid solution found
   - Doesn't compare multiple solutions
   - ⭐ **IMPROVED:** Multiple attempts may find different solutions

---

## Recent Improvements ⭐

### 1. **One Subject Per Day Constraint** ✅ IMPLEMENTED
- Each subject can only be scheduled once per day per section
- Prevents duplicate subjects on same day
- Better subject distribution across week

### 2. **Smart Prioritization** ✅ IMPLEMENTED
- Timeslots prioritized by subject conflict avoidance
- Rooms prioritized by capacity match and type suitability
- Reduces backtracking significantly

### 3. **Progress Tracking** ✅ IMPLEMENTED
- Monitors backtrack count
- Tracks placement attempts
- Provides generation statistics

### 4. **Multiple Attempts** ✅ IMPLEMENTED
- Retries with different random seeds
- Increases success rate
- Prevents getting stuck in local minima

### 5. **Better Error Handling** ✅ IMPLEMENTED
- Validates input before solving
- Provides detailed error messages
- Includes statistics in response

## Future Optimization Opportunities

### 1. **Constraint Propagation**
- Forward checking: eliminate invalid options early
- Arc consistency: maintain constraint consistency

### 2. **Soft Constraints**
- Add preference scoring
- Optimize for teacher preferences
- Balance workload distribution

### 3. **Incremental Generation**
- Allow partial solutions
- Fill remaining slots manually
- Suggest alternatives when stuck

### 4. **Alternative Algorithms**
- **Genetic Algorithm:** For large-scale problems
- **Simulated Annealing:** For optimization
- **Graph Coloring:** For conflict-free scheduling

### 5. **Parallel Processing**
- Try multiple branches simultaneously
- Use multiprocessing for large datasets

### 6. **Caching & Memoization**
- Cache constraint checks
- Remember failed sub-problems

---

## Example Execution Flow

```
1. Load Data:
   - 10 teachers, 15 rooms, 20 timeslots
   - 50 subject assignments (150 total lectures)

2. Create Master List:
   - 150 Lecture objects created

3. Initialize Schedules:
   - 10 teachers × 20 timeslots = 200 entries
   - 20 sections × 20 timeslots = 400 entries
   - 15 rooms × 20 timeslots = 300 entries

4. Sort by Difficulty:
   - Lab classes (few suitable rooms) first
   - Large classes (few suitable rooms) first
   - Less available teachers first

5. Solve:
   - Try placing Lecture 0 (hardest) in timeslot 1, room 1
   - Check constraints → Valid → Place
   - Recurse to Lecture 1
   - Continue until all placed or backtrack needed

6. Result:
   - Solution found with 150 lectures scheduled
   - All constraints satisfied
   - Saved to database
```

---

## Comparison with Other Approaches

| Feature | Backtracking (Current) | Genetic Algorithm | Simulated Annealing |
|---------|----------------------|-------------------|---------------------|
| Guarantees | Finds solution if exists | No guarantee | No guarantee |
| Speed | Medium | Fast | Fast |
| Quality | First valid | Optimized | Optimized |
| Constraints | Hard only | Hard + Soft | Hard + Soft |
| Scalability | Limited | Good | Good |

---

## Recommendations

1. **For Small-Medium Problems (< 200 lectures):**
   - Current algorithm works well
   - Add soft constraint scoring
   - Add progress reporting

2. **For Large Problems (> 200 lectures):**
   - Consider hybrid approach
   - Use genetic algorithm or simulated annealing
   - Implement incremental generation

3. **Improvements to Add:**
   - Conflict detection and reporting
   - Quality metrics calculation
   - Multiple solution generation
   - User preference integration
   - Performance monitoring

---

## Conclusion

The current algorithm is a **solid backtracking CSP solver** with good constraint handling and heuristic optimizations. It works well for medium-sized problems but may struggle with very large datasets. The difficulty-based sorting is a smart optimization that significantly improves performance.

**Key Takeaway:** The algorithm prioritizes correctness (all constraints satisfied) over optimization (preferences/quality), which is appropriate for a timetable generator where constraint violations are unacceptable.

