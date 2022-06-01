import { LightningElement , api, wire } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import getSections from '@salesforce/apex/GGW_ApplicationCtrl.getSections'; 
import findSections from '@salesforce/apex/GGW_ApplicationCtrl.findSections';
import newGrant from '@salesforce/apex/GGW_ApplicationCtrl.newGrant';
import createNewSection from '@salesforce/apex/GGW_ApplicationCtrl.createNewSection';
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
    basevalue = []; //['Statement of need','Plan of action','Budget narrative']; // Sample recommends selected items
    baseoptions = []; // List of Suggested sections

    // --Search for sections
    valueSectionAdd = [];
    optionsSectionAdd = [];
    // ---
    newSectionName;
    // --New Grant name & Status combo box
    grantNameValue;
    statusValue;
    // ---
    /** App status si deafulted not setting by user coment for now
    get statusOptions() {
        return [
            { label: 'New', value: 'New' },
            { label: 'Progress', value: 'Progress' },
            { label: 'Submited', value: 'Submited' },
            { label: 'Complete', value: 'Complete' },
            { label: 'Rejected', value: 'Rejected' },
        ];
    }
    */
    // Status changes combo box handler
    handleStatusChange(event){
        this.statusValue = event.detail.value;
    }
    handleGrantNameChange(event) {
        this.grantNameValue = event.detail.value;
    }
    // Search for existing sections taht are NOT part of suggested list
    // There can be many sections that are not suggested but can be re-used
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

    // Select new section checkbox found from Search action
    // add section to the application list
    handleNewSectionAdd(e){
        this.valueSectionAdd = e.detail.value;
        console.log('Select Section: '+e.detail.value);
        // Include selected section to Grant application list
        // Collection has list ov values as array selected by this event
        var tempSectionOptions = [];
        var tempSectionValues = [];
        for(var i=0; i<this.baseoptions.length; i++)  {
            tempSectionOptions.push(this.baseoptions[i]);
        }
        for(var i=0; i<this.basevalue.length; i++)  {
            tempSectionValues.push(this.basevalue[i]);
        }
        // Add or remove selevcted frmo search values to update Section sugested list
        for(var i=0; i<this.optionsSectionAdd.length; i++)  {
            // Get label
            console.log('Section ID: '+this.optionsSectionAdd[i].label+' '+this.optionsSectionAdd[i].value);
            for(var j=0; j<this.valueSectionAdd.length; j++){
                if(this.optionsSectionAdd[i].value == this.valueSectionAdd[j]){
                    console.log('Add section: '+this.optionsSectionAdd[i].label+' ID:'+this.optionsSectionAdd[i].value);
                    // Lets push select new section to main list
                    tempSectionOptions.push(this.optionsSectionAdd[i]);
                    tempSectionValues.push(this.optionsSectionAdd[i].value);
                }
            }
        }
        // REset
        this.options = [];
        this.options = tempSectionOptions;
        this.value = [];
        this.value = tempSectionValues;
    }

    // Search Input method - fires events when user inputs or change characters in Section search bar
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

    handleSectionInputChange(event) {
        this.newSectionName = event.detail.value;
    }
    // CREATE NEW Section - use standard page layout
    // Navigate to New Section record page not baes UX
    // Will use custom metho call instead
    handleCreateNewSection(){
        /* THIS METHOD TO NAVIAGTE STANDARD NEW RECORD
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'GGW_Section__c',
                actionName: 'new'
            }
        });  **/
        // THIS WILL CALL APEX METHOD
        if(this.newSectionName != null){
            createNewSection({name: this.newSectionName})
                .then((result) => {
                    console.log('NEW SECTION: '+JSON.stringify(result));
                    this.error = undefined;
                    // Add new section to active list on LWC client side
                    this.baseoptions.push({label: result.label, value: result.recordid});
                    this.basevalue.push(result.recordid);
                    // Reset
                    this.options = [];
                    this.options = this.baseoptions;
                    this.value = [];
                    this.value = this.basevalue;

                    this.message = 'New Section was created with ID: ';
                    this.variant = 'success';
                })
                .catch((error) => {
                    this.error = error;
                    //this.contacts = undefined;
                    this.message = this.error;
                    this.variant = 'error';
                });
        }else{
            this.message = 'Please provide a name to create a new Section.';
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
    // Intialize seggested sections list for home page
    // Used in checkbox group to select sections to use by Grant application
    @wire(getSections)
        wireSugestedSection({error,data}){
            if (data) {

                for(var i=0; i<data.length; i++)  {
                    this.options = [...this.options ,{label: data[i].label, value: data[i].recordid} ];  
                    this.baseoptions = [...this.baseoptions ,{label: data[i].label, value: data[i].recordid} ];  

                    if(data[i].selected == true){
                        this.value.push(data[i].recordid);
                        this.basevalue.push(data[i].recordid);
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
                    /*
                    console.log('NEXT Try Navigate IF FLOW');
                    if (this.availableActions.find((action) => action === 'NEXT')) {
                        // navigate to the next screen
                        console.log('Navigate FLOW NEXT IF Action is OK');
                        const navigateNextEvent = new FlowNavigationNextEvent();
                        this.dispatchEvent(navigateNextEvent);
                    }
                    */
                    this.message = 'New Grant Application was created with ID: ';
                    this.variant = 'success';

                    // Navigate to New Grant record page
                    this[NavigationMixin.Navigate]({
                            type: 'standard__navItemPage',
                            attributes: {
                                apiName: 'GGW_UI_Tester'
                            },
                            state: {
                                c__recordId: result.Id
                            }
                        });
                    /** This navi to standard Grant record page    
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: result.Id,
                            objectApiName: 'GGW_Grant_Application__c',
                            actionName: 'view'
                        }
                    }); */
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