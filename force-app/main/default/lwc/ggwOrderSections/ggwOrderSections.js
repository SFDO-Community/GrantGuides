/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement , api } from "lwc";
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getApplication from '@salesforce/apex/GGW_ApplicationCtrl.getApplication';
import reorderSections from '@salesforce/apex/GGW_ApplicationCtrl.reorderSections';
const columns = [
    { label: 'Section', fieldName: 'label', editable: false },
    { label: 'Order', fieldName: 'order', type: 'number', editable: true },
];

export default class GgwOrderSections extends LightningElement {
	@api recordId; // For Grant Application record as header holdeing section Items
	@api objectApiName;
    sections = [];
    columns = columns;
    rowOffset = 0;
    grantName;
    displayTitle;
    status;
    sectioncount;
    selected = [];
    
	closeQuickAction() {
		this.dispatchEvent(new CloseActionScreenEvent());
         // Fire event to UI
         const cancelreorder = {action: 'close'};
         const reOrderEvent = new CustomEvent("sectionorderchange", {
             detail: cancelreorder,
             bubbles: true
         });
         // Dispatches the event.
         this.dispatchEvent(reOrderEvent);
	}
    
    confirmSectionReorder(){
        // Fire event to UI to notify parent app to close modal reorder and update view
        const neworder = {items: this.selected};
        const sectionOrderEvent = new CustomEvent("sectionorderchange", {
                detail: neworder,
                bubbles: true
        });
        // Dispatches the event.
        this.dispatchEvent(sectionOrderEvent);
    }    
    // when the component is first initialized assign an initial value to sections and other Grant App variables    
    connectedCallback() {
        // --- Need this timeout delay to allow record ID from Quick Action on record page to be set
        // For some crazy reason LEX/LWC does not init record ID fast enough to init this call
        setTimeout(() => {
            console.log(`Init App with ID: ${this.recordId}`);
            //this.displayTitle = 'Grant Application: ' + this.grant.data ? this.grant.data.fields.Name.value : null;
            // Change to call imperative instead of wire for data refreshes
            getApplication({recordId: this.recordId})
                .then((data) => {
                    console.log(`Grant Name: ${data.name}`);
                    this.grantName = data.name;
                    this.displayTitle = `Grant Application: ${data.name}`;
                    this.status = data.status;
                    
                    if (data.selectedContentBlock){
                        this.sectioncount = data.selectedContentBlock.length;
                        for(let i=0; i<data.selectedContentBlock.length; i++)  {
                            let item = data.selectedContentBlock[i];
                            // Use Selectors
                            this.sections = [...this.sections ,{label: item.sectionname, 
                                                                value: item.selecteditemid, // sfid for Section record
                                                                } ];                              
                            if(item.isselected == true){
                                this.selected.push(item.selecteditemid);
                                console.log('Selected: '+item.selecteditemid);
                            }
                                            
                        }                
                    }  
                    // New sections
                    if (data.unselectSectionList){
                        console.log(`UN-Selected: ${data.unselectSectionList}`);
                        for(let i=0; i<data.unselectSectionList.length; i++)  {
                            let sect = data.unselectSectionList[i];
                            console.log(`${i}  section: ${sect.label}`);
                            // Use Selectors
                            this.sections = [...this.sections ,{label: sect.label, 
                                                                value: sect.recordid, // sfid for Section record
                                                                } ];                              
                        }                
                    } 
                    this.error = undefined;
                })
                .catch((error) => {
                    console.log(error);
                    this.error = error;
                    this.sections = undefined;    
                });
        }, 5);
    }

    // Method called by list order LWC standard component when order changes
    // List items rearranged by user
    handleSectionOrderChange(e){
        this.selected = e.detail.value;
        console.log(`Order: ${this.selected}`);
    }
    // Save reorder sections for Grant in Salesforce call APEX to save data
    // Update Selected Items with new sort order
    handleReorder(e){
        console.log(`Call APEX to reOrder: ${this.selected}`);
        reorderSections({sectionList: this.selected, appId: this.recordId})
            .then((data) => {
                console.log(`REORDER RETURNED OK `);
                this.error = undefined;
                this.confirmSectionReorder();
            })
            .catch((error) => {
                console.log(error);
                this.error = error;
                this.sections = undefined;  
                console.log(`REORDER ERROR: ${this.error}`);
                
                const evt = new ShowToastEvent({
                    title: 'Reorder Error',
                    message: this.error,
                    variant: 'error',
                });
                this.dispatchEvent(evt);    
        
            });
    }
}