import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import enrich from '@salesforce/apex/ContactEnrichmentService.enrich';

export default class ContactEnrichmentModal extends LightningModal {
    @api recordId;

    isLoading = true;
    errorMessage;
    result;

    connectedCallback() {
        this.runSearch();
    }

    get hasFacts() {
        return this.result && this.result.facts && this.result.facts.length > 0;
    }

    get hasSources() {
        return this.result && this.result.sources && this.result.sources.length > 0;
    }

    get hasKnowledge() {
        return this.result && (this.result.knowledgeTitle || this.result.knowledgeDescription);
    }

    async runSearch() {
        this.isLoading = true;
        this.errorMessage = undefined;
        try {
            this.result = await enrich({ contactId: this.recordId });
        } catch (e) {
            this.errorMessage = this.reduceError(e);
        } finally {
            this.isLoading = false;
        }
    }

    handleClose() {
        this.close();
    }

    reduceError(error) {
        if (!error) {
            return 'The search failed.';
        }
        if (typeof error === 'string') {
            return error;
        }
        if (Array.isArray(error.body)) {
            return error.body.map((item) => item.message).join(', ');
        }
        if (error.body && error.body.message) {
            return error.body.message;
        }
        return error.message || 'The search failed.';
    }
}