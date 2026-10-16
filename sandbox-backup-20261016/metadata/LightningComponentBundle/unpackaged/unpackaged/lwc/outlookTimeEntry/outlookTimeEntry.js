import { LightningElement, api } from 'lwc';
import createTimeEntry from '@salesforce/apex/TimeEntryController.createTimeEntry';
import findMatchingEvent from '@salesforce/apex/OutlookEventReviewController.findMatchingEvent';
import linkEventTimeEntry from '@salesforce/apex/OutlookEventReviewController.linkEventTimeEntry';
import deleteTimeEntryForEvent from '@salesforce/apex/OutlookEventReviewController.deleteTimeEntryForEvent';
import updateTimeEntryTask from '@salesforce/apex/OutlookEventReviewController.updateTimeEntryTask';
import activeProjectsForAccount from '@salesforce/apex/OutlookEventReviewController.activeProjectsForAccount';

/**
 * Outlook side-panel (lightning__Inbox). The only identifier it resolves is the
 * Salesforce Event, matched on owner, subject, and start time. Account comes
 * from that event; project, task, hours, and notes come only from the time
 * entry the event is linked to. Nothing is guessed when the panel opens.
 */
export default class OutlookTimeEntry extends LightningElement {
    _source;
    @api
    get source() {
        return this._source;
    }
    set source(value) {
        this._source = value;
        this.applyEmailDefaults();
        this.loadMatchingEvent();
    }

    _subject;
    @api
    get subject() {
        return this._subject;
    }
    set subject(value) {
        this._subject = value;
        this.prefillNotes();
        this.loadMatchingEvent();
    }

    _dates;
    @api
    get dates() {
        return this._dates;
    }
    set dates(value) {
        this._dates = value;
        this.prefillFromDates();
        this.loadMatchingEvent();
    }

    workDate;
    hoursWorked;
    notes;
    accountId = null;
    projectId = null;
    projectTaskId = null;
    matchedEventId = null;
    timeEntryId = null;
    matchChecked = false;

    userEditedDate = false;
    userEditedHours = false;
    userEditedNotes = false;
    userEditedAccount = false;
    userEditedProject = false;

    isSubmitting = false;
    message;
    messageVariant = 'info';
    eventRequestToken = 0;

    // Account → Project → Task. Each picker only appears once its parent is
    // set; until then a disabled stand-in holds its place, matching Event Review.
    get showProjectPicker() {
        return !!this.accountId;
    }

    get showTaskPicker() {
        return !!this.projectId;
    }

    get projectFilter() {
        return {
            criteria: [
                {
                    fieldPath: 'Status__c',
                    operator: 'eq',
                    value: 'Active'
                },
                {
                    fieldPath: 'Account__c',
                    operator: 'eq',
                    value: this.accountId
                }
            ]
        };
    }

    get taskFilter() {
        return {
            criteria: [
                {
                    fieldPath: 'Status__c',
                    operator: 'eq',
                    value: 'Active'
                },
                {
                    fieldPath: 'EG_Project__c',
                    operator: 'eq',
                    value: this.projectId
                }
            ]
        };
    }

    get isSupportedItem() {
        return this._source === 'event' || this._source === 'email';
    }

    get isEmail() {
        return this._source === 'email';
    }

    get isEvent() {
        return this._source === 'event';
    }

    get isDateReadOnly() {
        return this.isEvent;
    }

    get hasLinkedEntry() {
        return !!this.timeEntryId;
    }

    get submitLabel() {
        return this.timeEntryId ? 'Edit Time Entry' : 'Create Time Entry';
    }

    get showMatchStatus() {
        return this.isEvent && this.matchChecked;
    }

    get matchStatus() {
        if (!this.matchedEventId) {
            return 'No matching Salesforce event. A time entry can still be created.';
        }
        if (this.timeEntryId) {
            return 'Editing the time entry linked to this Salesforce event.';
        }
        return 'Matched a Salesforce event. Saving will link the new time entry to it.';
    }

    get matchStatusClass() {
        return `slds-var-m-bottom_x-small slds-text-body_small slds-text-color_${
            this.matchedEventId ? 'success' : 'weak'
        }`;
    }

    get pageMeta() {
        if (this.isEmail) {
            return this._subject ? this._subject : 'From this email';
        }
        return this._subject ? this._subject : 'From this event';
    }

    get isSubmitDisabled() {
        return (
            this.isSubmitting ||
            !this.workDate ||
            !(parseFloat(this.hoursWorked) > 0)
        );
    }

    get messageClass() {
        return `slds-var-m-top_small slds-text-color_${
            this.messageVariant === 'error' ? 'error' : 'success'
        }`;
    }

    prefillNotes() {
        if (!this.userEditedNotes && this._subject) {
            this.notes = this._subject;
        }
    }

    applyEmailDefaults() {
        if (this._source === 'email' && !this.userEditedDate && !this.workDate) {
            this.workDate = this.toIsoDate(new Date());
        }
    }

    prefillFromDates() {
        const start = this.parseDate(this._dates && this._dates.start);
        const end = this.parseDate(this._dates && this._dates.end);

        if (start && !this.userEditedDate) {
            this.workDate = this.toIsoDate(start);
        }
        if (start && end && !this.userEditedHours) {
            this.hoursWorked = this.computeHours(start, end);
        }
    }

    async loadMatchingEvent() {
        if (this._source !== 'event') {
            this.matchedEventId = null;
            this.timeEntryId = null;
            this.matchChecked = false;
            return;
        }
        const startIso = this._dates && this._dates.start;
        if (!startIso) {
            return;
        }
        const token = ++this.eventRequestToken;
        try {
            const match = await findMatchingEvent({
                subject: this._subject,
                startIso
            });
            if (token !== this.eventRequestToken) {
                return;
            }
            this.matchChecked = true;
            this.matchedEventId = match && match.id ? match.id : null;
            this.timeEntryId = match && match.timeEntryId ? match.timeEntryId : null;
            if (!match) {
                return;
            }
            if (!this.userEditedAccount) {
                this.accountId = match.accountId || null;
            }
            // Project, task, hours, and notes are only adopted from an entry
            // the event is already linked to. A matched event with no entry
            // leaves those fields alone.
            if (!match.timeEntryId) {
                return;
            }
            if (!this.userEditedProject) {
                this.projectId = match.suggestedProjectId || null;
                this.projectTaskId = match.projectTaskId || null;
            }
            if (!this.userEditedHours && match.hours) {
                this.hoursWorked = match.hours;
            }
            if (!this.userEditedNotes && match.notes) {
                this.notes = match.notes;
            }
        } catch (error) {
            if (token === this.eventRequestToken) {
                this.matchChecked = true;
                this.matchedEventId = null;
                this.timeEntryId = null;
            }
        }
    }

    parseDate(value) {
        if (!value) {
            return null;
        }
        const parsed = new Date(value);
        return isNaN(parsed.getTime()) ? null : parsed;
    }

    toIsoDate(date) {
        const year = date.getFullYear();
        const month = `${date.getMonth() + 1}`.padStart(2, '0');
        const day = `${date.getDate()}`.padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    computeHours(start, end) {
        const hours = (end.getTime() - start.getTime()) / (1000 * 60 * 60);
        const rounded = Math.round(hours * 4) / 4;
        return rounded > 0 ? rounded : 0;
    }

    handleDateChange(event) {
        this.workDate = event.target.value;
        this.userEditedDate = true;
    }

    handleHoursChange(event) {
        this.hoursWorked = event.target.value;
        this.userEditedHours = true;
    }

    handleNotesChange(event) {
        this.notes = event.target.value;
        this.userEditedNotes = true;
    }

    async handleAccountChange(event) {
        this.accountId = event.detail.recordId || null;
        this.userEditedAccount = true;
        // A project belongs to an account and a task belongs to a project, so
        // both have to drop when the account moves.
        this.projectId = null;
        this.projectTaskId = null;
        this.userEditedProject = true;
        await this.discardLinkedEntry();
        if (this.accountId) {
            await this.adoptOnlyProject(this.accountId);
        }
    }

    async handleProjectChange(event) {
        this.projectId = event.detail.recordId || null;
        this.projectTaskId = null;
        this.userEditedProject = true;
        // The linked entry logs the project that was just replaced, so it goes
        // whether the project was cleared or swapped for another one.
        await this.discardLinkedEntry();
        if (this.projectId) {
            await this.autoSaveEntry();
        }
    }

    async handleTaskChange(event) {
        this.projectTaskId = event.detail.recordId || null;
        if (!this.matchedEventId || !this.timeEntryId) {
            await this.autoSaveEntry();
            return;
        }
        // An entry is valid with or without a task, so the existing record is
        // retagged rather than replaced.
        try {
            await updateTimeEntryTask({
                eventId: this.matchedEventId,
                projectTaskId: this.projectTaskId
            });
        } catch (error) {
            this.showMessage(this.extractError(error), 'error');
        }
    }

    /**
     * Deletes the entry this event is linked to. Called whenever the account or
     * project changes, because the entry logs work the panel no longer claims.
     */
    async discardLinkedEntry() {
        if (!this.matchedEventId || !this.timeEntryId) {
            this.timeEntryId = null;
            return;
        }
        try {
            await deleteTimeEntryForEvent({ eventId: this.matchedEventId });
            this.timeEntryId = null;
        } catch (error) {
            this.showMessage(this.extractError(error), 'error');
        }
    }

    /**
     * Fills in the project only when switching accounts leaves exactly one
     * active choice. Opening the panel never prepopulates.
     */
    async adoptOnlyProject(accountId) {
        try {
            const projects = await activeProjectsForAccount({ accountId });
            if (!projects || projects.length !== 1) {
                return;
            }
            this.projectId = projects[0].Id;
            this.projectTaskId = null;
            await this.autoSaveEntry();
        } catch (error) {
            this.showMessage(this.extractError(error), 'error');
        }
    }

    /** Saves silently from a lookup change, once there is enough to log. */
    async autoSaveEntry() {
        if (!this.projectId || !this.workDate || !(parseFloat(this.hoursWorked) > 0)) {
            return;
        }
        await this.saveEntry(false);
    }

    handleSubmit() {
        return this.saveEntry(true);
    }

    async saveEntry(announce) {
        this.clearMessage();
        this.isSubmitting = true;
        try {
            const request = {
                workDate: this.workDate,
                hoursWorked: parseFloat(this.hoursWorked),
                notes: this.notes,
                projectId: this.projectId,
                projectTaskId: this.projectTaskId,
                // Set on an edit so the service updates this record instead of
                // matching on the canonical key.
                timeEntryId: this.timeEntryId,
                // Part of the canonical key, so a new entry lands on whatever
                // the event automation already drafted for this meeting.
                sourceEventId: this.matchedEventId
            };
            const result = await createTimeEntry({ request });
            this.timeEntryId = result.timeEntryId;
            if (this.matchedEventId) {
                try {
                    await linkEventTimeEntry({
                        eventId: this.matchedEventId,
                        timeEntryId: result.timeEntryId
                    });
                } catch (linkError) {
                    // Time entry already saved; linking the Event is secondary.
                }
            }
            if (announce) {
                const action = result.wasUpdated ? 'updated' : 'created';
                this.showMessage(
                    `Time entry ${action} (${result.timeEntryId}).`,
                    'success'
                );
            }
        } catch (error) {
            this.showMessage(this.extractError(error), 'error');
        } finally {
            this.isSubmitting = false;
        }
    }

    extractError(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        return 'Something went wrong creating the time entry.';
    }

    showMessage(text, variant) {
        this.message = text;
        this.messageVariant = variant;
    }

    clearMessage() {
        this.message = undefined;
    }
}