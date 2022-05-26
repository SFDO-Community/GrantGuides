import { LightningElement , api } from "lwc";
import { CloseActionScreenEvent } from 'lightning/actions';
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
         var neworder = {items: this.selected};
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
            console.log('Init App with ID:'+this.recordId);
            //this.displayTitle = 'Grant Application: ' + this.grant.data ? this.grant.data.fields.Name.value : null;
            // Change to call imperative insted of wire for data refreshes
            getApplication({recordId: this.recordId})
                .then((data) => {
                    console.log('Grant Name: '+data.name);
                    this.grantName = data.name;
                    this.displayTitle = 'Grant Application: ' + data.name;
                    this.status = data.status;
                    
                    if (data.selectedContentBlock){
                        this.sectioncount = data.selectedContentBlock.length;
                        for(var i=0; i<data.selectedContentBlock.length; i++)  {
                            var item = data.selectedContentBlock[i];
                            // Use Selectors
                            this.sections = [...this.sections ,{label: item.sectionname, 
                                                                value: item.selecteditemid, // sfid for Section record
                                                                } ];                              
                            if(item.isselected == true){
                                this.selected.push(item.selecteditemid);
                                console.log('Selected: '+item.selecteditemid);
                            }
                                            
                            // USE Data table
                            //this.sections = [...this.sections ,{label: item.sectionname, 
                            //                                    order: item.sortorder,
                            //                                    id: item.sectionid, // sfid for Section record
                            //                                    } ];                              
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

    //get selected() {
    //    return this._selected.length ? this._selected : 'none';
    //}
    // Methdod called by list order LWC standard component when order changes
    // List items rearenged by user
    handleSectionOrderChange(e){
        this.selected = e.detail.value;
        console.log('Order: '+this.selected);
        
    }
    // Save reorder sections for Grant in Salesforce call APEX to save data
    // Update Selected Items with new sort order
    handleReorder(){
        console.log('Call APEX to reOrder: '+this.selected);
        reorderSections({sectionList: this.selected})
            .then((data) => {
                console.log('REORDER RETURENED OK ');
                this.error = undefined;
            })
            .catch((error) => {
                console.log(error);
                this.error = error;
                this.sections = undefined;    
            });
        // Fire event to UI
        var neworder = {items: this.selected};
        const sectionOrderEvent = new CustomEvent("sectionorderchange", {
            detail: neworder,
            bubbles: true
        });

        // Dispatches the event.
        this.dispatchEvent(sectionOrderEvent);

        // Close
        this.closeQuickAction();
    }
}