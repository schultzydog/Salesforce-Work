import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import getMyActivities from '@salesforce/apex/OutlookEventReviewController.getMyActivities';
import updateEventAccount from '@salesforce/apex/OutlookEventReviewController.updateEventAccount';
import activeProjectsForAccount from '@salesforce/apex/OutlookEventReviewController.activeProjectsForAccount';
import deleteTimeEntryForEvent from '@salesforce/apex/OutlookEventReviewController.deleteTimeEntryForEvent';
import updateTimeEntryTask from '@salesforce/apex/OutlookEventReviewController.updateTimeEntryTask';
import saveTimeEntry from '@salesforce/apex/OutlookEventReviewController.saveTimeEntry';
import deleteEvent from '@salesforce/apex/OutlookEventReviewController.deleteEvent';

const DAY_MS = 24 * 60 * 60 * 1000;

/* The component tab still sits in the LEX workspace. Lock scroll on body
   while this panel is open so the viewport-sized list does not rubber-band.
   Component CSS cannot reach those nodes, so the rules go on document.body
   and come off in disconnectedCallback. */
const WORKSPACE_LOCK_CSS = `
body.eg-outlook-event-review-lock,
body.eg-outlook-event-review-lock .viewport,
body.eg-outlook-event-review-lock .stage,
body.eg-outlook-event-review-lock .slds-template_default,
body.eg-outlook-event-review-lock .oneCenterStage,
body.eg-outlook-event-review-lock .centerstage,
body.eg-outlook-event-review-lock .scroller,
body.eg-outlook-event-review-lock .slds-scrollable,
body.eg-outlook-event-review-lock .slds-scrollable_y {
    overscroll-behavior: none !important;
}
body.eg-outlook-event-review-lock {
    overflow: hidden !important;
}`;

export default class EgOutlookEventReview extends LightningElement {
    allRows = [];
    eventWindow = 'past';
    timeEntryFilter = 'all';
    sortField = 'activityDate';
    sortDirection = 'desc';
    isLoading = false;
    fromDate;
    toDate;
    nowMillis = Date.now();
    nowTimer;
    savesInFlight = {};

    eventWindowOptions = [
        { label: 'All', value: 'all' },
        { label: 'Past events', value: 'past' },
        { label: 'Upcoming events', value: 'upcoming' }
    ];

    timeEntryFilterOptions = [
        { label: 'All', value: 'all' },
        { label: 'With time entry', value: 'with' },
        { label: 'Without time entry', value: 'without' }
    ];

    connectedCallback() {
        this._lockStyle = document.createElement('style');
        this._lockStyle.innerText = WORKSPACE_LOCK_CSS;
        document.body.appendChild(this._lockStyle);
        document.body.classList.add('eg-outlook-event-review-lock');
        this.fromDate = this.toIsoDate(new Date(Date.now() - 180 * DAY_MS));
        this.toDate = this.toIsoDate(new Date(Date.now() + 90 * DAY_MS));
        this.nowMillis = Date.now();
        this.nowTimer = setInterval(() => {
            this.nowMillis = Date.now();
        }, 30000);
        this._onResize = () => this.syncLayout();
        window.addEventListener('resize', this._onResize);
        this.loadRows();
    }

    renderedCallback() {
        this.syncLayout();
    }

    disconnectedCallback() {
        document.body.classList.remove('eg-outlook-event-review-lock');
        if (this._lockStyle) {
            this._lockStyle.remove();
            this._lockStyle = null;
        }
        if (this.nowTimer) {
            clearInterval(this.nowTimer);
            this.nowTimer = null;
        }
        if (this._onResize) {
            window.removeEventListener('resize', this._onResize);
            this._onResize = null;
        }
    }

    syncLayout() {
        this.syncPanelHeight();
        this.syncHeaderScrollbarGutter();
    }

    syncPanelHeight() {
        const panel = this.template.querySelector('.list-view');
        if (!panel) {
            return;
        }
        const top = panel.getBoundingClientRect().top;
        const nextHeight = Math.max(window.innerHeight - top - 12, 320) + 'px';
        if (panel.style.height !== nextHeight) {
            panel.style.height = nextHeight;
        }
    }

    /**
     * Body has a vertical scrollbar; pad the static header by that width so
     * columns stay aligned with the scrolling rows.
     */
    syncHeaderScrollbarGutter() {
        const body = this.template.querySelector('.table-body');
        const shell = this.template.querySelector('.table-shell');
        if (!body || !shell) {
            return;
        }
        const width = Math.max(body.offsetWidth - body.clientWidth, 0) + 'px';
        if (shell.style.getPropertyValue('--body-scrollbar-width') !== width) {
            shell.style.setProperty('--body-scrollbar-width', width);
        }
    }

    get visibleRows() {
        let rows = this.allRows;
        const now = this.nowMillis;
        if (this.eventWindow === 'upcoming') {
            rows = rows.filter((row) => this.eventStartMillis(row) > now);
        } else if (this.eventWindow === 'past') {
            rows = rows.filter((row) => this.eventStartMillis(row) <= now);
        }
        if (this.timeEntryFilter === 'with') {
            rows = rows.filter((row) => row.hasTimeEntry);
        } else if (this.timeEntryFilter === 'without') {
            rows = rows.filter((row) => !row.hasTimeEntry);
        }
        const direction = this.sortDirection === 'asc' ? 1 : -1;
        return [...rows].sort((left, right) => {
            const leftValue = left[this.sortField] || '';
            const rightValue = right[this.sortField] || '';
            if (leftValue < rightValue) {
                return -1 * direction;
            }
            if (leftValue > rightValue) {
                return 1 * direction;
            }
            return 0;
        }).map((row, index) => ({
            ...row,
            rowNumber: index + 1
        }));
    }

    get isEmpty() {
        return !this.isLoading && this.visibleRows.length === 0;
    }

    get listMeta() {
        const count = this.visibleRows.length;
        const items = count === 1 ? '1 item' : count + ' items';
        const sortLabels = {
            activityDate: 'Start Date/Time',
            subject: 'Subject',
            accountName: 'Account'
        };
        const sortLabel = sortLabels[this.sortField] || 'Start Date/Time';
        const windowLabels = {
            all: 'All',
            upcoming: 'Upcoming',
            past: 'Past'
        };
        const windowLabel = windowLabels[this.eventWindow] || 'Past';
        const filterLabels = {
            all: 'Time entry',
            with: 'Time entry (with)',
            without: 'Time entry (without)'
        };
        return items + ' • ' + windowLabel + ' • Sorted by ' + sortLabel + ' • Filtered by ' + filterLabels[this.timeEntryFilter];
    }

    get dateHeaderClass() {
        return this.sortableHeaderClass('col-date');
    }

    get subjectHeaderClass() {
        return this.sortableHeaderClass('col-subject');
    }

    get accountHeaderClass() {
        return this.sortableHeaderClass('col-account');
    }

    get dateSortIcon() {
        return this.sortIconName('activityDate', 'desc');
    }

    get subjectSortIcon() {
        return this.sortIconName('subject', 'asc');
    }

    get accountSortIcon() {
        return this.sortIconName('accountName', 'asc');
    }

    sortableHeaderClass(columnClass) {
        return columnClass + ' sortable header-box';
    }

    sortIconName(field, defaultDirection) {
        const direction = this.sortField === field ? this.sortDirection : defaultDirection;
        return direction === 'asc' ? 'utility:arrowup' : 'utility:arrowdown';
    }

    handleFromDateChange(event) {
        this.fromDate = event.target.value;
        this.loadRows();
    }

    handleToDateChange(event) {
        this.toDate = event.target.value;
        this.loadRows();
    }

    handleEventWindowChange(event) {
        this.eventWindow = event.detail.value;
        this.sortField = 'activityDate';
        this.sortDirection = this.eventWindow === 'upcoming' ? 'asc' : 'desc';
    }

    handleTimeEntryFilterChange(event) {
        this.timeEntryFilter = event.detail.value;
    }

    eventStartMillis(row) {
        if (row && row.startMillis != null && row.startMillis !== '') {
            const stamped = Number(row.startMillis);
            if (!Number.isNaN(stamped)) {
                return stamped;
            }
        }
        if (!row || !row.activityDate) {
            return 0;
        }
        const parsed = new Date(row.activityDate).getTime();
        return Number.isNaN(parsed) ? 0 : parsed;
    }

    handleSortDate() {
        this.toggleSort('activityDate');
    }

    handleSortSubject() {
        this.toggleSort('subject');
    }

    handleSortAccount() {
        this.toggleSort('accountName');
    }

    toggleSort(field) {
        if (this.sortField === field) {
            this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortField = field;
            this.sortDirection = field === 'activityDate' ? 'desc' : 'asc';
        }
    }

    async loadRows() {
        this.isLoading = true;
        try {
            const data = await getMyActivities({
                startDate: this.fromDate,
                endDate: this.toDate
            });
            this.allRows = (data || []).map((row) => this.decorateRow(row));
        } catch (error) {
            this.toast('Error', this.extractError(error), 'error');
            this.allRows = [];
        } finally {
            this.isLoading = false;
        }
    }

    decorateRow(row) {
        const projectId = row.suggestedProjectId || null;
        const attendees = row.attendees || [];
        return {
            ...row,
            rowKey: row.id,
            accountId: row.accountId || null,
            accountName: row.accountName || null,
            suggestedProjectId: projectId,
            suggestedProjectName: row.suggestedProjectName || null,
            projectTaskId: row.projectTaskId || null,
            projectTaskName: row.projectTaskName || null,
            ...this.formatDateParts(row.activityDate),
            noProject: !projectId,
            // Templates can't join a list, so each name carries its own trailing comma.
            attendees: attendees.map((person, index) => ({
                ...person,
                separator: index < attendees.length - 1 ? ', ' : ''
            }))
        };
    }

    handleHoursBlur(event) {
        const row = this.findRow(event.currentTarget.dataset.rowId);
        if (!row) {
            return;
        }
        const value = event.currentTarget.value;
        if (value === row.hours) {
            return;
        }
        row.hours = value;
        this.allRows = [...this.allRows];
        this.saveRow(row);
    }

    async handleAccountChange(event) {
        const row = this.findRow(event.currentTarget.dataset.rowId);
        if (!row) {
            return;
        }
        const rowId = row.id;
        const accountId = event.detail.value || null;
        row.accountId = accountId;
        row.accountName = event.detail.selection || null;
        row.accountUrl = accountId ? '/' + accountId : null;
        // A project belongs to an account and a task belongs to a project, so
        // both have to drop when the account moves.
        row.suggestedProjectId = null;
        row.suggestedProjectName = null;
        row.projectTaskId = null;
        row.projectTaskName = null;
        this.redecorateRow(rowId);
        try {
            await updateEventAccount({ eventId: rowId, accountId: accountId });
            await this.discardTimeEntry(rowId);
            if (accountId) {
                await this.adoptOnlyProject(rowId, accountId);
            }
        } catch (error) {
            this.toast('Error', this.extractError(error), 'error');
        }
    }

    async handleProjectChange(event) {
        const row = this.findRow(event.currentTarget.dataset.rowId);
        if (!row) {
            return;
        }
        const rowId = row.id;
        const projectId = event.detail.value || null;
        row.suggestedProjectId = projectId;
        row.suggestedProjectName = event.detail.selection || null;
        row.projectTaskId = null;
        row.projectTaskName = null;
        this.redecorateRow(rowId);
        try {
            // The linked entry logs the project that was just replaced, so it
            // goes whether the project was cleared or swapped for another one.
            await this.discardTimeEntry(rowId);
        } catch (error) {
            this.toast('Error', this.extractError(error), 'error');
            return;
        }
        if (projectId) {
            this.saveRow(this.findRow(rowId));
        }
    }

    redecorateRow(rowId) {
        this.allRows = this.allRows.map((item) =>
            item.id === rowId ? this.decorateRow(item) : item
        );
    }

    /**
     * Deletes the time entry the row is linked to. Called whenever the account
     * or project changes, because the entry logs work the row no longer claims.
     */
    async discardTimeEntry(rowId) {
        const row = this.findRow(rowId);
        if (!row || !row.timeEntryId) {
            return;
        }
        await deleteTimeEntryForEvent({ eventId: rowId });
        row.timeEntryId = null;
        row.hasTimeEntry = false;
        this.redecorateRow(rowId);
    }

    /**
     * Only fills in a project when switching accounts leaves exactly one
     * choice. Page load never prepopulates.
     */
    async adoptOnlyProject(rowId, accountId) {
        const projects = await activeProjectsForAccount({ accountId: accountId });
        if (!projects || projects.length !== 1) {
            return;
        }
        const row = this.findRow(rowId);
        if (!row) {
            return;
        }
        row.suggestedProjectId = projects[0].Id;
        row.suggestedProjectName = projects[0].Name;
        this.redecorateRow(rowId);
        await this.saveRow(this.findRow(rowId));
    }

    async handleTaskChange(event) {
        const row = this.findRow(event.currentTarget.dataset.rowId);
        if (!row) {
            return;
        }
        const rowId = row.id;
        row.projectTaskId = event.detail.value || null;
        row.projectTaskName = event.detail.selection || null;
        this.redecorateRow(rowId);
        const current = this.findRow(rowId);
        if (!current.timeEntryId) {
            this.saveRow(current);
            return;
        }
        // An entry is valid with or without a task, so the existing record is
        // retagged rather than replaced.
        try {
            await updateTimeEntryTask({
                eventId: rowId,
                projectTaskId: current.projectTaskId
            });
        } catch (error) {
            this.toast('Error', this.extractError(error), 'error');
        }
    }

    async handleDelete(event) {
        const row = this.findRow(event.currentTarget.dataset.rowId);
        if (!row) {
            return;
        }
        const confirmed = await LightningConfirm.open({
            label: 'Delete event and time entry',
            message: `Delete "${row.subject || 'this event'}" and its time entry?`,
            theme: 'error'
        });
        if (!confirmed) {
            return;
        }
        try {
            await deleteEvent({ recordId: row.id });
            this.allRows = this.allRows.filter((item) => item.id !== row.id);
            this.toast('Deleted', 'Event and time entry deleted.', 'success');
        } catch (error) {
            this.toast('Error', this.extractError(error), 'error');
        }
    }

    findRow(rowId) {
        return this.allRows.find((row) => row.id === rowId);
    }

    async saveRow(row) {
        if (this.savesInFlight[row.id]) {
            return;
        }
        this.savesInFlight[row.id] = true;
        try {
            if (!row.suggestedProjectId || !(parseFloat(row.hours) > 0)) {
                return;
            }
            const timeEntryId = await saveTimeEntry({
                eventId: row.id,
                workDate: row.workDate,
                hoursWorked: parseFloat(row.hours),
                projectId: row.suggestedProjectId,
                projectTaskId: row.projectTaskId
            });
            if (timeEntryId && timeEntryId !== row.timeEntryId) {
                row.timeEntryId = timeEntryId;
                row.hasTimeEntry = true;
                this.redecorateRow(row.id);
            }
        } catch (error) {
            this.toast('Error', this.extractError(error), 'error');
        } finally {
            this.savesInFlight[row.id] = false;
        }
    }

    formatDateParts(value) {
        if (!value) {
            return { displayDate: '', displayTime: '' };
        }
        const when = new Date(value);
        return {
            displayDate: new Intl.DateTimeFormat('en-US', {
                year: 'numeric',
                month: 'short',
                day: '2-digit'
            }).format(when),
            displayTime: new Intl.DateTimeFormat('en-US', {
                hour: 'numeric',
                minute: '2-digit'
            }).format(when)
        };
    }

    toIsoDate(value) {
        const year = value.getFullYear();
        const month = String(value.getMonth() + 1).padStart(2, '0');
        const day = String(value.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    extractError(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        return 'Something went wrong.';
    }
}
