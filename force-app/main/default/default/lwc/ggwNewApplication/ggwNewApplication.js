import { LightningElement , api, wire } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import getSections from '@salesforce/apex/GGW_ApplicationCtrl.getSections'; 
import findSections from '@salesforce/apex/GGW_ApplicationCtrl.findSections';
import newGrant from '@salesforce/apex/GGW_ApplicationCtrl.newGrant';
/** The delay used when debouncing event handlers before invoking Apex method. */
const DELAY = 300;

export default class GgwNewApplication extends NavigationMixin(LightningElement) {
    error;
    _title = 'New Grant Application';
    message = 'New grant was created';
    variant = 'success';
    @api availableActions = [];
    // --List of checkobxes gested section
    value = []; //['Statement of need','Plan of action','Budget narrative']; // Sample recommends selected items
    options = []; // List of Suggested sections
    searchKey = ''; // Seach key for find Sections
    // ---

    // --Search for sections
    valueSectionAdd = [];
    optionsSectionAdd = [];
    // ---

    // --New Grant name & Status combo box
    grantNameValue;
    statusValue;
    // ---
    get statusOptions() {
        return [
            { label: 'New', value: 'New' },
            { label: 'Progress', value: 'Progress' },
            { label: 'Submited', value: 'Submited' },
            { label: 'Complete', value: 'Complete' },
            { label: 'Rejected', value: 'Rejected' },
        ];
    }
    // Status changes combo box handler
    handleStatusChange(event){
        this.statusValue = event.detail.value;
    }
    handleGrantNameChange(event) {
        this.grantNameValue = event.detail.value;
    }

    @wire(findSections, { searchKey: '$searchKey' })
        wireFoundSections({error,data}){
            if (data) {
                this.optionsSectionAdd = []; // Clear list to reset values
                for(var i=0; i<data.length; i++)  {
                    this.optionsSectionAdd = [...this.optionsSectionAdd ,{label: data[i].label, value: data[i].recordid} ];  
                    if(data[i].selected == true){
                        this.valueSectionAdd.push(data[i].recordid);
                    }
                }                
                this.error = undefined;
                
            }else if(error){
                console.log(error);
                this.error = error;
                this.optionsSectionAdd = undefined;
            }else{
                // eslint-disable-next-line no-console
                console.log('unknown error')
            }
        }

    // Select new section found from Search action
    handleNewSectionAdd(e){
        this.valueSectionAdd = e.detail.value;
        console.log('Select Section: '+e.detail.value);
        // Include selected section to Grap application list
        // Collection has CSV list ov values need to split and get element/s selected by this event
        const selArr = this.valueSectionAdd; //.split(',');
        console.log('Split array: '+this.valueSectionAdd);
        for(var i=0; i<this.optionsSectionAdd.length; i++)  {
            // Get label
            console.log('Section ID: '+this.optionsSectionAdd[i].value);
            if(this.optionsSectionAdd[i].value == this.valueSectionAdd){
                console.log('Add section: '+this.optionsSectionAdd[i].label+' ID:'+this.optionsSectionAdd[i].value);
                // Lets push select new section to main list
                this.options.push(this.optionsSectionAdd[i]);
                this.value.push(this.optionsSectionAdd[i].value);
            }
    /*    
            for(var j=0; j<selArr.length; j++){
                if(this.optionsSectionAdd[i].value === selArr[j]){
                    console.log('Add section: '+this.optionsSectionAdd[i]);
                    // Lets push select new section to main list
                    this.options.push(this.optionsSectionAdd[i]);
                }
            }*/
        }
    }

    // Seach method
    handleSectionSearchChange(event) {
        // Debouncing this method: Do not update the reactive property as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            this.searchKey = searchKey;
        }, DELAY);
    }

    // CREATE NEW Section - use standard page layout
    // Navigate to New Section record page
    handleNewSection(){
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'GGW_Section__c',
                actionName: 'new'
            }
        });  
    }

/** Sample data for options
    get options() {
        return [
            { label: 'Statement of need', value: 'Statement of need' },
            { label: 'Program narrative', value: 'Program narrative' },
            { label: 'Plan of action', value: 'Plan of action' },
            { label: 'Goals and objectives', value: 'Goals and objectives' },
            { label: 'Measurable outcomes', value: 'Measurable outcomes' },
            { label: 'Budget narrative', value: 'Budget narrative' },

        ];
    }
*/
    @wire(getSections)
        wireSugestedSection({error,data}){
            if (data) {

                for(var i=0; i<data.length; i++)  {
                    this.options = [...this.options ,{label: data[i].label, value: data[i].recordid} ];  
                    if(data[i].selected == true){
                        this.value.push(data[i].recordid);
                    }
                }                
                this.error = undefined;
            }else if(error){
                console.log(error);
                this.error = error;
            }else{
		        // eslint-disable-next-line no-console
		        console.log('unknown error')
            }
        }


    get selectedValues() {
        return this.value.join(',');
    }

    handleIncludeSectionChange(e) {
        this.value = e.detail.value;
    }

    // Create new Grant application event handler
    // Will dispatch DFlow event
    handleApplicationRecordCreate(){
        if(this.grantNameValue != null){
            // Create record/s for new app save and continue to next
            newGrant({name: this.grantNameValue, sections: this.value})
            .then((result) => {
                //this.contacts = result;
                console.log('NEW GRANT: '+JSON.stringify(result));
                this.error = undefined;

                // check if NEXT is allowed on this screen
                console.log('NEXT Try Navigate IF FLOW');
                if (this.availableActions.find((action) => action === 'NEXT')) {
                    // navigate to the next screen
                    console.log('Navigate FLOW NEXT IF Action is OK');
                    const navigateNextEvent = new FlowNavigationNextEvent();
                    this.dispatchEvent(navigateNextEvent);
                }
                this.message = 'New Grant Application was created with ID: ';
                this.variant = 'success';
            })
            .catch((error) => {
                this.error = error;
                //this.contacts = undefined;
                this.message = this.error;
                this.variant = 'error';
            });
        }else{
            this.message = 'Please provide a name to create a Grant application.';
            this.variant = 'warning';
        }
        // Display toaster message
        const evt = new ShowToastEvent({
                title: this._title,
                message: this.message,
                variant: this.variant,
        });
        this.dispatchEvent(evt);
    
    }
}