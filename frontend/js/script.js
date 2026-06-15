// Global variables
let currentSection = 'dashboard';

// Initialize the application
document.addEventListener('DOMContentLoaded', function () {
    checkAuthentication();
    loadDashboardStats();
    showSection('dashboard');

    // Add click handlers for stat cards
    document.querySelectorAll('.stat-card').forEach(card => {
        card.addEventListener('click', function () {
            const cardType = this.querySelector('h3').textContent.toLowerCase();
            if (cardType.includes('teachers')) {
                showSection('teachers');
            } else if (cardType.includes('rooms')) {
                showSection('rooms');
            } else if (cardType.includes('subjects')) {
                showSection('subjects');
            } else if (cardType.includes('sections')) {
                showSection('groups');
            }
        });
    });

    // Initialize search functionality
    initializeSearch();
});

// Check if user is authenticated and set up role-based UI
function checkAuthentication() {
    fetch('/api/check-session')
        .then(response => response.json())
        .then(data => {
            if (data.authenticated) {
                setupRoleBasedUI(data.role);
            } else {
                window.location.href = '/login';
            }
        })
        .catch(error => {
            console.error('Session check failed:', error);
            window.location.href = '/login';
        });
}

// Setup UI based on user role
function setupRoleBasedUI(role) {
    // Store current role globally so other functions (like timetable/export) can adapt
    window.currentUserRole = role;
    const userRoleElement = document.getElementById('user-role');
    userRoleElement.textContent = `${role.charAt(0).toUpperCase() + role.slice(1)} Dashboard`;

    // Role-based menu visibility
    const rolePermissions = {
        admin: ['teachers-menu', 'rooms-menu', 'subjects-menu', 'groups-menu', 'assignments-menu', 'session-types-menu', 'timeslots-menu', 'generate-menu', 'view-timetable-menu', 'conflicts-menu', 'statistics-menu', 'preferences-menu', 'notifications-menu'],
        coordinator: ['teachers-menu', 'rooms-menu', 'subjects-menu', 'groups-menu', 'assignments-menu', 'session-types-menu', 'timeslots-menu', 'generate-menu', 'view-timetable-menu', 'conflicts-menu', 'statistics-menu', 'preferences-menu', 'notifications-menu'],
        teacher: ['view-timetable-menu', 'preferences-menu', 'notifications-menu'], // Teachers can view timetable, set preferences, see notifications
        student: ['view-timetable-menu', 'notifications-menu']  // Students can view timetable and notifications
    };

    // Hide menu items not allowed for this role
    const allowedMenus = rolePermissions[role] || [];
    const allMenus = ['teachers-menu', 'rooms-menu', 'subjects-menu', 'groups-menu', 'assignments-menu', 'session-types-menu', 'timeslots-menu', 'generate-menu', 'view-timetable-menu', 'conflicts-menu', 'statistics-menu', 'preferences-menu', 'notifications-menu'];

    allMenus.forEach(menuId => {
        const menuItem = document.getElementById(menuId);
        if (menuItem) {
            if (allowedMenus.includes(menuId)) {
                menuItem.style.display = 'block';
            } else {
                menuItem.style.display = 'none';
            }
        }
    });

    // For teachers and students, redirect to timetable view
    if (role === 'teacher' || role === 'student') {
        showSection('view-timetable');
    }
}

// Initialize search functionality
function initializeSearch() {
    document.querySelectorAll('.search-input').forEach(input => {
        input.addEventListener('input', function () {
            const tableId = this.getAttribute('data-table');
            const searchTerm = this.value.toLowerCase();
            filterTable(tableId, searchTerm);
        });
    });
}

// Filter table rows based on search term
function filterTable(tableId, searchTerm) {
    const table = document.getElementById(tableId);
    const tbody = table.querySelector('tbody');
    const rows = tbody.querySelectorAll('tr');

    rows.forEach(row => {
        const cells = row.querySelectorAll('td');
        let match = false;

        cells.forEach(cell => {
            if (cell.textContent.toLowerCase().includes(searchTerm)) {
                match = true;
            }
        });

        row.style.display = match ? '' : 'none';
    });
}

// Sort table function
function sortTable(tableId, columnIndex) {
    const table = document.getElementById(tableId);
    const tbody = table.querySelector('tbody');
    const rows = Array.from(tbody.querySelectorAll('tr'));

    // Get current sort direction
    const header = table.querySelector(`th:nth-child(${columnIndex + 1})`);
    const currentDirection = header.getAttribute('data-sort') || 'asc';
    const newDirection = currentDirection === 'asc' ? 'desc' : 'asc';

    // Clear sort indicators
    table.querySelectorAll('th').forEach(th => {
        th.removeAttribute('data-sort');
        const indicator = th.querySelector('.sort-indicator');
        if (indicator) indicator.textContent = '';
    });

    // Set new sort direction
    header.setAttribute('data-sort', newDirection);
    const indicator = header.querySelector('.sort-indicator');
    if (indicator) {
        indicator.textContent = newDirection === 'asc' ? ' ▲' : ' ▼';
    }

    // Sort rows
    rows.sort((a, b) => {
        const aValue = a.cells[columnIndex].textContent.trim();
        const bValue = b.cells[columnIndex].textContent.trim();

        // Try to parse as numbers
        const aNum = parseFloat(aValue);
        const bNum = parseFloat(bValue);

        let comparison = 0;
        if (!isNaN(aNum) && !isNaN(bNum)) {
            comparison = aNum - bNum;
        } else {
            comparison = aValue.localeCompare(bValue);
        }

        return newDirection === 'asc' ? comparison : -comparison;
    });

    // Re-append sorted rows
    rows.forEach(row => tbody.appendChild(row));
}

// Navigation functions
function showSection(sectionName) {
    // Hide all sections
    document.querySelectorAll('.content-section').forEach(section => {
        section.classList.remove('active');
    });

    // Remove active class from sidebar links
    document.querySelectorAll('.sidebar-menu a').forEach(link => {
        link.classList.remove('active');
    });

    // Show selected section
    document.getElementById(sectionName).classList.add('active');

    // Add active class to corresponding sidebar link
    const sidebarLink = document.querySelector(`.sidebar-menu a[onclick*="${sectionName}"]`);
    if (sidebarLink) {
        sidebarLink.classList.add('active');
    }

    currentSection = sectionName;

    // Load data for the section
    switch (sectionName) {
        case 'teachers':
            loadTeachers();
            break;
        case 'rooms':
            loadRooms();
            break;
        case 'subjects':
            loadSubjects();
            break;
        case 'groups':
            loadGroups();
            break;
        case 'session-types':
            loadSessionTypes();
            break;
        case 'assignments':
            setupAssignmentsPage();
            break;
        case 'timeslots':
            loadTimeslots();
            break;
        case 'generate':
            loadGenerationStats();
            break;
        case 'view-timetable':
            loadSectionsForDropdown();
            loadTimetable();
            break;
        case 'conflicts':
            loadConflicts();
            break;
        case 'statistics':
            loadStatistics();
            break;
        case 'preferences':
            loadTeachersForPreferences();
            break;
        case 'notifications':
            loadNotifications();
            break;
    }
}

// Helper function for statistics tabs
function showStatTab(tabName) {
    // Hide all tab contents
    document.querySelectorAll('.stat-tab-content').forEach(content => {
        content.classList.remove('active');
    });

    // Remove active from all tabs
    document.querySelectorAll('.stat-tab').forEach(tab => {
        tab.classList.remove('active');
    });

    // Show selected tab content
    const content = document.getElementById(`${tabName}-stats-container`) ||
        document.getElementById(`${tabName}-utilization-container`) ||
        document.getElementById(`${tabName}-metrics-container`);
    if (content) {
        content.classList.add('active');
    }

    // Activate tab button
    event.target.classList.add('active');

    // Load data if needed
    if (tabName === 'workload') {
        loadWorkloadStatistics();
    } else if (tabName === 'utilization') {
        loadRoomUtilization();
    } else if (tabName === 'quality') {
        loadQualityMetrics();
    }
}

// Load teachers for preferences dropdown
async function loadTeachersForPreferences() {
    try {
        const response = await fetch('/api/teachers');
        const teachers = await response.json();
        const select = document.getElementById('teacher-pref-select');
        select.innerHTML = '<option value="">Select a teacher</option>';
        teachers.forEach(teacher => {
            const option = document.createElement('option');
            option.value = teacher.teacher_id;
            option.textContent = teacher.name;
            select.appendChild(option);
        });
    } catch (error) {
        console.error('Error loading teachers:', error);
    }
}

// Show add preference form
function showAddPreferenceForm() {
    showModal('Add Teacher Preference', 'teacher-preference');
}

// Dashboard functions
async function loadDashboardStats() {
    try {
        const [teachers, rooms, subjects, groups] = await Promise.all([
            fetch('/api/teachers').then(r => r.json()),
            fetch('/api/rooms').then(r => r.json()),
            fetch('/api/subjects').then(r => r.json()),
            fetch('/api/sections').then(r => r.json())
        ]);

        document.getElementById('teacher-count').textContent = teachers.length;
        document.getElementById('room-count').textContent = rooms.length;
        document.getElementById('subject-count').textContent = subjects.length;
        document.getElementById('group-count').textContent = groups.length;
    } catch (error) {
        console.error('Error loading dashboard stats:', error);
    }
}

// Teachers functions
async function loadTeachers() {
    try {
        const response = await fetch('/api/teachers');
        const teachers = await response.json();
        displayTeachers(teachers);
    } catch (error) {
        console.error('Error loading teachers:', error);
    }
}

function displayTeachers(teachers) {
    const tbody = document.querySelector('#teachers-table tbody');
    tbody.innerHTML = '';

    teachers.forEach(teacher => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${teacher.teacher_id}</td>
            <td>${teacher.name}</td>
            <td>${teacher.email}</td>
            <td>
                <button onclick="editTeacher(${teacher.teacher_id})" class="btn-secondary">Edit</button>
                <button onclick="deleteTeacher(${teacher.teacher_id})" class="btn-danger">Delete</button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// Rooms functions
async function loadRooms() {
    try {
        const response = await fetch('/api/rooms');
        const rooms = await response.json();
        displayRooms(rooms);
    } catch (error) {
        console.error('Error loading rooms:', error);
    }
}

function displayRooms(rooms) {
    const tbody = document.querySelector('#rooms-table tbody');
    tbody.innerHTML = '';

    rooms.forEach(room => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${room.room_id}</td>
            <td>${room.name}</td>
            <td>${room.capacity}</td>
            <td>${room.type}</td>
            <td>
                <button onclick="editRoom(${room.room_id})" class="btn-secondary">Edit</button>
                <button onclick="deleteRoom(${room.room_id})" class="btn-danger">Delete</button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// Subjects functions
async function loadSubjects() {
    try {
        const response = await fetch('/api/subjects');
        const subjects = await response.json();
        displaySubjects(subjects);
    } catch (error) {
        console.error('Error loading subjects:', error);
    }
}

function displaySubjects(subjects) {
    const tbody = document.querySelector('#subjects-table tbody');
    tbody.innerHTML = '';

    subjects.forEach(subject => {
        const row = document.createElement('tr');
        row.innerHTML = `\n            <td>${subject.subject_id}</td>\n            <td>${subject.name}</td>\n            <td>${subject.requires_room_type || 'Any'}</td>\n            <td>${subject.assigned_classes || 'None'}</td>\n            <td>\n                <button onclick="editSubject(${subject.subject_id})" class="btn-secondary">Edit</button>\n                <button onclick="deleteSubject(${subject.subject_id})" class="btn-danger">Delete</button>\n            </td>\n        `;
        tbody.appendChild(row);
    });
}

// Sections functions
async function loadGroups() {
    try {
        const response = await fetch('/api/sections');
        const groups = await response.json();
        displayGroups(groups);
    } catch (error) {
        console.error('Error loading groups:', error);
    }
}

function displayGroups(groups) {
    const tbody = document.querySelector('#groups-table tbody');
    tbody.innerHTML = '';

    groups.forEach(group => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${group.section_id}</td>
            <td>${group.program_name}</td>
            <td>${group.section_name || '-'}</td>
            <td>${group.year}</td>
            <td>${group.size}</td>
            <td>
                <button onclick="editGroup(${group.section_id})" class="btn-secondary">Edit</button>
                <button onclick="deleteGroup(${group.section_id})" class="btn-danger">Delete</button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// Session Types functions
async function loadSessionTypes() {
    try {
        const response = await fetch('/api/session_types');
        const sessionTypes = await response.json();
        if (!response.ok) {
            throw new Error(sessionTypes.error || `Failed to load session types. Status: ${response.status}`);
        }
        displaySessionTypes(sessionTypes);
    } catch (error) {
        console.error('Error loading session types:', error);
        showToast(error.message, 'error');
        // Clear the table on error to avoid showing stale data
        displaySessionTypes([]);
    }
}

function displaySessionTypes(sessionTypes) {
    const tbody = document.querySelector('#session-types-table tbody');
    if (!tbody) return;
    tbody.innerHTML = '';

    if (!Array.isArray(sessionTypes) || sessionTypes.length === 0) {
        const row = document.createElement('tr');
        const cell = document.createElement('td');
        cell.colSpan = 5; // Number of columns in the session types table
        cell.textContent = 'No session types found. Click "Add New" to create one.';
        cell.className = 'no-data';
        row.appendChild(cell);
        tbody.appendChild(row);
        return;
    }

    sessionTypes.forEach(type => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${type.session_type_id}</td>
            <td>${type.name}</td>
            <td>${type.description || '-'}</td>
            <td><span style="display:inline-block;width:20px;height:20px;background-color:${type.color};border:1px solid #ccc;"></span> ${type.color}</td>
            <td>
                <button onclick="editSessionType(${type.session_type_id})" class="btn-secondary">Edit</button>
                <button onclick="deleteSessionType(${type.session_type_id})" class="btn-danger">Delete</button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

async function saveSessionType() {
    const name = document.getElementById('st-name').value.trim();
    const description = document.getElementById('st-description').value.trim();
    const color = document.getElementById('st-color').value;

    if (!name) {
        showToast('Name is required', 'warning');
        return;
    }

    const data = { name, description, color };
    const method = currentEditId ? 'PUT' : 'POST';
    const url = currentEditId ? `/api/session_types/${currentEditId}` : '/api/session_types';

    try {
        const response = await fetch(url, {
            method,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });

        if (response.ok) {
            closeModal();
            loadSessionTypes();
            showToast(`Session Type ${currentEditId ? 'updated' : 'added'} successfully`, 'success');
        } else {
            const error = await response.json();
            showToast(error.error || 'Error saving session type', 'error');
        }
    } catch (error) {
        console.error('Error saving session type:', error);
        showToast('Error saving session type', 'error');
    }
}

async function deleteSessionType(id) {
    if (confirm('Are you sure you want to delete this session type?')) {
        try {
            const response = await fetch(`/api/session_types/${id}`, {
                method: 'DELETE'
            });

            if (response.ok) {
                loadSessionTypes();
                showToast('Session type deleted successfully', 'success');
            } else {
                const error = await response.json();
                showToast(error.error || 'Error deleting session type', 'error');
            }
        } catch (error) {
            console.error('Error deleting session type:', error);
            showToast('Error deleting session type', 'error');
        }
    }
}

// Subject Assignments functions
async function setupAssignmentsPage() {
    const section = document.getElementById('assignments');
    let headerActions = section.querySelector('.header-actions');

    // Add controls only if they don't exist to prevent re-creating them
    if (!headerActions) {
        const addButton = section.querySelector('button[onclick*="showAddForm"]');

        // 1. Create the main container for the filters and button, and style it for a single row layout
        headerActions = document.createElement('div');
        headerActions.className = 'header-actions';
        headerActions.style.display = 'flex';
        headerActions.style.alignItems = 'center';
        headerActions.style.gap = '15px';
        headerActions.style.flexWrap = 'wrap';
        headerActions.style.marginBottom = '15px';

        // 2. Create the filter elements as a temporary container to parse them
        const tempFilterContainer = document.createElement('div');
        tempFilterContainer.innerHTML = `
            <div class="filter-group" style="display: flex; align-items: center; gap: 5px;">
                <label for="assignment-program-filter" style="margin: 0;">Program:</label>
                <select id="assignment-program-filter" style="padding: 5px;">
                    <option value="">All Programs</option>
                </select>
            </div>
            <div class="filter-group" style="display: flex; align-items: center; gap: 5px;">
                <label for="assignment-year-filter" style="margin: 0;">Year:</label>
                <select id="assignment-year-filter" style="padding: 5px;">
                    <option value="">All Years</option>
                    <option value="1">Year 1</option>
                    <option value="2">Year 2</option>
                    <option value="3">Year 3</option>
                    <option value="4">Year 4</option>
                </select>
            </div>
            <div class="filter-group" style="display: flex; align-items: center; gap: 5px;">
                <label for="assignment-teacher-filter" style="margin: 0;">Teacher:</label>
                <select id="assignment-teacher-filter" style="padding: 5px;">
                    <option value="">All Teachers</option>
                </select>
            </div>
            <button id="clear-assignment-filters-btn" class="btn-secondary" style="padding: 5px 10px; margin: 0;">Clear</button>
        `;

        // 3. Move all filter elements directly into the headerActions container
        while (tempFilterContainer.firstChild) {
            headerActions.appendChild(tempFilterContainer.firstChild);
        }

        // 4. Move the "Add New" button to the end of the row
        if (addButton) {
            headerActions.appendChild(addButton);
        }

        // 5. Find or create a single, definitive h2 heading and remove any duplicates.
        const allH2s = section.querySelectorAll('h2');
        let h2;

        if (allH2s.length > 0) {
            // Keep the first h2 as the main heading.
            h2 = allH2s[0];
            // Remove any other h2 elements to prevent duplicates (the "lower one").
            for (let i = 1; i < allH2s.length; i++) {
                allH2s[i].remove();
            }
        } else {
            // If no h2 exists at all, create one.
            h2 = document.createElement('h2');
            section.prepend(h2);
        }

        // Unify the heading text and style to ensure it's prominent and singular.
        h2.textContent = 'Manage Subject Assignments';
        h2.style.fontSize = '2.2em'; // Increased size
        h2.style.marginBottom = '15px'; // Add some space below

        h2.insertAdjacentElement('afterend', headerActions);

        // 6. Populate filters and add event listeners
        // Populate filters
        const programSelect = document.getElementById('assignment-program-filter');
        const yearSelect = document.getElementById('assignment-year-filter');
        const teacherSelect = document.getElementById('assignment-teacher-filter');
        const clearBtn = document.getElementById('clear-assignment-filters-btn');

        try {
            const [programsRes, teachersRes] = await Promise.all([fetch('/api/programs'), fetch('/api/teachers')]);
            const programs = await programsRes.json();
            const teachers = await teachersRes.json();

            programs.forEach(p => {
                const option = document.createElement('option');
                option.value = p.program_id;
                option.textContent = p.name;
                programSelect.appendChild(option);
            });
            teachers.forEach(t => {
                const option = document.createElement('option');
                option.value = t.teacher_id;
                option.textContent = t.name;
                teacherSelect.appendChild(option);
            });
        } catch (error) {
            console.error("Failed to load filters", error);
            showToast("Failed to load filters", "error");
        }

        // Add event listeners
        programSelect.addEventListener('change', () => loadAssignments());
        yearSelect.addEventListener('change', () => loadAssignments());
        teacherSelect.addEventListener('change', () => loadAssignments());
        clearBtn.addEventListener('click', () => {
            programSelect.value = '';
            yearSelect.value = '';
            teacherSelect.value = '';
            loadAssignments();
        });
    }

    // Initial load
    loadAssignments();
}

async function loadAssignments() {
    const programFilter = document.getElementById('assignment-program-filter');
    const teacherFilter = document.getElementById('assignment-teacher-filter');
    const yearFilter = document.getElementById('assignment-year-filter');

    const programId = programFilter ? programFilter.value : null;
    const teacherId = teacherFilter ? teacherFilter.value : null;
    const year = yearFilter ? yearFilter.value : null;

    try {
        const url = new URL('/api/subject_assignments', window.location.origin);
        if (programId) {
            url.searchParams.append('program_id', programId);
        }
        if (year) {
            url.searchParams.append('year', year);
        }
        if (teacherId) {
            url.searchParams.append('teacher_id', teacherId);
        }

        const response = await fetch(url);
        const assignments = await response.json();

        if (!response.ok) {
            throw new Error(assignments.error || `Failed to load assignments. Status: ${response.status}`);
        }

        displayAssignments(assignments);
    } catch (error) {
        console.error('Error loading assignments:', error);
        showToast(error.message, 'error');
        // Clear the table on error
        displayAssignments([]);
    }
}

async function loadTimeslots() {
    try {
        const response = await fetch('/api/timeslots');
        const timeslots = await response.json();

        // Display timeslots in timetable view only
        displayTimeslotsAsTimetable(timeslots);
    } catch (error) {
        console.error('Error loading timeslots:', error);
    }
}

function formatTimeTo12Hour(timeString) {
    const [hours, minutes] = timeString.split(':').map(Number);
    const period = hours >= 12 ? 'PM' : 'AM';
    const displayHours = hours % 12 || 12;
    return `${displayHours}:${minutes.toString().padStart(2, '0')} ${period}`;
}

function displayTimeslotsAsGrid(timeslots) {
    const container = document.getElementById('timeslots-table-container');
    container.innerHTML = '';

    if (timeslots.length === 0) {
        container.innerHTML = '<p class="no-data">No timeslots available. Add some timeslots to get started.</p>';
        return;
    }

    // Group timeslots by day
    const dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const uniqueDays = [...new Set(timeslots.map(slot => slot.day_of_week))];
    const days = dayOrder.filter(day => uniqueDays.includes(day));
    const timeslotsByDay = {};

    days.forEach(day => {
        timeslotsByDay[day] = timeslots.filter(slot => slot.day_of_week === day);
    });

    // Create grid container
    const gridContainer = document.createElement('div');
    gridContainer.className = 'timeslots-grid';

    days.forEach(day => {
        const dayColumn = document.createElement('div');
        dayColumn.className = 'timeslots-day-column';

        const dayHeader = document.createElement('div');
        dayHeader.className = 'timeslots-day-header';
        dayHeader.textContent = day;
        dayColumn.appendChild(dayHeader);

        const slotsContainer = document.createElement('div');
        slotsContainer.className = 'timeslots-slots-container';

        timeslotsByDay[day].forEach(slot => {
            const slotElement = document.createElement('div');
            slotElement.className = 'timeslots-slot';

            // Check if this is a break/lunch slot
            const isBreak = slot.session_type_name && slot.session_type_name.toLowerCase().includes('break');
            const displayTime = `${formatTimeTo12Hour(slot.start_time)} - ${formatTimeTo12Hour(slot.end_time)}`;
            const slotType = isBreak ? 'break-slot' : 'lecture-slot';

            slotElement.className = `timeslots-slot ${slotType}`;
            slotElement.innerHTML = `
                <div class="timeslots-slot-time">${displayTime}</div>
                ${isBreak ? '<div class="timeslots-slot-type">Break</div>' : ''}
                <div class="timeslots-slot-actions">
                    <button onclick="editTimeslot(${slot.timeslot_id})" class="btn-secondary small">Edit</button>
                    <button onclick="deleteTimeslot(${slot.timeslot_id})" class="btn-danger small">Delete</button>
                </div>
            `;
            slotsContainer.appendChild(slotElement);
        });

        dayColumn.appendChild(slotsContainer);
        gridContainer.appendChild(dayColumn);
    });

    container.appendChild(gridContainer);
}

// Display timeslots in a timetable-like structure (like View Timetable)
function displayTimeslotsAsTimetable(timeslots) {
    const container = document.getElementById('timeslots-table-container');
    container.innerHTML = '';

    if (timeslots.length === 0) {
        const noDataMessage = document.createElement('div');
        noDataMessage.className = 'no-data';
        noDataMessage.innerHTML = `
            <p>No timeslots available.</p>
            <p>Please generate timeslot structure to create a timetable framework.</p>
            <p>Click "Generate Timeslot Structure" button above to create timeslots.</p>
        `;
        container.appendChild(noDataMessage);
        return;
    }

    // Day order for the timetable - always show Monday to Saturday
    const dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    // Get unique time slots and sort them
    const timeSlotSet = new Set();
    timeslots.forEach(slot => {
        const slotKey = `${slot.start_time}-${slot.end_time}`;
        timeSlotSet.add(slotKey);
    });

    const timeSlots = Array.from(timeSlotSet).sort((a, b) => {
        const aStart = a.split('-')[0];
        const bStart = b.split('-')[0];
        const aTime = aStart.split(':').map(Number);
        const bTime = bStart.split(':').map(Number);
        const aMinutes = aTime[0] * 60 + (aTime[1] || 0);
        const bMinutes = bTime[0] * 60 + (bTime[1] || 0);
        return aMinutes - bMinutes;
    });

    // Create timetable table
    let html = '<div class="timeslots-timetable-container">';
    html += '<table class="timeslots-timetable-table">';

    // Table header with time slots - Add Edit/Delete buttons in header
    html += '<thead><tr><th class="day-column-header">Day / Time</th>';
    timeSlots.forEach((slot) => {
        const [start, end] = slot.split('-');
        const displayTime = `${formatTimeTo12Hour(start)}-${formatTimeTo12Hour(end)}`;

        // Find the first timeslot data for this slot to get the ID
        const slotData = timeslots.find(s => `${s.start_time}-${s.end_time}` === slot);

        html += `<th class="time-column-header">
            <div class="time-header-content">
                <span class="time-display">${displayTime}</span>
            </div>
        </th>`;
    });
    html += '</tr></thead>';

    // Table body with days as rows (Monday to Saturday - always show all days)
    html += '<tbody>';
    dayOrder.forEach(day => {
        html += `<tr><td class="day-cell">${day}</td>`;

        // Get timeslots for this day
        const daySlots = timeslots.filter(slot => slot.day_of_week === day);

        // Check if this day has any timeslots
        const dayHasSlots = daySlots.length > 0;

        if (!dayHasSlots) {
            // Day has no timeslots - show empty cells
            timeSlots.forEach(() => {
                html += '<td class="timeslot-cell empty-cell">-</td>';
            });
        } else {
            // Day has timeslots - show them
            timeSlots.forEach(slot => {
                // Find if there's a timeslot for this day and time
                const slotData = daySlots.find(s => `${s.start_time}-${s.end_time}` === slot);

                if (slotData) {
                    // Check if this is a break/lunch slot
                    const isBreak = slotData.session_type_name &&
                        (slotData.session_type_name.toLowerCase().includes('break') ||
                            slotData.session_type_name.toLowerCase().includes('lunch'));

                    if (isBreak) {
                        html += `<td class="timeslot-cell break-cell">
                            <div class="timeslot-break">
                                <span class="break-label">${slotData.session_type_name || 'Break'}</span>
                            </div>
                        </td>`;
                    } else {
                        html += `<td class="timeslot-cell lecture-cell">
                            <div class="timeslot-info">
                                <span class="timeslot-time">${formatTimeTo12Hour(slotData.start_time)} - ${formatTimeTo12Hour(slotData.end_time)}</span>
                            </div>
                        </td>`;
                    }
                } else {
                    html += '<td class="timeslot-cell empty-cell">-</td>';
                }
            });
        }

        html += '</tr>';
    });

    html += '</tbody></table></div>';
    container.innerHTML += html;
}

function editTimeslot(id) {
    currentEditId = id;
    currentEditType = 'timeslot';
    showModal('Edit Timeslot', 'timeslot', id);
}

function showGenerateTimeslotStructure() {
    showModal('Generate Timeslot Structure', 'generate-timeslot-structure');
}

async function generateTimeslotStructure() {
    const dayStartTime = document.getElementById('day-start-time').value;
    const dayEndTime = document.getElementById('day-end-time').value;
    const lectureDuration = document.getElementById('lecture-duration').value;
    const breakDuration = document.getElementById('break-duration').value;
    const lunchStart = document.getElementById('lunch-start').value;
    const lunchEnd = document.getElementById('lunch-end').value;
    const clearExisting = document.getElementById('clear-existing').checked;

    // Get selected days
    const selectedDays = Array.from(document.querySelectorAll('input[name="days"]:checked')).map(cb => cb.value);

    if (!dayStartTime || !dayEndTime || !lectureDuration || !breakDuration || !lunchStart || !lunchEnd) {
        showToast('Please fill in all required fields', 'warning');
        return;
    }

    if (selectedDays.length === 0) {
        showToast('Please select at least one day', 'warning');
        return;
    }

    // Validate times
    if (dayStartTime >= dayEndTime) {
        showToast('Day end time must be after start time', 'error');
        return;
    }

    if (lunchStart >= lunchEnd) {
        showToast('Lunch break end time must be after start time', 'error');
        return;
    }

    // Show confirmation if clearing existing
    if (clearExisting) {
        if (!confirm('Are you sure you want to delete all existing timeslots? This action cannot be undone.')) {
            return;
        }
    }

    const data = {
        day_start_time: dayStartTime,
        day_end_time: dayEndTime,
        lecture_duration: parseInt(lectureDuration),
        break_duration: parseInt(breakDuration),
        lunch_start: lunchStart,
        lunch_end: lunchEnd,
        clear_existing: clearExisting,
        days: selectedDays
    };

    try {
        const response = await fetch('/api/timeslots/generate-structure', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });

        const result = await response.json();

        if (response.ok) {
            closeModal();
            loadTimeslots();
            showToast(
                `Timeslot structure generated successfully! Created ${result.timeslots_created} timeslots across ${result.days_processed} days.`,
                'success'
            );
        } else {
            showToast(result.error || 'Error generating timeslot structure', 'error');
        }
    } catch (error) {
        console.error('Error generating timeslot structure:', error);
        showToast('Error generating timeslot structure', 'error');
    }
}

async function deleteTimeslot(id) {
    if (confirm('Are you sure you want to delete this timeslot? This action cannot be undone.')) {
        try {
            const response = await fetch(`/api/timeslots/${id}`, {
                method: 'DELETE'
            });

            const result = await response.json();

            if (response.ok) {
                showToast('Timeslot deleted successfully', 'success');
                loadTimeslots();
            } else {
                showToast(result.error || 'Error deleting timeslot', 'error');
            }
        } catch (error) {
            console.error('Error deleting timeslot:', error);
            showToast('Error deleting timeslot', 'error');
        }
    }
}

// Delete timeslots by day
async function deleteTimeslotsByDay(day) {
    if (!confirm(`Are you sure you want to delete ALL timeslots for ${day}? This action cannot be undone.`)) {
        return;
    }

    try {
        const response = await fetch('/api/timeslots/delete-by-day', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ day_of_week: day })
        });

        const result = await response.json();

        if (response.ok) {
            showToast(`Successfully deleted ${result.deleted_count} timeslot(s) for ${day}`, 'success');
            loadTimeslots();
        } else {
            showToast(result.error || 'Error deleting timeslots', 'error');
        }
    } catch (error) {
        console.error('Error deleting timeslots:', error);
        showToast('Error deleting timeslots', 'error');
    }
}

// Delete all timeslots
async function deleteAllTimeslots() {
    if (!confirm('⚠️ WARNING: This will delete ALL timeslots! This action cannot be undone.\n\nAre you absolutely sure?')) {
        return;
    }

    // Double confirmation
    if (!confirm('This is your last chance. Delete ALL timeslots?')) {
        return;
    }

    try {
        const response = await fetch('/api/timeslots/delete-all', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ confirm: true })
        });

        const result = await response.json();

        if (response.ok) {
            showToast('All timeslots deleted successfully', 'success');
            loadTimeslots();
        } else {
            showToast(result.error || 'Error deleting timeslots', 'error');
        }
    } catch (error) {
        console.error('Error deleting timeslots:', error);
        showToast('Error deleting timeslots', 'error');
    }
}

// Bulk delete selected timeslots
async function bulkDeleteTimeslots(timeslotIds) {
    if (!timeslotIds || timeslotIds.length === 0) {
        showToast('No timeslots selected', 'warning');
        return;
    }

    if (!confirm(`Are you sure you want to delete ${timeslotIds.length} timeslot(s)? This action cannot be undone.`)) {
        return;
    }

    try {
        const response = await fetch('/api/timeslots/bulk-delete', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ timeslot_ids: timeslotIds })
        });

        const result = await response.json();

        if (response.ok) {
            showToast(`Successfully deleted ${result.deleted_count} timeslot(s)`, 'success');
            loadTimeslots();
        } else {
            showToast(result.error || 'Error deleting timeslots', 'error');
            if (result.used_timeslots) {
                showToast(`Timeslots in use: ${result.used_timeslots.join(', ')}`, 'warning');
            }
        }
    } catch (error) {
        console.error('Error deleting timeslots:', error);
        showToast('Error deleting timeslots', 'error');
    }
}

// Delete timetable functions
async function deleteTimetableBySection(sectionId) {
    if (!sectionId) {
        showToast('Please select a section', 'warning');
        return;
    }

    if (!confirm('Are you sure you want to delete all timetable slots for this section? This action cannot be undone.')) {
        return;
    }

    try {
        const response = await fetch(`/api/timetable/section/${sectionId}`, {
            method: 'DELETE'
        });

        const result = await response.json();

        if (response.ok) {
            showToast(`Successfully deleted ${result.deleted_count} timetable slot(s)`, 'success');
            closeModal();
            loadTimetable();
        } else {
            showToast(result.error || 'Error deleting timetable', 'error');
        }
    } catch (error) {
        console.error('Error deleting timetable:', error);
        showToast('Error deleting timetable', 'error');
    }
}

async function deleteTimetableByTeacher(teacherId) {
    if (!teacherId) {
        showToast('Please select a teacher', 'warning');
        return;
    }

    if (!confirm('Are you sure you want to delete all timetable slots for this teacher? This action cannot be undone.')) {
        return;
    }

    try {
        const response = await fetch(`/api/timetable/teacher/${teacherId}`, {
            method: 'DELETE'
        });

        const result = await response.json();

        if (response.ok) {
            showToast(`Successfully deleted ${result.deleted_count} timetable slot(s)`, 'success');
            closeModal();
            loadTimetable();
        } else {
            showToast(result.error || 'Error deleting timetable', 'error');
        }
    } catch (error) {
        console.error('Error deleting timetable:', error);
        showToast('Error deleting timetable', 'error');
    }
}

async function deleteTimetableByDay(day) {
    if (!day) {
        showToast('Please select a day', 'warning');
        return;
    }

    if (!confirm(`Are you sure you want to delete all timetable slots for ${day}? This action cannot be undone.`)) {
        return;
    }

    try {
        const response = await fetch(`/api/timetable/day/${day}`, {
            method: 'DELETE'
        });

        const result = await response.json();

        if (response.ok) {
            showToast(`Successfully deleted ${result.deleted_count} timetable slot(s) for ${day}`, 'success');
            closeModal();
            loadTimetable();
        } else {
            showToast(result.error || 'Error deleting timetable', 'error');
        }
    } catch (error) {
        console.error('Error deleting timetable:', error);
        showToast('Error deleting timetable', 'error');
    }
}

async function deleteTimetableByRoom(roomId) {
    if (!roomId) {
        showToast('Please select a room', 'warning');
        return;
    }

    if (!confirm('Are you sure you want to delete all timetable slots for this room? This action cannot be undone.')) {
        return;
    }

    try {
        const response = await fetch(`/api/timetable/room/${roomId}`, {
            method: 'DELETE'
        });

        const result = await response.json();

        if (response.ok) {
            showToast(`Successfully deleted ${result.deleted_count} timetable slot(s)`, 'success');
            closeModal();
            loadTimetable();
        } else {
            showToast(result.error || 'Error deleting timetable', 'error');
        }
    } catch (error) {
        console.error('Error deleting timetable:', error);
        showToast('Error deleting timetable', 'error');
    }
}

async function deleteAllTimetable() {
    if (!confirm('⚠️ WARNING: This will delete ALL timetable slots! This action cannot be undone.\n\nAre you absolutely sure?')) {
        return;
    }

    // Double confirmation
    if (!confirm('This is your last chance. Delete ALL timetable slots?')) {
        return;
    }

    try {
        const response = await fetch('/api/timetable', {
            method: 'DELETE'
        });

        const result = await response.json();

        if (response.ok) {
            showToast('All timetable slots deleted successfully', 'success');
            closeModal();
            loadTimetable();
        } else {
            showToast(result.error || 'Error deleting timetable', 'error');
        }
    } catch (error) {
        console.error('Error deleting timetable:', error);
        showToast('Error deleting timetable', 'error');
    }
}

function displayAssignments(assignments) {
    const table = document.getElementById('assignments-table');
    const thead = table.querySelector('thead tr');
    const tbody = table.querySelector('tbody');

    // Update headers to include more details
    if (thead) {
        thead.innerHTML = `
            <th>ID</th>
            <th>Class (Program - Sec)</th>
            <th>Subject</th>
            <th>Teacher</th>
            <th>Hours/Week</th>
            <th>Actions</th>
        `;
    }

    tbody.innerHTML = '';

    if (!Array.isArray(assignments) || assignments.length === 0) {
        const row = document.createElement('tr');
        const cell = document.createElement('td');
        cell.colSpan = 6; // Number of columns in the assignments table
        cell.textContent = 'No subject assignments found. Try clearing filters or adding new assignments.';
        cell.className = 'no-data';
        row.appendChild(cell);
        tbody.appendChild(row);
        return;
    }

    assignments.forEach(assignment => {
        const row = document.createElement('tr');

        // Format Class: e.g., "BCA - A (Year 1)"
        const programStr = assignment.program_code || assignment.program_name;
        const classStr = `${programStr} - ${assignment.group_name} (Year ${assignment.year})`;

        // Format Subject: "CS101 - Data Structures"
        const subjectStr = assignment.subject_code
            ? `${assignment.subject_code} - ${assignment.subject_name}`
            : assignment.subject_name;

        row.innerHTML = `
            <td>${assignment.assign_id}</td>
            <td>${classStr}</td>
            <td>${subjectStr}</td>
            <td>${assignment.teacher_name}</td>
            <td>${assignment.hours_per_week}</td>
            <td>
                <button onclick="editAssignment(${assignment.assign_id})" class="btn-secondary">Edit</button>
                <button onclick="deleteAssignment(${assignment.assign_id})" class="btn-danger">Delete</button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// Generation functions
async function loadGenerationStats() {
    try {
        const [teachers, rooms, subjects, assignments] = await Promise.all([
            fetch('/api/teachers').then(r => r.json()),
            fetch('/api/rooms').then(r => r.json()),
            fetch('/api/subjects').then(r => r.json()),
            fetch('/api/subject_assignments').then(r => r.json())
        ]);

        document.getElementById('gen-teacher-count').textContent = teachers.length;
        document.getElementById('gen-room-count').textContent = rooms.length;
        document.getElementById('gen-subject-count').textContent = subjects.length;
        document.getElementById('gen-assignment-count').textContent = assignments.length;
    } catch (error) {
        console.error('Error loading generation stats:', error);
    }
}

// Timetable viewing functions
async function loadTimetable() {
    const sectionSelect = document.getElementById('section-select');
    const sectionId = sectionSelect ? sectionSelect.value : null;
    const container = document.getElementById('timetable-container');

    try {
        // Always load timetable - structure will be shown even if no class selected
        const url = sectionId ? `/api/timetable?section_id=${sectionId}` : '/api/timetable';
        const response = await fetch(url);

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const timetable = await response.json();

        // Always display timetable - structure will be shown
        displayTimetable(timetable, container);
    } catch (error) {
        console.error('Error loading timetable:', error);
        container.innerHTML = '<p class="error">Error loading timetable: ' + error.message + '</p>';
    }
}

function displayTimetable(timetable, container) {
    const dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    // Only show days that have data (timeslots defined)
    const days = dayOrder.filter(day => (timetable[day] && timetable[day].length > 0) || day === 'Saturday');

    // Extract all unique time slots from the timetable data
    const timeSlotSet = new Set();
    days.forEach(day => {
        if (timetable[day] && timetable[day].length > 0) {
            timetable[day].forEach(entry => {
                if (entry.timeslot) {
                    timeSlotSet.add(entry.timeslot);
                }
            });
        }
    });

    // Convert to array and sort by start time (properly handle time format)
    const timeSlots = Array.from(timeSlotSet).sort((a, b) => {
        const aStart = a.split('-')[0];
        const bStart = b.split('-')[0];
        // Convert time strings to comparable format (HH:MM)
        const aTime = aStart.split(':').map(Number);
        const bTime = bStart.split(':').map(Number);
        const aMinutes = aTime[0] * 60 + (aTime[1] || 0);
        const bMinutes = bTime[0] * 60 + (bTime[1] || 0);
        return aMinutes - bMinutes;
    });

    // If no timeslots found, show message
    if (timeSlots.length === 0) {
        container.innerHTML = '<p class="no-data">No timeslots found. Please generate timeslot structure first.</p>';
        return;
    }

    // If timetable is empty but timeslots exist, show structure
    const hasData = Object.keys(timetable).some(day =>
        timetable[day] && timetable[day].some(entry => !entry.is_empty && !entry.is_break)
    );

    if (!hasData && timeSlots.length > 0) {
        // Show empty structure
        let html = '<div class="timetable-table-container">';
        html += '<table class="timetable-table">';
        html += '<thead><tr><th>Day / Time</th>';

        timeSlots.forEach(slot => {
            const [start, end] = slot.split('-');
            const displayTime = `${formatTimeTo12Hour(start)}-${formatTimeTo12Hour(end)}`;
            html += `<th>${displayTime}</th>`;
        });

        html += '</tr></thead><tbody>';

        days.forEach(day => {
            html += `<tr><td class="day-header">${day}</td>`;
            timeSlots.forEach(slot => {
                // Check if this slot exists for this day
                const dayEntries = timetable[day] || [];
                const slotEntry = dayEntries.find(e => e.timeslot === slot);

                if (slotEntry) {
                    if (slotEntry.is_break) {
                        html += `<td class="timetable-cell break"><div class="break-slot">${slotEntry.break_type || 'Break'}</div></td>`;
                    } else if (slotEntry.is_empty) {
                        html += `<td class="timetable-cell empty"><div class="empty-slot">-</div></td>`;
                    } else {
                        html += `<td class="timetable-cell occupied">
                            <div class="slot-content">
                                <div class="slot-subject">${slotEntry.subject || '-'}</div>
                                <div class="slot-teacher">${slotEntry.teacher || '-'}</div>
                                <div class="slot-room">${slotEntry.room || '-'}</div>
                                ${slotEntry.group ? `<div class="slot-group">${slotEntry.group}</div>` : ''}
                            </div>
                        </td>`;
                    }
                } else {
                    // No entry for this slot on this day - show empty
                    html += `<td class="timetable-cell empty"><div class="empty-slot">-</div></td>`;
                }
            });
            html += '</tr>';
        });

        html += '</tbody></table></div>';
        container.innerHTML = html;
        return;
    }

    let html = '<div class="timetable-table-container">';
    html += '<table class="timetable-table">';
    html += '<thead><tr><th>Day / Time</th>';

    timeSlots.forEach(slot => {
        const [start, end] = slot.split('-');
        const displayTime = `${formatTimeTo12Hour(start)}-${formatTimeTo12Hour(end)}`;
        html += `<th>${displayTime}</th>`;
    });

    html += '</tr></thead><tbody>';

    days.forEach(day => {
        html += `<tr><td class="day-header">${day}</td>`;

        timeSlots.forEach(slot => {
            let cellContent = '<div class="empty-slot">-</div>';
            let cellClass = 'timetable-cell empty';

            if (timetable[day] && timetable[day].length > 0) {
                // Find all entries for this timeslot (could be multiple if viewing all sections)
                const slotEntries = timetable[day].filter(s => s.timeslot === slot);

                if (slotEntries.length > 0) {
                    const firstEntry = slotEntries[0];

                    // Check if this is a break slot
                    if (firstEntry.is_break) {
                        cellContent = `<div class="break-slot">${firstEntry.break_type || 'Break'}</div>`;
                        cellClass = 'timetable-cell break';
                    } else if (firstEntry.is_empty) {
                        // Empty slot - show structure
                        cellContent = '<div class="empty-slot">-</div>';
                        cellClass = 'timetable-cell empty';
                    } else {
                        // Scheduled slot - show first entry, or all if multiple
                        if (slotEntries.length === 1) {
                            const entry = slotEntries[0];
                            cellContent = `
                                <div class="slot-content">
                                    <div class="slot-subject">${entry.subject || '-'}</div>
                                    <div class="slot-teacher">${entry.teacher || '-'}</div>
                                    <div class="slot-room">${entry.room || '-'}</div>
                                    ${entry.group ? `<div class="slot-group">${entry.group}</div>` : ''}
                                </div>
                            `;
                        } else {
                            // Multiple entries for this slot
                            cellContent = '<div class="slot-content multiple-slots">';
                            slotEntries.forEach(entry => {
                                cellContent += `
                                    <div class="slot-entry">
                                        <div class="slot-subject">${entry.subject || '-'}</div>
                                        <div class="slot-teacher">${entry.teacher || '-'}</div>
                                        <div class="slot-room">${entry.room || '-'}</div>
                                        ${entry.group ? `<div class="slot-group">${entry.group}</div>` : ''}
                                    </div>
                                `;
                            });
                            cellContent += '</div>';
                        }
                        cellClass = 'timetable-cell occupied';
                    }
                } else {
                    // No entry for this slot on this day - show empty structure
                    cellContent = '<div class="empty-slot">-</div>';
                    cellClass = 'timetable-cell empty';
                }
            } else {
                // No data for this day - show empty structure (structure will be shown)
                cellContent = '<div class="empty-slot">-</div>';
                cellClass = 'timetable-cell empty';
            }

            html += `<td class="${cellClass}">${cellContent}</td>`;
        });

        html += '</tr>';
    });

    html += '</tbody></table></div>';
    container.innerHTML = html;
}

// Load sections for dropdown
async function loadSectionsForDropdown() {
    try {
        const select = document.getElementById('section-select');
        if (!select) return;

        // Choose appropriate endpoint based on logged-in role
        let endpoint = '/api/sections';
        if (window.currentUserRole === 'teacher') {
            // For teachers, only show sections they teach (if backend supports it)
            endpoint = '/api/sections?for_role=teacher';
        } else if (window.currentUserRole === 'student') {
            // For students, show only their own section (if available)
            endpoint = '/api/sections?for_role=student';
        }

        const response = await fetch(endpoint);
        const sections = await response.json();

        select.innerHTML = '<option value="">Select Class</option>';

        sections.forEach(section => {
            const option = document.createElement('option');
            option.value = section.section_id;
            option.textContent = `${section.program_name} - ${section.section_name} (Year ${section.year})`;
            select.appendChild(option);
        });

        // If there is exactly one section (common for students), auto-select it
        if (window.currentUserRole === 'student' && sections.length === 1) {
            select.value = sections[0].section_id;
            select.disabled = true;
            loadTimetable();
        }
    } catch (error) {
        console.error('Error loading sections:', error);
    }
}

// Multi-Timetable View Functions
// Toggle the multi-timetable dropdown menu
function toggleMultiTimetableMenu() {
    const menu = document.getElementById('multi-timetable-menu');
    if (menu.style.display === 'none') {
        menu.style.display = 'block';
        // Load checkboxes for sections
        loadMultiSectionCheckboxes();
    } else {
        menu.style.display = 'none';
    }
}

// Load section checkboxes for multi-select
async function loadMultiSectionCheckboxes() {
    try {
        const response = await fetch('/api/sections');
        const sections = await response.json();

        const container = document.getElementById('multi-section-checkboxes');
        container.innerHTML = '';

        sections.forEach(section => {
            const label = document.createElement('label');
            label.style.display = 'flex';
            label.style.alignItems = 'center';
            label.style.marginBottom = '5px';
            label.style.cursor = 'pointer';

            const checkbox = document.createElement('input');
            checkbox.type = 'checkbox';
            checkbox.value = section.section_id;
            checkbox.className = 'multi-section-checkbox';
            checkbox.style.marginRight = '8px';

            label.appendChild(checkbox);
            label.appendChild(document.createTextNode(
                `${section.program_name} - ${section.section_name} (Year ${section.year})`
            ));

            container.appendChild(label);
        });
    } catch (error) {
        console.error('Error loading sections for checkboxes:', error);
    }
}

// Load all timetables at once
async function loadAllTimetables() {
    try {
        const response = await fetch('/api/sections');
        const sections = await response.json();

        if (sections.length === 0) {
            showToast('No sections available', 'warning');
            return;
        }

        // Get all section IDs
        const sectionIds = sections.map(s => s.section_id);

        // Close the menu
        document.getElementById('multi-timetable-menu').style.display = 'none';

        // Update button text
        const btn = document.getElementById('multi-timetable-btn');
        btn.innerHTML = `Viewing All Classes (${sectionIds.length}) ▼`;

        // Load all timetables
        displayMultipleTimetables(sectionIds);

    } catch (error) {
        console.error('Error loading all timetables:', error);
        showToast('Error loading timetables', 'error');
    }
}

// Load selected timetables based on checkboxes
async function loadSelectedTimetables() {
    const checkboxes = document.querySelectorAll('.multi-section-checkbox:checked');
    const sectionIds = Array.from(checkboxes).map(cb => parseInt(cb.value));

    if (sectionIds.length === 0) {
        showToast('Please select at least one class', 'warning');
        return;
    }

    // Close the menu
    document.getElementById('multi-timetable-menu').style.display = 'none';

    // Update button text
    const btn = document.getElementById('multi-timetable-btn');
    btn.innerHTML = `Viewing ${sectionIds.length} Classes ▼`;

    // Load selected timetables
    displayMultipleTimetables(sectionIds);
}

// Display multiple timetables side by side
async function displayMultipleTimetables(sectionIds) {
    const container = document.getElementById('timetable-container');
    container.innerHTML = '<div class="loading">Loading timetables...</div>';

    try {
        // Fetch timetables for all selected sections
        const timetablePromises = sectionIds.map(sectionId =>
            fetch(`/api/timetable?section_id=${sectionId}`).then(r => r.json())
        );

        const timetables = await Promise.all(timetablePromises);

        // Get section names
        const sectionsResponse = await fetch('/api/sections');
        const allSections = await sectionsResponse.json();
        const sectionMap = {};
        allSections.forEach(s => {
            sectionMap[s.section_id] = s;
        });

        // Create container for multiple timetables
        let html = '<div class="multiple-timetables-container">';

        // Track which section IDs are currently rendered so export can respect the view
        window.currentMultiSectionIds = sectionIds.slice();

        sectionIds.forEach((sectionId, index) => {
            const section = sectionMap[sectionId];
            const timetable = timetables[index];
            const sectionName = section ?
                `${section.program_name} - ${section.section_name} (Year ${section.year})` :
                `Section ${sectionId}`;

            html += `<div class="single-timetable-wrapper" data-section-id="${sectionId}">`;
            html += `<h3 class="timetable-section-title">${sectionName}</h3>`;

            // Render the timetable for this section
            html += renderSingleTimetable(timetable);

            html += `</div>`;
        });

        html += '</div>';
        container.innerHTML = html;

    } catch (error) {
        console.error('Error displaying multiple timetables:', error);
        container.innerHTML = '<p class="error">Error loading timetables: ' + error.message + '</p>';
    }
}

// Render a single timetable as HTML string
function renderSingleTimetable(timetable) {
    const dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const days = dayOrder.filter(day => (timetable[day] && timetable[day].length > 0) || day === 'Saturday');

    // Extract all unique time slots
    const timeSlotSet = new Set();
    days.forEach(day => {
        if (timetable[day] && timetable[day].length > 0) {
            timetable[day].forEach(entry => {
                if (entry.timeslot) {
                    timeSlotSet.add(entry.timeslot);
                }
            });
        }
    });

    const timeSlots = Array.from(timeSlotSet).sort((a, b) => {
        const aStart = a.split('-')[0];
        const bStart = b.split('-')[0];
        const aTime = aStart.split(':').map(Number);
        const bTime = bStart.split(':').map(Number);
        const aMinutes = aTime[0] * 60 + (aTime[1] || 0);
        const bMinutes = bTime[0] * 60 + (bTime[1] || 0);
        return aMinutes - bMinutes;
    });

    if (timeSlots.length === 0) {
        return '<p class="no-data">No timeslots found.</p>';
    }

    let html = '<div class="timetable-table-container">';
    html += '<table class="timetable-table">';
    html += '<thead><tr><th>Day / Time</th>';

    timeSlots.forEach(slot => {
        const [start, end] = slot.split('-');
        const displayTime = `${formatTimeTo12Hour(start)}-${formatTimeTo12Hour(end)}`;
        html += `<th>${displayTime}</th>`;
    });

    html += '</tr></thead><tbody>';

    days.forEach(day => {
        html += `<tr><td class="day-header">${day}</td>`;

        timeSlots.forEach(slot => {
            let cellContent = '<div class="empty-slot">-</div>';
            let cellClass = 'timetable-cell empty';

            if (timetable[day] && timetable[day].length > 0) {
                const slotEntries = timetable[day].filter(s => s.timeslot === slot);

                if (slotEntries.length > 0) {
                    const firstEntry = slotEntries[0];

                    if (firstEntry.is_break) {
                        cellContent = `<div class="break-slot">${firstEntry.break_type || 'Break'}</div>`;
                        cellClass = 'timetable-cell break';
                    } else if (firstEntry.is_empty) {
                        cellContent = '<div class="empty-slot">-</div>';
                        cellClass = 'timetable-cell empty';
                    } else {
                        const entry = slotEntries[0];
                        cellContent = `
                            <div class="slot-content">
                                <div class="slot-subject">${entry.subject || '-'}</div>
                                <div class="slot-teacher">${entry.teacher || '-'}</div>
                                <div class="slot-room">${entry.room || '-'}</div>
                            </div>
                        `;
                        cellClass = 'timetable-cell occupied';
                    }
                }
            }

            html += `<td class="${cellClass}">${cellContent}</td>`;
        });

        html += '</tr>';
    });

    html += '</tbody></table></div>';
    return html;
}

// Close multi-timetable menu when clicking outside
document.addEventListener('click', function (event) {
    const menu = document.getElementById('multi-timetable-menu');
    const btn = document.getElementById('multi-timetable-btn');

    if (menu && !menu.contains(event.target) && !btn.contains(event.target)) {
        menu.style.display = 'none';
    }
});

// Export Functions
function showExportOptions(event) {
    const menu = document.getElementById('export-options-menu');
    // Try to get button from event, or fallback to ID
    const btn = (event && event.currentTarget) ? event.currentTarget : document.getElementById('export-btn');

    if (!menu) return;

    if (menu.style.display === 'none' || menu.style.display === '') {
        menu.style.display = 'block';

        // Position logic: Place menu near the button
        if (btn) {
            menu.style.position = 'absolute';
            const rect = btn.getBoundingClientRect();
            const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
            const scrollLeft = window.pageXOffset || document.documentElement.scrollLeft;

            menu.style.top = (rect.bottom + scrollTop + 5) + 'px';
            menu.style.left = (rect.left + scrollLeft) + 'px';
            menu.style.zIndex = '1000';
        }
    } else {
        menu.style.display = 'none';
    }

    if (event) {
        event.stopPropagation();
    }
}

// Export all timetables (all sections)
async function exportAllTimetables(format) {
    try {
        // Hide export menu
        document.getElementById('export-options-menu').style.display = 'none';

        showToast(`Exporting all timetables as ${format.toUpperCase()}...`, 'info');

        let url = `/api/export/${format}`;

        // Create download link - this will export all sections
        const link = document.createElement('a');
        link.href = url;
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
        link.download = `all_timetables_${timestamp}.${format === 'excel' ? 'xlsx' : format}`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        showToast(`All timetables exported as ${format.toUpperCase()}`, 'success');
    } catch (error) {
        console.error('Error exporting all timetables:', error);
        showToast('Error exporting timetables', 'error');
    }
}

// Close export menu when clicking outside
document.addEventListener('click', function (event) {
    const exportMenu = document.getElementById('export-options-menu');
    const exportBtn = document.getElementById('export-btn');

    if (exportMenu && !exportMenu.contains(event.target) && !exportBtn.contains(event.target)) {
        exportMenu.style.display = 'none';
    }
});

// Initialize timetable viewer when section is shown
document.addEventListener('DOMContentLoaded', function () {
    // ... existing code ...

    // Add timetable viewer initialization
    const timetableSection = document.getElementById('view-timetable');
    if (timetableSection) {
        loadSectionsForDropdown();
        loadTimetable();
    }
});

async function generateTimetable(overwrite = false) {
    const btn = document.getElementById('generate-btn');
    const status = document.getElementById('generation-status');

    // On the initial call, set up the UI for loading
    if (!overwrite) {
        btn.disabled = true;
        btn.textContent = 'Generating...';

        status.style.display = 'block';
        status.className = 'generation-status';
        status.textContent = 'Starting timetable generation...';

        // Add loading spinner
        const spinner = document.createElement('div');
        spinner.className = 'loading-spinner';
        spinner.innerHTML = '<div class="spinner"></div>';

        const existingSpinner = status.querySelector('.loading-spinner');
        if (existingSpinner) {
            existingSpinner.remove();
        }
        status.appendChild(spinner);
        
        // Remove any existing error notification bar
        removeErrorNotificationBar();
    }

    try {
        const response = await fetch('/api/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ overwrite })
        });

        const result = await response.json();

        if (response.ok) {
            status.className = 'generation-status success';
            status.textContent = 'Timetable generated successfully!';
            if (currentSection === 'view-timetable') {
                loadTimetable();
            }
        } else if (response.status === 409 && result.conflict === 'existing_timetable') {
            // Confirmation dialog
            if (confirm('A timetable already exists. Do you want to delete it and generate a new one?')) {
                status.textContent = 'Overwriting existing timetable...';
                generateTimetable(true); // Recursive call, UI remains in loading state
                return; // Prevent finally block from running prematurely
            } else {
                // User cancelled
                status.className = 'generation-status warning';
                status.textContent = 'Generation cancelled.';
            }
        } else {
            // Other errors - show detailed error notification
            status.className = 'generation-status error';
            status.textContent = `Error: ${result.error || 'Unknown error'}`;
            
            // Show detailed error notification bar
            showErrorNotificationBar(result);
        }
    } catch (error) {
        status.className = 'generation-status error';
        status.textContent = `Error: ${error.message}`;
        showErrorNotificationBar({
            error: error.message,
            error_details: {
                title: 'Connection Error',
                message: 'Failed to connect to the server.',
                suggestion: 'Please check your internet connection and try again.'
            }
        });
    }

    // This block runs when the process is complete (success, error, or cancellation)
    if (!btn.disabled) { // If button is already enabled, do nothing
        btn.disabled = false;
        btn.textContent = 'Generate Timetable';
        // Remove spinner
        const existingSpinner = status.querySelector('.loading-spinner');
        if (existingSpinner) {
            existingSpinner.remove();
        }
    }
}

// Function to show detailed error notification bar
function showErrorNotificationBar(errorData) {
    // Remove any existing notification bar first
    removeErrorNotificationBar();
    
    // Get error details from the response
    const errorDetails = errorData.error_details || {};
    const context = errorData.context || {};
    const errorCode = errorData.error_code;
    
    // Create notification bar container
    const notificationBar = document.createElement('div');
    notificationBar.id = 'error-notification-bar';
    notificationBar.className = 'error-notification-bar';
    
    // Determine severity class
    const severity = errorDetails.severity || 'critical';
    notificationBar.classList.add(`severity-${severity}`);
    
    // Build the notification content
    let content = `
        <div class="error-notification-header">
            <span class="error-icon">⚠️</span>
            <span class="error-title">${errorDetails.title || 'Error Generating Timetable'}</span>
            <button class="close-notification" onclick="removeErrorNotificationBar()">×</button>
        </div>
        <div class="error-notification-body">
            <p class="error-message">${errorDetails.message || errorData.error || 'An unknown error occurred.'}</p>
    `;
    
    // Add suggestion if available
    if (errorDetails.suggestion) {
        content += `
            <div class="error-suggestion">
                <strong>💡 How to fix:</strong>
                <p>${errorDetails.suggestion}</p>
            </div>
        `;
    }
    
    // Add context information if available
    if (context && Object.keys(context).length > 0) {
        content += `<div class="error-context"><strong>📊 Details:</strong><ul>`;
        for (const [key, value] of Object.entries(context)) {
            if (key !== 'message') {
                content += `<li>${formatContextKey(key)}: <strong>${value}</strong></li>`;
            }
        }
        content += `</ul></div>`;
    }
    
    // Add action button if link is provided
    if (errorDetails.link) {
        content += `
            <div class="error-actions">
                <button class="btn-primary" onclick="navigateToFix('${errorDetails.link}')">
                    Go to ${getLinkLabel(errorDetails.link)}
                </button>
            </div>
        `;
    }
    
    content += `</div>`;
    notificationBar.innerHTML = content;
    
    // Insert after the status element or at the top of generate section
    const generateSection = document.getElementById('generate');
    if (generateSection) {
        const statusElement = document.getElementById('generation-status');
        if (statusElement) {
            statusElement.parentNode.insertBefore(notificationBar, statusElement.nextSibling);
        } else {
            generateSection.insertBefore(notificationBar, generateSection.firstChild);
        }
    }
}

// Helper function to format context keys
function formatContextKey(key) {
    return key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
}

// Helper function to get link label
function getLinkLabel(link) {
    const labels = {
        '#teachers': 'Teachers',
        '#rooms': 'Rooms',
        '#subjects': 'Subjects',
        '#groups': 'Sections',
        '#assignments': 'Subject Assignments',
        '#timeslots': 'Timeslots',
        '#preferences': 'Teacher Preferences'
    };
    return labels[link] || 'Fix Page';
}

// Function to navigate to fix the issue
function navigateToFix(link) {
    removeErrorNotificationBar();
    showSection(link.replace('#', ''));
}

// Function to remove error notification bar
function removeErrorNotificationBar() {
    const existingBar = document.getElementById('error-notification-bar');
    if (existingBar) {
        existingBar.remove();
    }
}

// Modal functions
let currentEditId = null;
let currentEditType = null;

function showAddForm(type) {
    currentEditId = null;
    currentEditType = type;
    const title = type === 'group' ? 'Add New Section' : `Add New ${type.charAt(0).toUpperCase() + type.slice(1)}`;
    showModal(title, type);
}

function editTeacher(id) {
    currentEditId = id;
    currentEditType = 'teacher';
    showModal('Edit Teacher', 'teacher', id);
}

function editRoom(id) {
    currentEditId = id;
    currentEditType = 'room';
    showModal('Edit Room', 'room', id);
}

function editSubject(id) {
    currentEditId = id;
    currentEditType = 'subject';
    showModal('Edit Subject', 'subject', id);
}

function editGroup(id) {
    currentEditId = id;
    currentEditType = 'group';
    showModal('Edit Section', 'group', id);
}

function editSessionType(id) {
    currentEditId = id;
    currentEditType = 'session-type';
    showModal('Edit Session Type', 'session-type', id);
}

function editAssignment(id) {
    currentEditId = id;
    currentEditType = 'assignment';
    showModal('Edit Subject Assignment', 'assignment', id);
}

async function showModal(title, type, id = null) {
    const modal = document.getElementById('modal');
    const modalTitle = document.getElementById('modal-title');
    const modalForm = document.getElementById('modal-form');

    modalTitle.textContent = title;
    modalForm.innerHTML = getFormHTML(type);

    if (id) {
        // Load existing data for editing
        await loadFormData(type, id);
    } else {
        // Load dropdown data for new forms
        if (type === 'group') {
            await loadProgramsForForm();
        } else if (type === 'assignment') {
            await Promise.all([
                loadSubjectsForForm(),
                loadTeachersForForm(),
                loadGroupsForForm()
            ]);
        }
    }

    modal.style.display = 'block';

    // Focus on first input
    const firstInput = modalForm.querySelector('input, select');
    if (firstInput) firstInput.focus();
}

function getFormHTML(type) {
    switch (type) {
        case 'teacher':
            return `
                <div class="form-group">
                    <label for="teacher-name">Name:</label>
                    <input type="text" id="teacher-name" required>
                </div>
                <div class="form-group">
                    <label for="teacher-email">Email:</label>
                    <input type="email" id="teacher-email" required>
                </div>
                <div class="form-actions">
                    <button type="button" onclick="closeModal()" class="btn-secondary">Cancel</button>
                    <button type="button" onclick="saveTeacher()" class="btn-primary">Save</button>
                </div>
            `;
        case 'room':
            return `
                <div class="form-group">
                    <label for="room-name">Name:</label>
                    <input type="text" id="room-name" required>
                </div>
                <div class="form-group">
                    <label for="room-capacity">Capacity:</label>
                    <input type="number" id="room-capacity" min="1" required>
                </div>
                <div class="form-group">
                    <label for="room-type">Type:</label>
                    <select id="room-type" required>
                        <option value="LECTURE">Lecture</option>
                        <option value="LAB">Lab</option>
                    </select>
                </div>
                <div class="form-actions">
                    <button type="button" onclick="closeModal()" class="btn-secondary">Cancel</button>
                    <button type="button" onclick="saveRoom()" class="btn-primary">Save</button>
                </div>
            `;
        case 'group':
            return `
                <div class="form-group">
                    <label for="group-program">Program:</label>
                    <select id="group-program" required>
                        <option value="">Loading...</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="group-name">Section:</label>
                    <input type="text" id="group-name">
                </div>
                <div class="form-group">
                    <label for="group-year">Year:</label>
                    <input type="number" id="group-year" min="1" max="4" required>
                </div>
                <div class="form-group">
                    <label for="group-size">Size:</label>
                    <input type="number" id="group-size" min="1" required>
                </div>
                <div class="form-actions">
                    <button type="button" onclick="closeModal()" class="btn-secondary">Cancel</button>
                    <button type="button" onclick="saveGroup()" class="btn-primary">Save</button>
                </div>
            `;
        case 'session-type':
            return `
                <div class="form-group">
                    <label for="st-name">Name:</label>
                    <input type="text" id="st-name" required>
                </div>
                <div class="form-group">
                    <label for="st-description">Description:</label>
                    <textarea id="st-description"></textarea>
                </div>
                <div class="form-group">
                    <label for="st-color">Color:</label>
                    <input type="color" id="st-color" value="#007bff">
                </div>
                <div class="form-actions">
                    <button type="button" onclick="closeModal()" class="btn-secondary">Cancel</button>
                    <button type="button" onclick="saveSessionType()" class="btn-primary">Save</button>
                </div>
            `;
        case 'assignment':
            return `
                <div class="form-group">
                    <label for="assignment-subject">Subject:</label>
                    <select id="assignment-subject" required>
                        <option value="">Loading...</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="assignment-teacher">Teacher:</label>
                    <select id="assignment-teacher" required>
                        <option value="">Loading...</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="assignment-group">Section:</label>
                    <select id="assignment-group" required>
                        <option value="">Loading...</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="assignment-hours">Hours per Week:</label>
                    <input type="number" id="assignment-hours" min="1" max="20" required>
                </div>
                <div class="form-actions">
                    <button type="button" onclick="closeModal()" class="btn-secondary">Cancel</button>
                    <button type="button" onclick="saveAssignment()" class="btn-primary">Save</button>
                </div>
            `;
        case 'timeslot':
            return `
                <div class="form-group">
                    <label for="timeslot-day">Day of Week:</label>
                    <select id="timeslot-day" required>
                        <option value="Monday">Monday</option>
                        <option value="Tuesday">Tuesday</option>
                        <option value="Wednesday">Wednesday</option>
                        <option value="Thursday">Thursday</option>
                        <option value="Friday">Friday</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="timeslot-start">Start Time:</label>
                    <input type="time" id="timeslot-start" required>
                </div>
                <div class="form-group">
                    <label for="timeslot-end">End Time:</label>
                    <input type="time" id="timeslot-end" required>
                </div>
                <div class="form-actions">
                    <button type="button" onclick="closeModal()" class="btn-secondary">Cancel</button>
                    <button type="button" onclick="saveTimeslot()" class="btn-primary">Save</button>
                </div>
            `;
        case 'generate-timeslot-structure':
            return `
                <div class="form-group">
                    <label for="day-start-time">Day Start Time:</label>
                    <input type="time" id="day-start-time" value="09:00" required>
                    <small class="form-help">When does the academic day start?</small>
                </div>
                <div class="form-group">
                    <label for="day-end-time">Day End Time:</label>
                    <input type="time" id="day-end-time" value="17:00" required>
                    <small class="form-help">When does the academic day end?</small>
                </div>
                <div class="form-group">
                    <label for="lecture-duration">Lecture Duration (minutes):</label>
                    <input type="number" id="lecture-duration" value="60" min="30" max="180" step="15" required>
                    <small class="form-help">How long is each lecture?</small>
                </div>
                <div class="form-group">
                    <label for="break-duration">Break Between Lectures (minutes):</label>
                    <input type="number" id="break-duration" value="10" min="0" max="60" step="5" required>
                    <small class="form-help">Time gap between consecutive lectures</small>
                </div>
                <div class="form-group">
                    <label for="lunch-start">Lunch Break Start Time:</label>
                    <input type="time" id="lunch-start" value="12:00" required>
                    <small class="form-help">When does lunch break start?</small>
                </div>
                <div class="form-group">
                    <label for="lunch-end">Lunch Break End Time:</label>
                    <input type="time" id="lunch-end" value="13:00" required>
                    <small class="form-help">When does lunch break end?</small>
                </div>
                <div class="form-group">
                    <label>Select Days:</label>
                    <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(80px, 1fr)); gap: 5px; margin-top: 5px;">
                        <label><input type="checkbox" name="days" value="Monday" checked> Mon</label>
                        <label><input type="checkbox" name="days" value="Tuesday" checked> Tue</label>
                        <label><input type="checkbox" name="days" value="Wednesday" checked> Wed</label>
                        <label><input type="checkbox" name="days" value="Thursday" checked> Thu</label>
                        <label><input type="checkbox" name="days" value="Friday" checked> Fri</label>
                        <label><input type="checkbox" name="days" value="Saturday" checked> Sat</label>
                        <label><input type="checkbox" name="days" value="Sunday"> Sun</label>
                    </div>
                </div>
                <div class="form-group">
                    <label>
                        <input type="checkbox" id="clear-existing">
                        Clear existing timeslots before generating
                    </label>
                    <small class="form-help">Warning: This will delete all existing timeslots</small>
                </div>
                <div class="form-actions">
                    <button type="button" onclick="closeModal()" class="btn-secondary">Cancel</button>
                    <button type="button" onclick="generateTimeslotStructure()" class="btn-primary">Generate Structure</button>
                </div>
            `;
        case 'teacher-preference':
            return `
                <div class="form-group">
                    <label for="pref-teacher">Teacher:</label>
                    <select id="pref-teacher" required>
                        <option value="">Loading...</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="pref-day">Day of Week:</label>
                    <select id="pref-day" required>
                        <option value="Monday">Monday</option>
                        <option value="Tuesday">Tuesday</option>
                        <option value="Wednesday">Wednesday</option>
                        <option value="Thursday">Thursday</option>
                        <option value="Friday">Friday</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="pref-start">Start Time:</label>
                    <input type="time" id="pref-start" required>
                </div>
                <div class="form-group">
                    <label for="pref-end">End Time:</label>
                    <input type="time" id="pref-end" required>
                </div>
                <div class="form-group">
                    <label for="pref-type">Preference Type:</label>
                    <select id="pref-type" required>
                        <option value="PREFERRED">Preferred</option>
                        <option value="AVOID">Avoid</option>
                        <option value="BLOCKED">Blocked</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="pref-weight">Weight (1-10):</label>
                    <input type="number" id="pref-weight" min="1" max="10" value="1" required>
                </div>
                <div class="form-actions">
                    <button type="button" onclick="closeModal()" class="btn-secondary">Cancel</button>
                    <button type="button" onclick="saveTeacherPreference()" class="btn-primary">Save</button>
                </div>
            `;
        case 'delete-timeslots':
            return `
                <div class="form-group">
                    <h3>Delete Timeslots Options</h3>
                    <p>Choose how you want to delete timeslots:</p>
                </div>
                <div class="form-group">
                    <label for="delete-day">Delete by Day:</label>
                    <select id="delete-day">
                        <option value="">Select a day...</option>
                        <option value="Monday">Monday</option>
                        <option value="Tuesday">Tuesday</option>
                        <option value="Wednesday">Wednesday</option>
                        <option value="Thursday">Thursday</option>
                        <option value="Friday">Friday</option>
                    </select>
                    <button type="button" onclick="deleteTimeslotsByDay(document.getElementById('delete-day').value)" class="btn-danger" style="margin-top: 10px;">Delete Day Timeslots</button>
                </div>
                <div class="form-group">
                    <hr>
                    <p><strong>⚠️ Warning:</strong> This will delete ALL timeslots. Use with caution!</p>
                    <button type="button" onclick="deleteAllTimeslots()" class="btn-danger">Delete All Timeslots</button>
                </div>
                <div class="form-actions">
                    <button type="button" onclick="closeModal()" class="btn-secondary">Close</button>
                </div>
            `;
        case 'delete-timetable':
            const stats = window.timetableStats || { total_slots: 0 };
            return `
                <div class="form-group">
                    <h3>Delete Timetable Options</h3>
                    <p><strong>Total Timetable Slots:</strong> ${stats.total_slots || 0}</p>
                </div>
                <div class="form-group">
                    <label for="delete-section">Delete by Section:</label>
                    <select id="delete-section">
                        <option value="">Select a section...</option>
                        ${(stats.by_section || []).map(s =>
                `<option value="${s.section_id}">${s.program_name} - ${s.section_name} (${s.slot_count} slots)</option>`
            ).join('')}
                    </select>
                    <button type="button" onclick="deleteTimetableBySection(document.getElementById('delete-section').value)" class="btn-danger" style="margin-top: 10px;">Delete Section Timetable</button>
                </div>
                <div class="form-group">
                    <label for="delete-teacher">Delete by Teacher:</label>
                    <select id="delete-teacher">
                        <option value="">Select a teacher...</option>
                        ${(stats.by_teacher || []).map(t =>
                `<option value="${t.teacher_id}">${t.name} (${t.slot_count} slots)</option>`
            ).join('')}
                    </select>
                    <button type="button" onclick="deleteTimetableByTeacher(document.getElementById('delete-teacher').value)" class="btn-danger" style="margin-top: 10px;">Delete Teacher Timetable</button>
                </div>
                <div class="form-group">
                    <label for="delete-timetable-day">Delete by Day:</label>
                    <select id="delete-timetable-day">
                        <option value="">Select a day...</option>
                        ${(stats.by_day || []).map(d =>
                `<option value="${d.day_of_week}">${d.day_of_week} (${d.slot_count} slots)</option>`
            ).join('')}
                    </select>
                    <button type="button" onclick="deleteTimetableByDay(document.getElementById('delete-timetable-day').value)" class="btn-danger" style="margin-top: 10px;">Delete Day Timetable</button>
                </div>
                <div class="form-group">
                    <label for="delete-room">Delete by Room:</label>
                    <select id="delete-room">
                        <option value="">Select a room...</option>
                        ${(stats.by_room || []).map(r =>
                `<option value="${r.room_id}">${r.name} (${r.slot_count} slots)</option>`
            ).join('')}
                    </select>
                    <button type="button" onclick="deleteTimetableByRoom(document.getElementById('delete-room').value)" class="btn-danger" style="margin-top: 10px;">Delete Room Timetable</button>
                </div>
                <div class="form-group">
                    <hr>
                    <p><strong>⚠️ WARNING:</strong> This will delete ALL timetable slots. This action cannot be undone!</p>
                    <button type="button" onclick="deleteAllTimetable()" class="btn-danger">Delete All Timetable</button>
                </div>
                <div class="form-actions">
                    <button type="button" onclick="closeModal()" class="btn-secondary">Close</button>
                </div>
            `;
        default:
            return '<p>Unknown form type</p>';
    }
}

async function loadFormData(type, id) {
    try {
        let endpoint;
        if (type === 'group') {
            endpoint = 'sections';
        } else if (type === 'assignment') {
            endpoint = 'subject_assignments';
        } else if (type === 'session-type') {
            endpoint = 'session_types';
        } else {
            endpoint = type + 's';
        }
        const response = await fetch(`/api/${endpoint}/${id}`);
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        const data = await response.json();

        switch (type) {
            case 'teacher':
                document.getElementById('teacher-name').value = data.name || '';
                document.getElementById('teacher-email').value = data.email || '';
                break;
            case 'room':
                document.getElementById('room-name').value = data.name || '';
                document.getElementById('room-capacity').value = data.capacity || '';
                document.getElementById('room-type').value = data.type || '';
                break;
            case 'subject':
                document.getElementById('subject-name').value = data.name || '';
                document.getElementById('subject-room-type').value = data.requires_room_type || '';
                break;
            case 'group':
                document.getElementById('group-name').value = data.section_name || '';
                document.getElementById('group-year').value = data.year || '';
                document.getElementById('group-size').value = data.size || '';
                await loadProgramsForForm(data.program_id);
                break;
            case 'session-type':
                document.getElementById('st-name').value = data.name || '';
                document.getElementById('st-description').value = data.description || '';
                document.getElementById('st-color').value = data.color || '#007bff';
                break;
            case 'assignment':
                document.getElementById('assignment-hours').value = data.hours_per_week || '';
                await loadSubjectsForForm(data.subject_id);
                await loadTeachersForForm(data.teacher_id);
                await loadGroupsForForm(data.section_id);
                break;
        }
    } catch (error) {
        console.error('Error loading form data:', error);
        showToast('Error loading data', 'error');
    }
}

async function loadProgramsForForm(selectedId = null) {
    console.log('Loading programs for form...');
    try {
        const response = await fetch('/api/programs');
        console.log('Programs API response status:', response.status);
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        const programs = await response.json();
        console.log('Programs loaded:', programs.length);
        const select = document.getElementById('group-program');
        select.innerHTML = '<option value="">Select Program</option>';
        programs.forEach(program => {
            const option = document.createElement('option');
            option.value = program.program_id;
            option.textContent = program.name;
            if (selectedId && program.program_id == selectedId) option.selected = true;
            select.appendChild(option);
        });
        console.log('Programs dropdown populated successfully');
    } catch (error) {
        console.error('Error loading programs:', error);
        const select = document.getElementById('group-program');
        select.innerHTML = '<option value="">Error loading programs</option>';
        showToast('Failed to load programs. Please try again.', 'error');
    }
}

async function loadSubjectsForForm(selectedId = null) {
    console.log('Loading subjects for form...');
    try {
        const response = await fetch('/api/subjects');
        console.log('Subjects API response status:', response.status);
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        const subjects = await response.json();
        console.log('Subjects loaded:', subjects.length);
        const select = document.getElementById('assignment-subject');
        select.innerHTML = '<option value="">Select Subject</option>';
        subjects.forEach(subject => {
            const option = document.createElement('option');
            option.value = subject.subject_id;
            option.textContent = subject.name;
            if (selectedId && subject.subject_id == selectedId) option.selected = true;
            select.appendChild(option);
        });
        console.log('Subjects dropdown populated successfully');
    } catch (error) {
        console.error('Error loading subjects:', error);
        const select = document.getElementById('assignment-subject');
        select.innerHTML = '<option value="">Error loading subjects</option>';
        showToast('Failed to load subjects. Please try again.', 'error');
    }
}

async function loadTeachersForForm(selectedId = null) {
    console.log('Loading teachers for form...');
    try {
        const response = await fetch('/api/teachers');
        console.log('Teachers API response status:', response.status);
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        const teachers = await response.json();
        console.log('Teachers loaded:', teachers.length);
        const select = document.getElementById('assignment-teacher');
        select.innerHTML = '<option value="">Select Teacher</option>';
        teachers.forEach(teacher => {
            const option = document.createElement('option');
            option.value = teacher.teacher_id;
            option.textContent = teacher.name;
            if (selectedId && teacher.teacher_id == selectedId) option.selected = true;
            select.appendChild(option);
        });
        console.log('Teachers dropdown populated successfully');
    } catch (error) {
        console.error('Error loading teachers:', error);
        const select = document.getElementById('assignment-teacher');
        select.innerHTML = '<option value="">Error loading teachers</option>';
        showToast('Failed to load teachers. Please try again.', 'error');
    }
}

async function loadGroupsForForm(selectedId = null) {
    try {
        const response = await fetch('/api/sections');
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        const groups = await response.json();
        const select = document.getElementById('assignment-group');
        select.innerHTML = '<option value="">Select Group</option>';
        groups.forEach(group => {
            const option = document.createElement('option');
            option.value = group.section_id;
            option.textContent = `${group.program_name} - ${group.section_name}`;
            if (selectedId && group.section_id == selectedId) option.selected = true;
            select.appendChild(option);
        });
    } catch (error) {
        console.error('Error loading groups:', error);
        const select = document.getElementById('assignment-group');
        select.innerHTML = '<option value="">Error loading groups</option>';
        showToast('Failed to load groups. Please try again.', 'error');
    }
}

// Save functions
async function saveTeacher() {
    const name = document.getElementById('teacher-name').value.trim();
    const email = document.getElementById('teacher-email').value.trim();

    if (!name || !email) {
        showToast('Please fill in all required fields', 'warning');
        return;
    }

    // Email format validation (CRITICAL BUG #1)
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        showToast('Please enter a valid email address', 'warning');
        return;
    }

    const data = { name, email };
    const method = currentEditId ? 'PUT' : 'POST';
    const url = currentEditId ? `/api/teachers/${currentEditId}` : '/api/teachers';

    try {
        const response = await fetch(url, {
            method,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });

        if (response.ok) {
            closeModal();
            loadTeachers();
            loadDashboardStats();
            showToast(`Teacher ${currentEditId ? 'updated' : 'added'} successfully`, 'success');
        } else {
            const error = await response.json();
            showToast(error.error || 'Error saving teacher', 'error');
        }
    } catch (error) {
        console.error('Error saving teacher:', error);
        showToast('Error saving teacher', 'error');
    }
}

async function saveRoom() {
    const name = document.getElementById('room-name').value.trim();
    const capacity = parseInt(document.getElementById('room-capacity').value);
    const type = document.getElementById('room-type').value;

    if (!name || !capacity || !type) {
        showToast('Please fill in all required fields', 'warning');
        return;
    }

    const data = { name, capacity, type };
    const method = currentEditId ? 'PUT' : 'POST';
    const url = currentEditId ? `/api/rooms/${currentEditId}` : '/api/rooms';

    try {
        const response = await fetch(url, {
            method,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });

        if (response.ok) {
            closeModal();
            loadRooms();
            loadDashboardStats();
            showToast(`Room ${currentEditId ? 'updated' : 'added'} successfully`, 'success');
        } else {
            const error = await response.json();
            showToast(error.error || 'Error saving room', 'error');
        }
    } catch (error) {
        console.error('Error saving room:', error);
        showToast('Error saving room', 'error');
    }
}

async function saveSubject() {
    const name = document.getElementById('subject-name').value.trim();
    const requires_room_type = document.getElementById('subject-room-type').value || null;

    if (!name) {
        showToast('Please fill in all required fields', 'warning');
        return;
    }

    const data = { name, requires_room_type };
    const method = currentEditId ? 'PUT' : 'POST';
    const url = currentEditId ? `/api/subjects/${currentEditId}` : '/api/subjects';

    try {
        const response = await fetch(url, {
            method,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });

        if (response.ok) {
            closeModal();
            loadSubjects();
            loadDashboardStats();
            showToast(`Subject ${currentEditId ? 'updated' : 'added'} successfully`, 'success');
        } else {
            const error = await response.json();
            showToast(error.error || 'Error saving subject', 'error');
        }
    } catch (error) {
        console.error('Error saving subject:', error);
        showToast('Error saving subject', 'error');
    }
}

async function saveGroup() {
    const section_name = document.getElementById('group-name').value.trim();
    const program_id = parseInt(document.getElementById('group-program').value);
    const year = parseInt(document.getElementById('group-year').value);
    const size = parseInt(document.getElementById('group-size').value);

    if (!program_id || !year || !size) {
        showToast('Please fill in all required fields', 'warning');
        return;
    }

    const data = { section_name: section_name || null, program_id, year, size };
    const method = currentEditId ? 'PUT' : 'POST';
    const url = currentEditId ? `/api/sections/${currentEditId}` : '/api/sections';

    try {
        const response = await fetch(url, {
            method,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });

        if (response.ok) {
            closeModal();
            loadGroups();
            loadDashboardStats();
            showToast(`Section ${currentEditId ? 'updated' : 'added'} successfully`, 'success');
        } else {
            const error = await response.json();
            showToast(error.error || 'Error saving section', 'error');
        }
    } catch (error) {
        console.error('Error saving section:', error);
        showToast('Error saving section', 'error');
    }
}

async function saveAssignment() {
    const subject_id = parseInt(document.getElementById('assignment-subject').value);
    const teacher_id = parseInt(document.getElementById('assignment-teacher').value);
    const section_id = parseInt(document.getElementById('assignment-group').value);
    const hours_per_week = parseInt(document.getElementById('assignment-hours').value);

    if (!subject_id || !teacher_id || !section_id || !hours_per_week) {
        showToast('Please fill in all required fields', 'warning');
        return;
    }

    const data = { subject_id, teacher_id, section_id, hours_per_week };
    const method = currentEditId ? 'PUT' : 'POST';
    const url = currentEditId ? `/api/subject_assignments/${currentEditId}` : '/api/subject_assignments';

    try {
        const response = await fetch(url, {
            method,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });

        if (response.ok) {
            closeModal();
            loadAssignments();
            showToast(`Assignment ${currentEditId ? 'updated' : 'added'} successfully`, 'success');
        } else {
            const error = await response.json();
            showToast(error.error || 'Error saving assignment', 'error');
        }
    } catch (error) {
        console.error('Error saving assignment:', error);
        showToast('Error saving assignment', 'error');
    }
}

async function saveTimeslot() {
    const day_of_week = document.getElementById('timeslot-day').value;
    const start_time = document.getElementById('timeslot-start').value;
    const end_time = document.getElementById('timeslot-end').value;

    if (!day_of_week || !start_time || !end_time) {
        showToast('Please fill in all required fields', 'warning');
        return;
    }

    const data = { day_of_week, start_time, end_time };
    const method = currentEditId ? 'PUT' : 'POST';
    const url = currentEditId ? `/api/timeslots/${currentEditId}` : '/api/timeslots';

    try {
        const response = await fetch(url, {
            method,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });

        if (response.ok) {
            closeModal();
            loadTimeslots();
            showToast(`Timeslot ${currentEditId ? 'updated' : 'added'} successfully`, 'success');
        } else {
            const error = await response.json();
            showToast(error.error || 'Error saving timeslot', 'error');
        }
    } catch (error) {
        console.error('Error saving timeslot:', error);
        showToast('Error saving timeslot', 'error');
    }
}

function closeModal() {
    document.getElementById('modal').style.display = 'none';
    currentEditId = null;
    currentEditType = null;
}

// Toast notification functions
function showToast(message, type = 'info') {
    const toast = document.getElementById('toast');
    const toastMessage = document.getElementById('toast-message');

    toastMessage.textContent = message;
    toast.className = `toast ${type}`;
    toast.style.display = 'block';

    // Auto-hide after 3 seconds
    setTimeout(() => {
        toast.style.display = 'none';
    }, 3000);
}

// Enhanced delete functions with confirmation
async function deleteTeacher(id) {
    if (confirm('Are you sure you want to delete this teacher? This action cannot be undone.')) {
        showLoading(true);
        try {
            const response = await fetch(`/api/teachers/${id}`, {
                method: 'DELETE'
            });

            if (response.ok) {
                loadTeachers();
                loadDashboardStats();
                showToast('Teacher deleted successfully', 'success');
            } else {
                const error = await response.json();
                showToast(error.error || 'Error deleting teacher', 'error');
            }
        } catch (error) {
            console.error('Error deleting teacher:', error);
            showToast('Error deleting teacher', 'error');
        } finally {
            showLoading(false);
        }
    }
}

async function deleteRoom(id) {
    if (confirm('Are you sure you want to delete this room? This action cannot be undone.')) {
        showLoading(true);
        try {
            const response = await fetch(`/api/rooms/${id}`, {
                method: 'DELETE'
            });

            if (response.ok) {
                loadRooms();
                loadDashboardStats();
                showToast('Room deleted successfully', 'success');
            } else {
                const error = await response.json();
                showToast(error.error || 'Error deleting room', 'error');
            }
        } catch (error) {
            console.error('Error deleting room:', error);
            showToast('Error deleting room', 'error');
        } finally {
            showLoading(false);
        }
    }
}

async function deleteSubject(id) {
    if (confirm('Are you sure you want to delete this subject? This action cannot be undone.')) {
        showLoading(true);
        try {
            const response = await fetch(`/api/subjects/${id}`, {
                method: 'DELETE'
            });

            if (response.ok) {
                loadSubjects();
                loadDashboardStats();
                showToast('Subject deleted successfully', 'success');
            } else {
                const error = await response.json();
                showToast(error.error || 'Error deleting subject', 'error');
            }
        } catch (error) {
            console.error('Error deleting subject:', error);
            showToast('Error deleting subject', 'error');
        } finally {
            showLoading(false);
        }
    }
}

async function deleteGroup(id) {
    if (confirm('Are you sure you want to delete this section? This action cannot be undone.')) {
        showLoading(true);
        try {
            const response = await fetch(`/api/sections/${id}`, {
                method: 'DELETE'
            });

            if (response.ok) {
                loadGroups();
                loadDashboardStats();
                showToast('Section deleted successfully', 'success');
            } else {
                const error = await response.json();
                showToast(error.error || 'Error deleting section', 'error');
            }
        } catch (error) {
            console.error('Error deleting section:', error);
            showToast('Error deleting section', 'error');
        } finally {
            showLoading(false);
        }
    }
}

async function deleteAssignment(id) {
    if (confirm('Are you sure you want to delete this assignment? This action cannot be undone.')) {
        showLoading(true);
        try {
            const response = await fetch(`/api/subject_assignments/${id}`, {
                method: 'DELETE'
            });

            if (response.ok) {
                loadAssignments();
                showToast('Assignment deleted successfully', 'success');
            } else {
                const error = await response.json();
                showToast(error.error || 'Error deleting assignment', 'error');
            }
        } catch (error) {
            console.error('Error deleting assignment:', error);
            showToast('Error deleting assignment', 'error');
        } finally {
            showLoading(false);
        }
    }
}

// Loading indicator
function showLoading(show) {
    const loadingElements = document.querySelectorAll('.loading');
    loadingElements.forEach(el => {
        el.style.display = show ? 'inline-block' : 'none';
    });
}

// Save teacher preference
async function saveTeacherPreference() {
    const teacher_id = parseInt(document.getElementById('pref-teacher').value);
    const day_of_week = document.getElementById('pref-day').value;
    const start_time = document.getElementById('pref-start').value;
    const end_time = document.getElementById('pref-end').value;
    const preference_type = document.getElementById('pref-type').value;
    const weight = parseInt(document.getElementById('pref-weight').value);

    if (!teacher_id || !day_of_week || !start_time || !end_time) {
        showToast('Please fill in all required fields', 'warning');
        return;
    }

    try {
        const response = await fetch('/api/teacher-preferences', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                teacher_id,
                day_of_week,
                start_time,
                end_time,
                preference_type,
                weight
            })
        });

        if (response.ok) {
            closeModal();
            loadTeacherPreferences(teacher_id);
            showToast('Preference saved successfully', 'success');
        } else {
            const error = await response.json();
            showToast(error.error || 'Error saving preference', 'error');
        }
    } catch (error) {
        console.error('Error saving preference:', error);
        showToast('Error saving preference', 'error');
    }
}

// Load teachers for preference form
document.addEventListener('DOMContentLoaded', function () {
    // Load teachers when preference modal is shown
    const originalShowModal = window.showModal;
    window.showModal = function (title, type, id) {
        originalShowModal(title, type, id);
        if (type === 'teacher-preference') {
            loadTeachersForPreferenceForm();
        }
    };
});

async function loadTeachersForPreferenceForm() {
    try {
        const response = await fetch('/api/teachers');
        const teachers = await response.json();
        const select = document.getElementById('pref-teacher');
        select.innerHTML = '<option value="">Select Teacher</option>';
        teachers.forEach(teacher => {
            const option = document.createElement('option');
            option.value = teacher.teacher_id;
            option.textContent = teacher.name;
            select.appendChild(option);
        });
    } catch (error) {
        console.error('Error loading teachers:', error);
    }
}

// Show delete timeslot options
function showDeleteTimeslotOptions() {
    showModal('Delete Timeslots', 'delete-timeslots');
}

// Show delete timetable options
function showDeleteTimetableOptions() {
    // Load statistics first
    loadTimetableStats().then(() => {
        showModal('Delete Timetable', 'delete-timetable');
    });
}

// Load timetable statistics
async function loadTimetableStats() {
    try {
        const response = await fetch('/api/timetable/stats');
        const stats = await response.json();
        window.timetableStats = stats; // Store for use in modal
        return stats;
    } catch (error) {
        console.error('Error loading timetable stats:', error);
        return null;
    }
}

// Initialize modal form data loading for new forms
document.addEventListener('DOMContentLoaded', function () {
    // Modal form initialization is handled in showModal
});
