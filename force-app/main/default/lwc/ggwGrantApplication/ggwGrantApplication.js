import { LightningElement ,wire , api, track } from "lwc";
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import {refreshApex} from '@salesforce/apex';
import getApplication from '@salesforce/apex/GGW_ApplicationCtrl.getApplication';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import { getRecord } from 'lightning/uiRecordApi';
//import ID_FIELD from '@salesforce/schema/GGW_Grant_Application__c.Id';
//import GRANTNAME_FIELD from '@salesforce/schema/GGW_Grant_Application__c.Name';

export default class GgwGrantApplication extends NavigationMixin(LightningElement) {
	@api recordId;
	@api objectApiName;
    @api grantName;
    displayTitle;
    status;
    sectioncount;
    _title = 'Grant Application';
    message = 'Test';
    variant = 'success';
    @track openModal = false;

    toggleIconName = 'utility:preview';
    toggleButtonLabel = 'Add Content';

    sections = [];

    @track currentPageReference;
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        this.recordId = this.currentPageReference?.state?.c__recordId;
        console.log('Grant ID:'+this.recordId);
    }

	closeModal() {
		this.dispatchEvent(new CloseActionScreenEvent());
        this.openModal = false;
	}
    /* This standard call is replaced by Apex method getApplication with related blocks sections.
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
        */

    queryGrantApplication(){
        // --- Need this timeout delay to allow record ID from Quick Action on record page to be set
        // For some crazy reason LEX/LWC does not init record ID fast enough to init this call
        setTimeout(() => {
            console.log('Init App with ID:'+this.recordId);
            //this.displayTitle = 'Grant Application: ' + this.grant.data ? this.grant.data.fields.Name.value : null;

            // Change to call imperative insted of wire for data refreshes
            getApplication({recordId: this.recordId})
                .then((data) => {
                    console.log('Grant Name: '+data.name);
                    this.sections = []; // Clear to reload
                    this.grantName = data.name;
                    this.displayTitle = 'Grant Application: ' + data.name;
                    this.status = data.status;
                    
                    if (data.selectedContentBlock){
                        this.sectioncount = data.selectedContentBlock.length;
                        for(var i=0; i<data.selectedContentBlock.length; i++)  {
                            var item = data.selectedContentBlock[i];
                            var tmpText = item.displaytext ? item.displaytext : 'Text placeholder'; // Set text value condition for null
                            this.sections = [...this.sections ,{label: item.sectionname, 
                                                                value: item.sectionid, // sfid for Section record
                                                                appid: data.recordid, // Id for Grant Application record 
                                                                hasblocks: true, 
                                                                sectioncount: this.sectioncount, // pass number of sections to LWC for sorting
                                                                sortorder: item.sortorder,
                                                                selecteditem: item.selecteditemid,
                                                                blockid: item.recordid, // sfid for Content Block record
                                                                textblock: tmpText} ];  
                            
                                                                console.log('Text: '+item.displaytext);
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
    // when the component is first initialized assign an initial value to sections and other Grant App variables    
    connectedCallback() {
            this.queryGrantApplication();
    }

/* -- Need to to update data and cache=true does not fit here swicth using connected Callback with a GACKy Hack
    @wire(getApplication, {recordId: '$recordId'})
    wireApplication({error,data}){
        if (data) {
            console.log('Grant Name: '+data.name);
            this.grantName = data.name;
            this.displayTitle = 'Grant Application: ' + data.name;
            this.status = data.status;
            if (data.selectedContentBlock){
                for(var i=0; i<data.selectedContentBlock.length; i++)  {
                    var item = data.selectedContentBlock[i];
                    var tmpText = item.displaytext ? item.displaytext : 'Text placeholder'; // Set text value condition for null
                    this.sections = [...this.sections ,{label: item.sectionname, 
                                                        value: item.sectionid, // sfid for Section record
                                                        appid: data.recordid, // Id for Grant Application record 
                                                        hasblocks: true, 
                                                        selecteditem: item.selecteditemid,
                                                        blockid: item.recordid, // sfid for Content Block record
                                                        textblock: tmpText} ];  
                    
                                                        console.log('Text: '+item.displaytext);
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
*/
    /**
     * Navigate using Lightning Navi helpers to custom VFP to render PDF doc
     * Preview of Grant application. This must pass rec ID parameter in state
     * 
     * ERROR: FOr some reason we allways get NULL rec ID in APEX controller for this page
     * despite the fact there is URL parm set c__recordId visible in URL example
     * https://velocity-java-707-dev-ed.lightning.force.com/lightning/n/GGW_Application_Preview?c__recordId=a001D0000058zp2
     * 
     * The navigation from Record page works OK using same methods but LEX passing context in other ways
     * to controler extension from recorp page context.
     */
    exportGrantPdf(){
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'GGW_Application_Preview'
            },
            state: {
                c__recordId: this.recordId  // Need this state object to pass parameters in LEX
            }                               // LEX will strip all parameters such as recordID so  must add c__recordId
        });
    }
    // Open section Modal to reorder
    reorderSections(){
        this.openModal = true;
    }

    hanldeSelectedTextChange(event){
        //this.textBlock = event.detail;
        console.log('Section:'+event.detail.section+' TXT: '+event.detail.text+' BlockID:'+event.detail.blockid);
        // Display toaster message
        /*
        const evt = new ShowToastEvent({
            title: this._title,
            message: 'Section:'+event.detail.section+' TXT: '+event.detail.text+' BlockID:'+event.detail.blockid,
            variant: this.variant,
        });
        this.dispatchEvent(evt);    
        */    
    }

    updateGrant(){
        /*
        console.log('Show Text Block:'+this.sections[0].textblock);
        // Display toaster message
        const evt = new ShowToastEvent({
            title: this._title,
            message: 'Show Text Block:'+this.sections[0].textblock,
            variant: this.variant,
        });
        this.dispatchEvent(evt);
        */
        this.closeModal();
    }
    // Order section change
    handleSectionOrderChange(event){
        
       // TODO There strange porblem refresh of section list is late even data is reloaded
       // MOdal Action box still not refresh, for now solve close box repoen will sho new order.
    
        // Arange new order sections on UI on client side
        //refreshApex(this.handleLoad());
        this.queryGrantApplication();
        // Close modal
        //this.openModal = false;
        this.closeModal();
    }

    // --- DRAG ACTION NOT USED FOR NOW
    /*
    drag(event){
        event.dataTransfer.setData("divId", event.target.id);
    }
    allowDrop(event){
        event.preventDefault();
    }
    drop(event){
        event.preventDefault();
        var divId = event.dataTransfer.getData("divId");
        console.log('DROP Section ID: '+divId);
        var draggedElement = this.template.querySelector('#' +divId);
        draggedElement.classList.add('completed'); 
        event.target.appendChild(draggedElement);
    }
    */
}