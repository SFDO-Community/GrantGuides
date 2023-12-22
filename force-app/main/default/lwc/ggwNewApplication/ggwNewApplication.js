/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement , api, wire } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import { FlowNavigationNextEvent } from 'lightning/flowSupport'; // This can be usefull if using inside Flow navigation conrol
import getSections from '@salesforce/apex/GGW_ApplicationCtrl.getSections'; 
import findSections from '@salesforce/apex/GGW_ApplicationCtrl.findSections';
import newGrant from '@salesforce/apex/GGW_ApplicationCtrl.newGrant';
import createNewSection from '@salesforce/apex/GGW_ApplicationCtrl.createNewSection';
/** The delay used when debouncing event handlers before invoking Apex method. */
const DELAY = 300;

export default class GgwNewApplication extends NavigationMixin(LightningElement) {
    error;
    _title = 'New Grant Application';
    @api availableActions = [];
    @api language = 'en_US';
    // -- List of checkobxes suggested section
    value = []; //['Statement of need','Plan of action','Budget narrative']; // Sample recommended selected Section IDs or items
    options = []; // List of Suggested sections display as checkboxes list the values show what is suggested from data
    searchKey = ''; // Search key for find Sections

    // --- Hold the original list of values temporary
    basevalue = []; //['Statement of need','Plan of action','Budget narrative']; // Sample recommends selected items
    baseoptions = []; // List of Suggested sections

    // --Search for sections
    valueSectionAdd = [];
    optionsSectionAdd = [];
    // ---
    newSectionName;
    disableSectionCreateButton = true;
    // --New Grant name & Status combo box
    grantNameValue;
    statusValue;
    // ---
    showToastSuccess(msg){
        const evt = new ShowToastEvent({
            title: this._title,
            message: msg,
            variant: 'success',
        });
        this.dispatchEvent(evt);    
    }
    showToastError(msg){
        const evt = new ShowToastEvent({
            title: this._title,
            message: msg,
            variant: 'error',
        });
        this.dispatchEvent(evt);    
    }
    showToastWarning(msg){
        const evt = new ShowToastEvent({
            title: this._title,
            message: msg,
            variant: 'warning',
        });
        this.dispatchEvent(evt);    
    }
    navigateToGrantEditorPage(recordId){
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'GGW_Grant_Editor'
            },
            state: {
                c__recordId: recordId,
                c__uictx: 'page'
            }
        });
    }

    connectedCallback() {
        this.getSectionsList();
    }
    // Status changes combo box handler
    handleStatusChange(event){
        this.statusValue = event.detail.value;
    }
    handleGrantNameChange(event) {
        this.grantNameValue = event.detail.value;
    }
    handleLanguageChange(event){
        //console.log('#### LANG - '+event.detail);
        this.getSectionsList();
    }
    // Search for existing sections that are NOT part of suggested list
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
                console.log('New Application wireFoundSections: unknown error')
            }
        }
    getSectionsList() {
        // Call SFDC method query sections
        getSections()
            .then((data) => {
                this.options = [];
                this.baseoptions = [];
                this.value = [];
                for(var i = 0; i < data.length; i++)  {
                    this.options = [...this.options ,{label: data[i].label, value: data[i].recordid} ];  
                    this.baseoptions = [...this.baseoptions ,{label: data[i].label, value: data[i].recordid} ];  

                    if(data[i].selected == true){
                        this.value.push(data[i].recordid);
                        this.basevalue.push(data[i].recordid);
                    }
                }                
                this.error = undefined;
            })
            .catch((error) => {
                this.error = error;
                console.log(error);
            });
    }
    

    get selectedValues() {
        return this.value.join(',');
    }
    // Event handler for sugested section checkbox group fir on select/deselect 
    // section from the suggested list
    handleIncludeSectionChange(e) {
        this.value = e.detail.value;
    }

    // Select new section found from Search action - checkbox select action
    // add section to the application list
    handleNewSectionAdd(e){
        this.valueSectionAdd = e.detail.value;
        console.log('Select Section: '+e.detail.value);
        // Include selected section to Grant application list
        // Collection has list ov values as array selected by this event
        var tempSectionOptions = [];
        var tempSectionValues = [];
        for(var i=0; i<this.options.length; i++)  {
            tempSectionOptions.push(this.options[i]);
        }
        for(var i=0; i<this.value.length; i++)  {
            tempSectionValues.push(this.value[i]);
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
        // Reset
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
    isStringEmpty(str) {
        if (typeof str === "string" && str.length === 0) {
            //console.log("The string is empty");
            return true;
          } else if (str === null) {
            //console.log("The string is null");
            return true
          } else {
            //console.log("The string is not empty or null");
            return false;
          }
        return false;
    }
    handleSectionInputChange(event) {
        this.newSectionName = event.detail.value;
        if(!this.isStringEmpty(this.newSectionName)){
            this.disableSectionCreateButton = false; // enable create section button
        }else{
            this.disableSectionCreateButton = true; // disable if text is erased
        }
    }
    // CREATE NEW Section - use standard page layout
    // Navigate to New Section record page not baes UX
    // Will use custom method call instead
    handleCreateNewSection(){
        // CALL APEX METHOD createNewSection
        //if(this.newSectionName != null){
        if(!this.isStringEmpty(this.newSectionName)){
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
                    // Clear Section input
                    this.disableSectionCreateButton = true;
                    this.newSectionName = null;

                    this.showToastSuccess(`New Section was created with ID: ${result.recordid}`);
                })
                .catch((error) => {
                    this.error = error;
                    this.showToastError(this.error);
                });
        }else{
            this.showToastWarning(`Please provide a name to create a new Section.`);
        }
    }

    // Create new Grant application event handler
    // Will dispatch DFlow event
    handleApplicationRecordCreate(){
        if(this.grantNameValue != null){
            // Create record/s for new app save and continue to next
            newGrant({name: this.grantNameValue, sections: this.value})
                .then((result) => {
                    console.log('NEW GRANT: '+JSON.stringify(result));
                    this.error = undefined;
                    
                    this.showToastSuccess(`New Grant Application was created with ID: ${result.Id}`);
                    // Navigate to New Grant record page
                    this.navigateToGrantEditorPage(result.Id);
                })
                .catch((error) => {
                    this.error = error;
                    this.showToastError(this.error);
                });
        }else{
            this.showToastWarning(`Please provide a name to create a Grant application.`);
        }
    }
}