import { api, LightningElement, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { CurrentPageReference } from 'lightning/navigation';

//import custom labels...
import Timesheets_Project_Task_Guidance from "@salesforce/label/c.Timesheets_Project_Task_Guidance";

//import static resources...
import FontAwesomePro from '@salesforce/resourceUrl/FontAwesomePro';

//import imperative apex...
import getTimesheetForDateApex from '@salesforce/apex/egTimesheet_Ctlr.getTimesheetForDateApex';
import saveTimesheetApex from '@salesforce/apex/egTimesheet_Ctlr.saveTimesheetApex';

//import field picklist values
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import LOCATION_MONDAY from '@salesforce/schema/EG_Time_Card__c.Location_Monday__c';

const RELEASE_2024_03 = new Date(2024, 2, 3, 0, 0, 0).toISOString().slice(0, 10); //March 3, 2023

export default class EgTimesheet extends LightningElement {
	//Private
	isWorking = true;
	isChanging = true;
	isDirty = false;
	wrapper;
	columnTotals = [];
	rowTotals = [];
	weeklyTotal = 0;
	values = [];
	error = null;
	timout = null;
	isTimesheetAdmin = false;
	dateString = null;
	locationOptions = [{ label: "", value: "" }];
	projectAndTaskGuidance = (Timesheets_Project_Task_Guidance && Timesheets_Project_Task_Guidance.toLowerCase()!='hidden') ? Timesheets_Project_Task_Guidance : null;

	@wire(CurrentPageReference)
	currentPageReference;

	@wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: LOCATION_MONDAY })
	locationPicklistValues({ error, data }) {
		console.log("locationPicklistValues", data, error);
		if (data && data.values && Array.isArray(data.values) && data.values.length > 0) {
			this.locationOptions = [...this.locationOptions, ...data.values];
		} else {
			/*
            if(this.locationOptions.length===1){
                //unable to retrieve picklist values dynamically...
                let dataValues = [{label: 'IO - All EG', value: 'IO - All EG'},
                                  {label: 'IO - Team', value: 'IO - Team'},
                                  {label: 'IO - Choice', value: 'IO - Choice'},
                                  {label: 'WFH', value: 'WFH'},
                                  {label: 'Excused - Travel / Client', value: 'Excused - Travel / Client'},
                                  {label: 'Excused - Offsite / Event', value: 'Excused - Offsite / Event'},
                                  {label: 'Excused - Sick WFH', value: 'Excused - Sick WFH'},
                                  {label: 'Excused - Other', value: 'Excused - Other'}];
                this.locationOptions = [...this.locationOptions, ...dataValues];
            }    
            */
		}
	}

	//UI Getters
	get saveButtonLabel() {
		let label = "Saved";
		if (this.isWorking) {
			label = "Saving";
		} else {
			if (this.isDirty) {
				label = "Save";
			} else {
				label = "Saved";
			}
		}
		return label;
	}
	get saveButtonDisabled() {
		return this.isWorking || !this.isDirty;
	}
	get weeklyTotalIconClass() {
		return this.weeklyTotal >= 40 ? "fas fa-badge-check success" : this.wrapper.isFuture ? "fal fa-star-half-alt warning" : "fas fa-times fail";
	}
	get isWorkingClass() {
		return this.isWorking ? "disabled" : "";
	}

	get showWorkingLocations() {
		return (
			this.wrapper &&
			this.wrapper.timeCardUser &&
			this.wrapper.timeCardUser.Id &&
			!this.wrapper.timeCardUser.Remote__c &&
			this.wrapper.timeCard &&
			this.locationOptions
		);
	}

	connectedCallback() {
		//lightning-input text-align hack - CSS Styling Hooks not available for text-align for inputs...
		const inputAligncenter = document.createElement("style");
		inputAligncenter.innerText = `.input-text-align_center input{ text-align: center!important; }`;
		document.body.appendChild(inputAligncenter);

		//load FontAwesome...
		loadStyle(this, FontAwesomePro + "/css/all.css");

		//initialize timesheet...
		this.init();
	}

	init = async () => {
		//initialize timesheet...
		console.log("connectedCallback init...");
		console.log("date");
		console.log("Param: " + this.currentPageReference.state?.c__date);
		this.getTimesheetForDate(); //no date will default to today
	};

	getTimesheetForDate(selectedDate, prefill) {
		//centralized getTimesheet method (you can send in a specific date or leave it blank for today)...
		console.log("getTimesheetForDateApex...", selectedDate);

		this.isWorking = true;
		this.error = null;

		let timeCardUserId = this.wrapper && this.wrapper.timeCardUser ? this.wrapper.timeCardUser.Id : null;
		getTimesheetForDateApex({ selectedDate: selectedDate, timeCardUserId: timeCardUserId, prefill: prefill }) //no date will default to today in apex
			.then((result) => {
				this.wrapper = result;

				//prepare Working Locations module...
				if (this.wrapper.dates && Array.isArray(this.wrapper.dates) && this.wrapper.dates.length > 0 && this.wrapper.dates.length <= 7) {
					//left label...
					this.wrapper.locationDateLabelMonday = this.wrapper.dates[1];
					this.wrapper.locationDateLabelTuesday = this.wrapper.dates[2];
					this.wrapper.locationDateLabelWednesday = this.wrapper.dates[3];
					this.wrapper.locationDateLabelThursday = this.wrapper.dates[4];
					this.wrapper.locationDateLabelFriday = this.wrapper.dates[5];
					//placeholder
					this.wrapper.locationPlaceholderMonday = "Select Location"; //'Monday ' + this.wrapper.dates[1];
					this.wrapper.locationPlaceholderTuesday = "Select Location"; //'Tuesday ' + this.wrapper.dates[2];
					this.wrapper.locationPlaceholderWednesday = "Select Location"; //'Wednesday ' + this.wrapper.dates[3];
					this.wrapper.locationPlaceholderThursday = "Select Location"; //'Thursday ' + this.wrapper.dates[4];
					this.wrapper.locationPlaceholderFriday = "Select Location"; //'Friday ' + this.wrapper.dates[5];
				}

				console.log("getTimesheetForDateApex result", result);

				this.isTimesheetAdmin = this.wrapper.runningUser.PermissionSetAssignments && this.wrapper.runningUser.PermissionSetAssignments.length == 1;

				if (this.wrapper.startDate >= RELEASE_2024_03) {
					this.wrapper.projectLookupParams = [this.wrapper.startDate, this.wrapper.endDate];
				}

				this.calculate();
			})
			.catch((error) => {
				this.error = JSON.stringify(error);
				console.error("getTimesheetForDateApex error", this.error);
			})
			.finally(() => {
				this.isDirty = false;
				this.isWorking = false;
				this.isChanging = false;
			});
	}

	calculate() {
		//calculate and refresh the UI side (row totals, column totals and weekly totals)
		this.weeklyTotal = 0;

		this.columnTotals = [
			{ total: 0, index: 0 },
			{ total: 0, index: 1 },
			{ total: 0, index: 2 },
			{ total: 0, index: 3 },
			{ total: 0, index: 4 },
			{ total: 0, index: 5 },
			{ total: 0, index: 6 },
		];

		for (var i = 0; i < this.wrapper.rows.length; i++) {
			this.rowTotals[i] = 0;
			this.values[i] = [];
			for (var j = 0; j < this.wrapper.rows[i].hours.length; j++) {
				this.rowTotals[i] += this.wrapper.rows[i].hours[j];
				this.columnTotals[j].total += this.wrapper.rows[i].hours[j];
				this.values[i][j] = this.wrapper.rows[i].hours[j];
				this.wrapper.rows[i].cells[j].cellClass = j == 0 || j == 6 ? "cell-hours weekend" : "cell-hours weekday";
				this.columnTotals[j].cellClass = j == 0 || j == 6 ? "slds-text-align_center weekend" : "slds-text-align_center weekday";
			}
			this.wrapper.rows[i].rowTotal = this.rowTotals[i];
			this.weeklyTotal += this.rowTotals[i];

			//only allow hours input if project and task selected...
			if (this.wrapper.startDate >= RELEASE_2024_03) {
				this.wrapper.rows[i].hoursDisabled = this.wrapper.rows[i].noProject || this.wrapper.rows[i].noTask;
			} else {
				this.wrapper.rows[i].hoursDisabled = this.wrapper.rows[i].noProject;
			}
		}
	}

	save() {
		//centralized save() routine...
		console.log("saveTimesheet...", this.wrapper);

		this.isWorking = true;

		let timeCardUserId = this.wrapper && this.wrapper.timeCardUser ? this.wrapper.timeCardUser.Id : null;
		let workingLocations = [
			this.wrapper.timeCard.Location_Monday__c,
			this.wrapper.timeCard.Location_Tuesday__c,
			this.wrapper.timeCard.Location_Wednesday__c,
			this.wrapper.timeCard.Location_Thursday__c,
			this.wrapper.timeCard.Location_Friday__c,
		];
		console.log("workingLocations", workingLocations);
		saveTimesheetApex({
			timeCardId: this.wrapper.timeCardId,
			timeCardUserId: timeCardUserId,
			startDate: this.wrapper.startDate,
			rows: this.wrapper.rows,
			workingLocations: workingLocations,
		})
			.then((result) => {
				console.log("saveTimesheet result", result);
			})
			.catch((error) => {
				this.error = JSON.stringify(error);
				console.error("saveTimesheet error", this.error);
			})
			.finally(() => {
				this.isDirty = false;
				this.isWorking = false;
				this.isChanging = false;

				this.template.querySelector("c-eg-timesheet-metrics").updateMetrics();
			});
	}

	handleFocus(event) {
		//auto select everything in the cell...
		event.target.selectionStart = 0;
		if (event.target.value) {
			event.target.selectionEnd = event.target.value.toString().length;
		} else {
			event.target.selectionEnd = 0;
		}
	}

	handleChange(event) {
		this.isDirty = true;

		//get values from custom dispatch event "select"...
		let type = event.target.type;
		let value = event.target.value;
		let selection = event.target.selection;

		//bind working location picklists...
		let locationName = event.target.name;
		let locationValue = event.detail.value;
		if (locationName && locationName.indexOf("Location_") === 0) {
			this.wrapper.timeCard[locationName] = locationValue;
		}

		if (type == "EG_Project__c") {
			//Project has changed...
			console.log("Handle Project change...");

			let rowIndex = event.target.closest("tr").getAttribute("data-rowid");
			console.log("handleChange for row: ", rowIndex, type, value, selection);

			if (value) {
				//Project is selected...
				this.wrapper.rows[rowIndex].projectId = value;
				this.wrapper.rows[rowIndex].projectName = selection;
				this.wrapper.rows[rowIndex].noProject = false;
			} else {
				//No Project selected...
				if (rowIndex == this.wrapper.rows.length - 1) {
					//if last row, clear the row's values...
					this.wrapper.rows[rowIndex].projectId = null;
					this.wrapper.rows[rowIndex].projectName = null;
					this.wrapper.rows[rowIndex].noProject = true;

					//also clear selected task...
					this.wrapper.rows[rowIndex].taskId = null;
					this.wrapper.rows[rowIndex].taskName = null;
					this.wrapper.rows[rowIndex].noTask = true;

					//clear time entries because no project...
					this.wrapper.rows[rowIndex].hours = [0, 0, 0, 0, 0, 0, 0];
					this.wrapper.rows[rowIndex].cells = [
						{ hours: 0, index: 0 },
						{ hours: 0, index: 1 },
						{ hours: 0, index: 2 },
						{ hours: 0, index: 3 },
						{ hours: 0, index: 4 },
						{ hours: 0, index: 5 },
						{ hours: 0, index: 6 },
					];
				} else {
					//remove this row...
					this.wrapper.rows.splice(rowIndex, 1);
				}
			}

			//only allow hours input if project and task selected...
			if (this.wrapper.startDate >= RELEASE_2024_03) {
				this.wrapper.rows[rowIndex].hoursDisabled = this.wrapper.rows[rowIndex].noProject || this.wrapper.rows[rowIndex].noTask;
			} else {
				this.wrapper.rows[rowIndex].hoursDisabled = this.wrapper.rows[rowIndex].noProject;
			}
		} else if (type == "EG_Project_Task__c") {
			//Task has changed...
			console.log("Handle Task change...");
			let rowIndex = event.target.closest("tr").getAttribute("data-rowid");
			console.log("handleChange for row: ", rowIndex, type, value, selection);

			if (value) {
				//Task is selected...
				this.wrapper.rows[rowIndex].taskId = value;
				this.wrapper.rows[rowIndex].taskName = selection;
				this.wrapper.rows[rowIndex].noTask = false;
			} else {
				//No Task selected...
				this.wrapper.rows[rowIndex].taskId = null;
				this.wrapper.rows[rowIndex].taskName = null;
				this.wrapper.rows[rowIndex].noTask = true;

				if (this.wrapper.startDate >= RELEASE_2024_03) {
					//clear time entries because no project...
					this.wrapper.rows[rowIndex].hours = [0, 0, 0, 0, 0, 0, 0];
					this.wrapper.rows[rowIndex].cells = [
						{ hours: 0, index: 0 },
						{ hours: 0, index: 1 },
						{ hours: 0, index: 2 },
						{ hours: 0, index: 3 },
						{ hours: 0, index: 4 },
						{ hours: 0, index: 5 },
						{ hours: 0, index: 6 },
					];
				}
			}

			//only allow hours input if project and task selected...
			if (this.wrapper.startDate >= RELEASE_2024_03) {
				this.wrapper.rows[rowIndex].hoursDisabled = this.wrapper.rows[rowIndex].noProject || this.wrapper.rows[rowIndex].noTask;
			} else {
				this.wrapper.rows[rowIndex].hoursDisabled = this.wrapper.rows[rowIndex].noProject;
			}
		} else if (type == "number") {
			//Hours has changed...
			console.log("Handle Hours change...");
			let rowIndex = event.target.dataset.rowid;
			let cellIndex = event.target.dataset.cellid;
			console.log("handleChange for row: ", rowIndex, cellIndex, type, value, selection);

			if (!value || isNaN(value) || value == "" || value == null || typeof value == "undefined") {
				this.wrapper.rows[rowIndex].hours[cellIndex] = 0;
				this.wrapper.rows[rowIndex].cells[cellIndex].hours = 0;
			} else {
				this.wrapper.rows[rowIndex].hours[cellIndex] = parseFloat(value);
				this.wrapper.rows[rowIndex].cells[cellIndex].hours = parseFloat(value);
			}
		} else if (type == "User") {
			console.log("Handle Time Card User change...");
			console.log("handleChange for row: ", type, value, selection);

			this.wrapper.timeCardUser.Id = value;
			this.wrapper.timeCardUser.Name = selection;

			if (this.wrapper.timeCardUser.Id) {
				this.save();
				this.init();
			}
		}

		//check last row, if any data, always ensure new row...
		let lastRow = this.wrapper.rows[this.wrapper.rows.length - 1];
		if (
			lastRow.projectId ||
			lastRow.taskId ||
			lastRow.cells[0].hours ||
			lastRow.cells[1].hours ||
			lastRow.cells[2].hours ||
			lastRow.cells[3].hours ||
			lastRow.cells[4].hours ||
			lastRow.cells[5].hours ||
			lastRow.cells[6].hours
		) {
			//there's at least on piece of data in last row, add another one...
			this.wrapper.rows.push(this.getNewRow());
		}

		//calculate and update UI in real time...
		this.calculate();

		//save after delay...
		clearTimeout(this.timeout);
		this.timeout = setTimeout(() => {
			console.log("Ready to save()...", this.wrapper);
			if (this.wrapper.timeCardUser.Id) {
				this.save();
			}
		}, 1000); //todo: get from custom metadata setting?
	}

	getNewRow() {
		//this is a template for a new row on the UI side...
		let newRow = {
			projectId: null,
			projectName: null,
			noProject: true,

			taskId: null,
			taskName: null,
			noTask: true,

			hoursDisabled: true,

			hours: [0, 0, 0, 0, 0, 0, 0],
			cells: [
				{ hours: 0, index: 0 },
				{ hours: 0, index: 1 },
				{ hours: 0, index: 2 },
				{ hours: 0, index: 3 },
				{ hours: 0, index: 4 },
				{ hours: 0, index: 5 },
				{ hours: 0, index: 6 },
			],
		};

		return newRow;
	}

	prefill() {
		//get timesheet for this week and set prefill flag to true...
		//let d = new Date(this.wrapper.timesheetDate);
		//d.setDate(d.getDate() - 7);
		this.getTimesheetForDate(this.wrapper.timesheetDate, true);
	}

	handleBack() {
		//get timesheet for previous week...
		this.isChanging = true;
		let d = new Date(this.wrapper.timesheetDate);
		d.setDate(d.getDate() - 7);
		this.getTimesheetForDate(d);
	}

	handleToday() {
		//reinitialize, get timesheet for this week...
		this.isChanging = true;
		this.init();
	}

	handleNext() {
		//get timesheet for next week...
		this.isChanging = true;
		let d = new Date(this.wrapper.timesheetDate);
		d.setDate(d.getDate() + 7);
		this.getTimesheetForDate(d);
	}

	selectDate(event) {
		var date = event.detail;
		console.log("parent date");
		console.log(date);
		this.getTimesheetForDate(date, false);
	}
}