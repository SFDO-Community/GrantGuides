import { LightningElement , api } from "lwc";
import { CloseActionScreenEvent } from 'lightning/actions';
import getApplication from '@salesforce/apex/GGW_ApplicationCtrl.getApplication';
const columns = [
    { label: 'Section', fieldName: 'label', editable: false },
    { label: 'Order', fieldName: 'order', type: 'number', editable: true },
];

export default class GgwOrderSections extends LightningElement {
	@api
	recordId; // For Grant Application record as header holdeing section Items
	@api
	objectApiName;
    sections = [];
    columns = columns;
    rowOffset = 0;

    //c/ggwBarChart
    grantName;
    displayTitle;
    status;
    sectioncount;

	closeModal() {
		this.dispatchEvent(new CloseActionScreenEvent());
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
                            this.sections = [...this.sections ,{label: item.sectionname, 
                                                                order: item.sortorder,
                                                                id: item.sectionid, // sfid for Section record
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

}