import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import customPermission_clientPortalSelfServiceAdministration from '@salesforce/customPermission/Client_Portal_Self_Service_Administration';

export default class ClientPortal_Home extends NavigationMixin(LightningElement) {


    connectedCallback(){
        if(customPermission_clientPortalSelfServiceAdministration){
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'Subscribers__c'
                }
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'Political_Risk_Dashboard__c'
                }
            });
        }
    }
}