import { LightningElement ,wire , api, track } from "lwc";
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import getSections from '@salesforce/apex/GGW_ApplicationCtrl.getSections';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/GGW_Grant_Application__c.Id';
import GRANTNAME_FIELD from '@salesforce/schema/GGW_Grant_Application__c.Name';

export default class GgwGrantApplication extends NavigationMixin(LightningElement) {
	@api
	recordId;
	@api
	objectApiName;
    @api grantName;
    displayTitle;
    
	closeModal() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}

    
    toggleIconName = 'utility:preview';
    toggleButtonLabel = 'Add Content';

    sections = [];

    @wire(getRecord, {recordId: '$recordId',fields: [GRANTNAME_FIELD]})
        wireGrantApp({error,data}){
            if (data) {
                console.log('Grant Name: '+data.fields.Name.value);
                this.grantName = data.fields.Name.value;
                this.displayTitle = 'Grant Application: ' + data.fields.Name.value;
                this.error = undefined;
            }else if(error){
                console.log(error);
                this.error = error;
                //this.sections = undefined;
            }else{
                // eslint-disable-next-line no-console
                console.log('unknown error');
            }
        }
    //grant;
    /*
    get grantname() {
        this.grantName = this.grant
        ? this.grant.fields.Name.value
        : null;
        return this.grant.data
            ? this.grant.data.fields.Name.value
            : null;
    }
*/
    @wire(getSections)
    wireIntro({error,data}){
        if (data) {

            for(var i=0; i<data.length; i++)  {
                if(data[i].selected == true){
                    this.sections = [...this.sections ,{label: data[i].label, value: data[i].recordid, hasblocks: data[i].hasblocks, textblock: 'Text placeholder'} ];  
                }
            }                
            this.error = undefined;
        }else if(error){
            console.log(error);
            this.error = error;
            this.sections = undefined;
        }else{
            // eslint-disable-next-line no-console
            console.log('unknown error')
        }
    }

    exportGrantPdf(){
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Grant_Preview'
            }
        });
    }

    updateGrant(){
        
    }
    // when the component is first initialized assign an initial value to the `greekLetter` variable
    //connectedCallback() {
        //this.greekLetter = this.getRandomGreekLetter();
        //this.displayTitle = 'Grant Application: ' + this.grant.data ? this.grant.data.fields.Name.value : null;
    //}

    // Handles click on the 'Show/hide content' button
    /**
    handleToggleClick() {
        // retrieve the classList from the specific element
        const contentBlockClasslist = this.template.querySelector(
            '.lgc-id_content-toggle'
        ).classList;
        // toggle the hidden class
        contentBlockClasslist.toggle('slds-hidden');

        // if the current icon-name is `utility:preview` then change it to `utility:hide`
        if (this.toggleIconName === 'utility:preview') {
            this.toggleIconName = 'utility:hide';
            this.toggleButtonLabel = 'Add content';
        } else {
            this.toggleIconName = 'utility:preview';
            this.toggleButtonLabel = 'Add content';
        }
    }
*/
}