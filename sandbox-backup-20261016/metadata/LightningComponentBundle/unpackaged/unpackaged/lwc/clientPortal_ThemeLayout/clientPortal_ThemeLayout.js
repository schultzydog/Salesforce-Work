import { LightningElement, wire, api} from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';

import FontAwesomePro from '@salesforce/resourceUrl/FontAwesomePro';
import ClientPortal from '@salesforce/resourceUrl/ClientPortal';

import { getRecord } from 'lightning/uiRecordApi';

import basePath from "@salesforce/community/basePath";

import User_Id from '@salesforce/user/Id';
import User_FirstName_Field from '@salesforce/schema/User.FirstName';
import User_LastName_Field from '@salesforce/schema/User.LastName';

import customPermission_clientPortalSelfServiceAdministration from '@salesforce/customPermission/Client_Portal_Self_Service_Administration';

/**
 * @slot sidebar
 */

export default class ClientPortal_ThemeLayout extends NavigationMixin(LightningElement) {


    //Private
    hasRendered = false; //Only initialize of first render
    pageName = 'Home';
    userFirstName = '';
    userLastName = '';
    userInitials = 'EG';

    @wire(getRecord, { recordId: User_Id, fields: [User_FirstName_Field, User_LastName_Field] }) 
    user({error, data}) {
        if (error) {
           console.log('user wire error: ', error)
        } else if (data) {
            this.userFirstName = data.fields.FirstName.value;
            this.userLastName = data.fields.LastName.value;
            this.userInitials = this.userFirstName[0] + this.userLastName[0];
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if(currentPageReference){
            this.pageName = currentPageReference.attributes.name;
        }
    }

    get logoUrl() {
        return ClientPortal + '/img/EG Logo_Horizontal_White.svg'
    }
    get navItemClassHome() {
        return this.pageName=='Home' ? 'navigation-item-container active' : 'navigation-item-container';
    }
    get navItemClassExplore() {
        return this.pageName=='Explore__c' ? 'navigation-item-container active' : 'navigation-item-container';
    }
    get navItemClassEngage() {
        return this.pageName=='Engage__c' ? 'navigation-item-container active' : 'navigation-item-container';
    }
    get navItemClassSearch() {
        return this.pageName=='Search__c' ? 'navigation-item-container active' : 'navigation-item-container';
    }
    get navItemClassProfile() {
        return this.pageName=='Profile__c' ? 'navigation-item-container active' : 'navigation-item-container';
    }
    get navItemClassPoliticalRisk() {
        return this.pageName=='Political_Risk_Dashboard__c' ? 'navigation-item-container active' : 'navigation-item-container';
    }
    get navItemClassSubscribers() {
        return this.pageName=='Subscribers__c' ? 'navigation-item-container active' : 'navigation-item-container';
    }
    get navItemClassReports() {
        return this.pageName=='Reports__c' ? 'navigation-item-container active' : 'navigation-item-container';
    }
    get isSelfServiceAdministrator() {
        return customPermission_clientPortalSelfServiceAdministration;
    }
    
  //Rendered Callback
  renderedCallback() {
      if (!this.hasRendered) {
          this.hasRendered = true;
          this.initComponent();
      }
  } //end renderedCallback
  
  //Initialize Component
  initComponent = async () => { 
      this.isWorking = true;
      
      loadStyle(this, FontAwesomePro + '/css/all.css')

      let sitePrefix = basePath.replace(/\/s$/i, ""); // site prefix is the site base path without the trailing "/s"
      this.logoutUrl = sitePrefix + "/secur/logout.jsp";
        console.log('this.logoutUrl', this.logoutUrl)
      this.isWorking = false;

        /*
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Subscribers__c'
            }
        });
        */
  }

    navigate(event) {
        let page = event.currentTarget.dataset.page;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: page
            }
        });
    }

}