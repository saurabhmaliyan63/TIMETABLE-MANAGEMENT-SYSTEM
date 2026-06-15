// Advanced Features JavaScript for Timetable Generator
// Includes: Manual editing, conflict detection, statistics, etc.

// ========== CONFLICT DETECTION ==========
async function loadConflicts() {
    try {
        const response = await fetch('/api/conflicts');
        const data = await response.json();
        displayConflicts(data.conflicts, data.summary);
    } catch (error) {
        console.error('Error loading conflicts:', error);
    }
}

function displayConflicts(conflicts, summary) {
    const container = document.getElementById('conflicts-container');
    if (!container) return;
    
    container.innerHTML = '';
    
    // Summary
    const summaryDiv = document.createElement('div');
    summaryDiv.className = 'conflicts-summary';
    summaryDiv.innerHTML = `
        <h3>Conflict Summary</h3>
        <div class="summary-stats">
            <div class="stat-item">
                <span class="stat-label">Total Conflicts:</span>
                <span class="stat-value error">${summary.total}</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Errors:</span>
                <span class="stat-value error">${summary.by_severity.ERROR || 0}</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Warnings:</span>
                <span class="stat-value warning">${summary.by_severity.WARNING || 0}</span>
            </div>
        </div>
    `;
    container.appendChild(summaryDiv);
    
    // Conflicts list
    if (conflicts.length === 0) {
        container.innerHTML += '<p class="no-conflicts">No conflicts detected!</p>';
        return;
    }
    
    const conflictsList = document.createElement('div');
    conflictsList.className = 'conflicts-list';
    
    conflicts.forEach(conflict => {
        const conflictItem = document.createElement('div');
        conflictItem.className = `conflict-item ${conflict.severity.toLowerCase()}`;
        conflictItem.innerHTML = `
            <div class="conflict-header">
                <span class="conflict-type">${conflict.type}</span>
                <span class="conflict-severity ${conflict.severity.toLowerCase()}">${conflict.severity}</span>
            </div>
            <div class="conflict-description">${conflict.description}</div>
            <button onclick="resolveConflict(${conflict.conflict_id})" class="btn-secondary small">Resolve</button>
        `;
        conflictsList.appendChild(conflictItem);
    });
    
    container.appendChild(conflictsList);
}

async function resolveConflict(conflictId) {
    try {
        const response = await fetch(`/api/conflicts/${conflictId}/resolve`, {
            method: 'POST'
        });
        
        if (response.ok) {
            showToast('Conflict resolved successfully', 'success');
            loadConflicts();
        } else {
            showToast('Error resolving conflict', 'error');
        }
    } catch (error) {
        console.error('Error resolving conflict:', error);
        showToast('Error resolving conflict', 'error');
    }
}

// ========== EXPORT FUNCTIONALITY ==========
async function exportTimetable(format, sectionId = null, teacherId = null) {
    try {
        // Determine current view (single class or multiple classes)
        const multipleWrapper = document.querySelector('.multiple-timetables-container');
        const activeSectionSelect = document.getElementById('section-select');

        let url;

        // If caller did not explicitly pass section/teacher, infer from UI
        if (!sectionId && activeSectionSelect && activeSectionSelect.value) {
            sectionId = activeSectionSelect.value;
        }

        if (multipleWrapper) {
            // Multiple timetables are currently displayed – gather section IDs from wrappers
            const wrappers = multipleWrapper.querySelectorAll('.single-timetable-wrapper[data-section-id]');
            const sectionIds = Array.from(wrappers)
                .map(w => parseInt(w.getAttribute('data-section-id')))
                .filter(id => !Number.isNaN(id));

            if (sectionIds.length > 1 && format === 'excel') {
                // Use dedicated multiple-export endpoint for Excel so everything is in one file
                const params = new URLSearchParams();
                params.append('section_ids', sectionIds.join(','));
                url = `/api/export-multiple/${format}?` + params.toString();
            } else if (sectionIds.length === 1) {
                // Fall back to single-section export
                sectionId = sectionIds[0];
            }
        }

        if (!url) {
            // Build URL for single-view export (current class / teacher / full)
            url = `/api/export/${format}`;
            const params = new URLSearchParams();

            if (sectionId) params.append('section_id', sectionId);
            if (teacherId) params.append('teacher_id', teacherId);

            if (params.toString()) {
                url += '?' + params.toString();
            }
        }

        const link = document.createElement('a');
        link.href = url;
        const ext = format === 'excel' ? 'xlsx' : format === 'ical' ? 'ics' : format;
        link.download = `timetable.${ext}`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        showToast(`Timetable exported as ${format.toUpperCase()}`, 'success');
    } catch (error) {
        console.error('Error exporting timetable:', error);
        showToast('Error exporting timetable', 'error');
    }
}

// ========== QUALITY METRICS ==========
async function loadQualityMetrics(versionId = null) {
    try {
        let url = '/api/quality-metrics';
        if (versionId) {
            url += '?version_id=' + versionId;
        }
        
        const response = await fetch(url);
        const metrics = await response.json();
        displayQualityMetrics(metrics);
    } catch (error) {
        console.error('Error loading quality metrics:', error);
    }
}

function displayQualityMetrics(metrics) {
    const container = document.getElementById('quality-metrics-container');
    if (!container) return;
    
    container.innerHTML = '';
    
    const metricsList = document.createElement('div');
    metricsList.className = 'metrics-list';
    
    for (const [key, value] of Object.entries(metrics)) {
        if (key === 'overall_score') continue;
        
        const metricItem = document.createElement('div');
        metricItem.className = 'metric-item';
        
        const percentage = (value * 100).toFixed(1);
        const status = value >= 0.8 ? 'good' : value >= 0.5 ? 'warning' : 'poor';
        
        metricItem.innerHTML = `
            <div class="metric-name">${key.replace('_', ' ').toUpperCase()}</div>
            <div class="metric-value ${status}">${percentage}%</div>
            <div class="metric-bar">
                <div class="metric-bar-fill ${status}" style="width: ${percentage}%"></div>
            </div>
        `;
        metricsList.appendChild(metricItem);
    }
    
    // Overall score
    if (metrics.overall_score !== undefined) {
        const overallDiv = document.createElement('div');
        overallDiv.className = 'metric-item overall-score';
        const overallPercentage = (metrics.overall_score * 100).toFixed(1);
        const overallStatus = metrics.overall_score >= 0.8 ? 'good' : metrics.overall_score >= 0.5 ? 'warning' : 'poor';
        
        overallDiv.innerHTML = `
            <div class="metric-name">OVERALL SCORE</div>
            <div class="metric-value ${overallStatus} large">${overallPercentage}%</div>
        `;
        metricsList.appendChild(overallDiv);
    }
    
    container.appendChild(metricsList);
}

// ========== MANUAL TIMETABLE EDITING ==========
let selectedSlot = null;
let editHistory = [];
let editHistoryIndex = -1;

function enableManualEditing() {
    const timetableCells = document.querySelectorAll('.timetable-cell.occupied');
    timetableCells.forEach(cell => {
        cell.classList.add('editable');
        cell.addEventListener('click', handleCellClick);
        cell.addEventListener('dragover', handleDragOver);
        cell.addEventListener('drop', handleDrop);
    });
}

function handleCellClick(event) {
    const cell = event.currentTarget;
    if (selectedSlot) {
        selectedSlot.classList.remove('selected');
    }
    cell.classList.add('selected');
    selectedSlot = cell;
    
    // Show edit options
    showEditOptions(cell);
}

function showEditOptions(cell) {
    // Remove existing options
    const existing = document.querySelector('.edit-options');
    if (existing) existing.remove();
    
    const options = document.createElement('div');
    options.className = 'edit-options';
    options.innerHTML = `
        <button onclick="moveSlot()" class="btn-secondary">Move</button>
        <button onclick="deleteSlot()" class="btn-danger">Delete</button>
        <button onclick="swapSlot()" class="btn-secondary">Swap</button>
    `;
    
    cell.appendChild(options);
}

function handleDragOver(event) {
    event.preventDefault();
    event.currentTarget.classList.add('drag-over');
}

function handleDrop(event) {
    event.preventDefault();
    event.currentTarget.classList.remove('drag-over');
    
    if (selectedSlot && selectedSlot !== event.currentTarget) {
        swapSlots(selectedSlot, event.currentTarget);
    }
}

async function moveSlot() {
    if (!selectedSlot) return;
    
    const slotId = selectedSlot.dataset.slotId;
    // Show modal to select new time/room
    showMoveSlotModal(slotId);
}

async function deleteSlot() {
    if (!selectedSlot) return;
    
    if (!confirm('Are you sure you want to delete this slot?')) return;
    
    const slotId = selectedSlot.dataset.slotId;
    try {
        const response = await fetch(`/api/timetable/slots/${slotId}`, {
            method: 'DELETE'
        });
        
        if (response.ok) {
            showToast('Slot deleted successfully', 'success');
            selectedSlot.remove();
            selectedSlot = null;
            loadTimetable();
        } else {
            showToast('Error deleting slot', 'error');
        }
    } catch (error) {
        console.error('Error deleting slot:', error);
        showToast('Error deleting slot', 'error');
    }
}

async function swapSlot() {
    if (!selectedSlot) return;
    
    // Enable selection mode for second slot
    const cells = document.querySelectorAll('.timetable-cell.occupied');
    cells.forEach(cell => {
        if (cell !== selectedSlot) {
            cell.classList.add('swap-candidate');
            cell.addEventListener('click', handleSwapClick);
        }
    });
    
    showToast('Click on another slot to swap', 'info');
}

function handleSwapClick(event) {
    const secondSlot = event.currentTarget;
    const slot1Id = selectedSlot.dataset.slotId;
    const slot2Id = secondSlot.dataset.slotId;
    
    swapSlotsAPI(slot1Id, slot2Id);
    
    // Clean up
    document.querySelectorAll('.swap-candidate').forEach(cell => {
        cell.classList.remove('swap-candidate');
        cell.removeEventListener('click', handleSwapClick);
    });
}

async function swapSlotsAPI(slot1Id, slot2Id) {
    try {
        const response = await fetch('/api/timetable/swap', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ slot1_id: slot1Id, slot2_id: slot2Id })
        });
        
        if (response.ok) {
            showToast('Slots swapped successfully', 'success');
            loadTimetable();
        } else {
            showToast('Error swapping slots', 'error');
        }
    } catch (error) {
        console.error('Error swapping slots:', error);
        showToast('Error swapping slots', 'error');
    }
}

// ========== STATISTICS DASHBOARD ==========
async function loadStatistics() {
    await Promise.all([
        loadWorkloadStatistics(),
        loadRoomUtilization(),
        loadQualityMetrics()
    ]);
}

async function loadWorkloadStatistics() {
    try {
        const response = await fetch('/api/statistics/workload');
        const stats = await response.json();
        displayWorkloadStatistics(stats);
    } catch (error) {
        console.error('Error loading workload statistics:', error);
    }
}

function displayWorkloadStatistics(stats) {
    const container = document.getElementById('workload-stats-container');
    if (!container) return;
    
    container.innerHTML = '';
    
    const table = document.createElement('table');
    table.className = 'stats-table';
    table.innerHTML = `
        <thead>
            <tr>
                <th>Teacher</th>
                <th>Total Classes</th>
                <th>Subjects</th>
                <th>Sections</th>
            </tr>
        </thead>
        <tbody>
            ${stats.map(stat => `
                <tr>
                    <td>${stat.name}</td>
                    <td>${stat.total_classes || 0}</td>
                    <td>${stat.subjects_count || 0}</td>
                    <td>${stat.sections_count || 0}</td>
                </tr>
            `).join('')}
        </tbody>
    `;
    
    container.appendChild(table);
}

async function loadRoomUtilization() {
    try {
        const response = await fetch('/api/statistics/room-utilization');
        const stats = await response.json();
        displayRoomUtilization(stats);
    } catch (error) {
        console.error('Error loading room utilization:', error);
    }
}

function displayRoomUtilization(stats) {
    const container = document.getElementById('room-utilization-container');
    if (!container) return;
    
    container.innerHTML = '';
    
    const table = document.createElement('table');
    table.className = 'stats-table';
    table.innerHTML = `
        <thead>
            <tr>
                <th>Room</th>
                <th>Type</th>
                <th>Capacity</th>
                <th>Usage Count</th>
                <th>Utilization</th>
            </tr>
        </thead>
        <tbody>
            ${stats.map(stat => {
                const utilization = stat.usage_count > 0 ? ((stat.usage_count / 50) * 100).toFixed(1) : 0;
                return `
                    <tr>
                        <td>${stat.name}</td>
                        <td>${stat.type}</td>
                        <td>${stat.capacity}</td>
                        <td>${stat.usage_count || 0}</td>
                        <td>${utilization}%</td>
                    </tr>
                `;
            }).join('')}
        </tbody>
    `;
    
    container.appendChild(table);
}

// ========== TEACHER PREFERENCES ==========
async function loadTeacherPreferences(teacherId) {
    try {
        const response = await fetch(`/api/teacher-preferences?teacher_id=${teacherId}`);
        const preferences = await response.json();
        displayTeacherPreferences(preferences);
    } catch (error) {
        console.error('Error loading teacher preferences:', error);
    }
}

function displayTeacherPreferences(preferences) {
    const container = document.getElementById('preferences-container');
    if (!container) return;
    
    container.innerHTML = '';
    
    if (preferences.length === 0) {
        container.innerHTML = '<p>No preferences set</p>';
        return;
    }
    
    preferences.forEach(pref => {
        const prefItem = document.createElement('div');
        prefItem.className = 'preference-item';
        prefItem.innerHTML = `
            <div>${pref.day_of_week} ${pref.start_time} - ${pref.end_time}</div>
            <div>${pref.preference_type}</div>
            <button onclick="deletePreference(${pref.pref_id})" class="btn-danger small">Delete</button>
        `;
        container.appendChild(prefItem);
    });
}

async function deletePreference(prefId) {
    try {
        const response = await fetch(`/api/teacher-preferences/${prefId}`, {
            method: 'DELETE'
        });
        
        if (response.ok) {
            showToast('Preference deleted successfully', 'success');
            // Reload preferences
            const teacherId = document.getElementById('teacher-pref-select').value;
            if (teacherId) loadTeacherPreferences(teacherId);
        }
    } catch (error) {
        console.error('Error deleting preference:', error);
        showToast('Error deleting preference', 'error');
    }
}

// ========== NOTIFICATIONS ==========
async function loadNotifications() {
    try {
        const response = await fetch('/api/notifications?unread_only=true');
        if (!response.ok) {
            console.error('Failed to load notifications:', response.status);
            displayNotifications([]);
            return;
        }
        const notifications = await response.json();
        // Ensure notifications is an array
        const notificationsArray = Array.isArray(notifications) ? notifications : [];
        displayNotifications(notificationsArray);
    } catch (error) {
        console.error('Error loading notifications:', error);
        displayNotifications([]);
    }
}

function displayNotifications(notifications) {
    const container = document.getElementById('notifications-container');
    if (!container) return;
    
    container.innerHTML = '';
    
    if (notifications.length === 0) {
        container.innerHTML = '<p>No new notifications</p>';
        return;
    }
    
    notifications.forEach(notif => {
        const notifItem = document.createElement('div');
        notifItem.className = `notification-item ${notif.type.toLowerCase()}`;
        notifItem.innerHTML = `
            <div class="notification-title">${notif.title}</div>
            <div class="notification-message">${notif.message}</div>
            <button onclick="markNotificationRead(${notif.notification_id})" class="btn-secondary small">Mark Read</button>
        `;
        container.appendChild(notifItem);
    });
}

async function markNotificationRead(notificationId) {
    try {
        const response = await fetch(`/api/notifications/${notificationId}/read`, {
            method: 'POST'
        });
        
        if (response.ok) {
            loadNotifications();
        }
    } catch (error) {
        console.error('Error marking notification as read:', error);
    }
}

// Initialize advanced features when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    // Load notifications on page load
    loadNotifications();
    
    // Set up periodic conflict checking (every 5 minutes)
    setInterval(loadConflicts, 5 * 60 * 1000);
});




