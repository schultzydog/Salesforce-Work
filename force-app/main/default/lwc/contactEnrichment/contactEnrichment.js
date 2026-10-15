import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ContactEnrichmentModal from 'c/contactEnrichmentModal';

export default class ContactEnrichment extends LightningElement {
    @api recordId;

    async handleOpen() {
        if (!this.recordId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No contact',
                    message: 'Open this from a Contact record.',
                    variant: 'error'
                })
            );
            return;
        }
        await ContactEnrichmentModal.open({
            size: 'large',
            recordId: this.recordId
        });
    }
}
