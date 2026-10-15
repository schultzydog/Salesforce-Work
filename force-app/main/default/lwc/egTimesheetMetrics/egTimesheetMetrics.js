import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';

//import imperative apex methods...
import queryTimecards from '@salesforce/apex/egTimesheetMetrics_Ctlr.queryTimecards';
import queryTimecardsByDate from '@salesforce/apex/egTimesheetMetrics_Ctlr.queryTimecardsByDate';

//import static resources...
import FontAwesomePro from '@salesforce/resourceUrl/FontAwesomePro';

export default class EgTimesheetMetrics extends LightningElement {

    loading = false;

    @api timecardId;
    complianceYear;

    @api userid;

    data = {};
    rows = [];
    error;

    detailsIcon = "(+)";
    showDetails = true;

    numberOfRows = 5;
    tableHeight = 0;

    selectedDate;

    underForty = false;

    connectedCallback() {
        //load FontAwesome...
        loadStyle(this, FontAwesomePro + '/css/all.css')

        this.init();
    }

    refresh () {
        this.init();
    }
    
    init() {

        this.loading = true;

        console.log("id");
        console.log(this.timecardId);
        
        this.tableHeight = (25 * (this.numberOfRows + 1));

        var css = document.body.style;

        this.tableHeight = "" + this.tableHeight + "px";

        css.setProperty('--tableHeight', this.tableHeight);

        queryTimecards({timecardId: this.timecardId, userid: this.userid})
        .then((result) => {
            console.log('success');
            console.log(JSON.parse(JSON.stringify(result)));
            this.data = result;
            this.rows = result.rows || [];
            this.complianceYear = result.complianceYear || new Date().getFullYear();
            this.selectedDate = result.d;

            let rows = this.rows;
            let rowArray = [];
    
            for (var i = 0; i< rows.length; i++) {
                
                if (!this.underForty || rows[i].hours < 40) {
                    rowArray.push(rows[i]);
                }
    
            }
    
            this.rows = rowArray;

        })
        .catch((error) => {
            console.log('error');
            console.log(error);
        })
        .finally(() => {
            this.loading = false;
        });

    }

    toggleDetails() {
        this.showDetails = !this.showDetails;

        if (this.showDetails) {
            this.detailsIcon = "(-)";
        } else {
            this.detailsIcon = "(+)";
        }
    }

    selectDate(event) {
        var date = event.target.dataset.date;
        console.log('date');
        console.log(date);

        this.selectedDate = date;

        const custEvent = new CustomEvent(
            'selectdate', {
                detail: date 
            });
        this.dispatchEvent(custEvent);

    }

    @api
    updateMetrics() {
        console.log('child update');

        this.refresh();

        /*
        queryTimecardsByDate({d: this.selectedDate})
        .then((result) => {
            console.log('success');
            console.log(JSON.parse(JSON.stringify(result)));
            this.data = result;
            this.compliance = result.compliance;
            console.log(JSON.parse(JSON.stringify(this.data)));
        })
        .catch((error) => {
            console.log('error');
            console.log(error);
        })
        .finally(() => {
            
        });
        */
    }

    toggleSwitch(event) {
        console.log('switch:');
        var checked = event.target.checked;
        console.log(checked);

        let rows = this.data.rows || [];
        let rowArray = [];

        this.underForty = checked;

        for (var i = 0; i< rows.length; i++) {
            
            if (!this.underForty || rows[i].hours < 40) {
                rowArray.push(rows[i]);
            }

        }

        this.rows = rowArray;

    }

}