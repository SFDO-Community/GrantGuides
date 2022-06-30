import { LightningElement ,wire , api, track } from "lwc";
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getApplication from '@salesforce/apex/GGW_ApplicationCtrl.getApplication';
//import {refreshApex} from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import { updateRecord } from 'lightning/uiRecordApi';
//import { getRecord } from 'lightning/uiRecordApi';
//import ID_FIELD from '@salesforce/schema/GGW_Grant_Application__c.Id';
//import GRANTNAME_FIELD from '@salesforce/schema/GGW_Grant_Application__c.Name';

const GRANT_TITLE = 'Grant Application';
const GRANT_TITLE_HEADER = 'Grant Application: ';
const GRANT_TITLE_ERROR = 'Grant Application do not exist, please create new or select existing grant.';

export default class GgwGrantApplication extends NavigationMixin(LightningElement) {
	@api recordId;
	@api objectApiName;
    @api grantName;
    displayTitle;
    status;
    sectioncount;
    _title = GRANT_TITLE;
    message = 'Test';
    variant = 'success';
    @track openModal = false; // OPen Reorder modal
    @track openVFPExportModal = false; // Open export modal
    toggleIconName = 'utility:preview';
    toggleButtonLabel = 'Add Content';
    @track grantPageURL = '';
    @track sections = [];
    currentSections = [];
    container = 'modal';
    showModalFooter = true;

    @track currentPageReference;
    @wire(CurrentPageReference)
        setCurrentPageReference(currentPageReference) {
            this.currentPageReference = currentPageReference;
            this.recordId = this.currentPageReference?.state?.c__recordId;
            this.container = this.currentPageReference?.state?.c__uictx;
            console.log('setCurrentPageReference: Grant ID:'+this.recordId);
            console.log('setCurrentPageReference: Container:'+this.container);
            if(this.container == 'page'){
                this.showModalFooter = false;
            }
            this.queryGrantApplication();
        }
    
    reloadSections(){
        this.queryGrantApplication();
    }
	
    closeModal() {
		this.dispatchEvent(new CloseActionScreenEvent());
        this.openModal = false;
	}
    exportGrantVFPdf(){
        //https://velocity-java-707-dev-ed.lightning.force.com/
        // https://velocity-java-707-dev-ed--c.visualforce.com/apex/GGW_GrantPreview
        //https://velocity-java-707-dev-ed--c.visualforce.com/apex/GGW_GrantPreviewCustom?c__recordId=a001D0000058zp2QAA
        //this.grantPageURL = '/apex/GGW_GrantPreview?c__recordId='+this.recordId;
        //this.openVFPExportModal = true;

        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Grant_Preview'
            },
            state: {
                c__recordId: this.recordId  // Need this state object to pass parameters in LEX
            }                               // LEX will strip all parameters such as recordID so  must add c__recordId
        });
/*
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: this.grantPageURL
            }
        }).then(generatedUrl => {
            window.open(generatedUrl);
        });
*/
    }
    closePDFModal(){
        this.openVFPExportModal = false;
    }
    
    queryGrantApplication(){
        // --- Need this timeout delay to allow record ID from Quick Action on record page to be set
        // For some crazy reason LEX/LWC does not init record ID fast enough to init this call
        setTimeout(() => {
            console.log('queryGrantApplication: Init App with ID:'+this.recordId);
            //this.displayTitle = 'Grant Application: ' + this.grant.data ? this.grant.data.fields.Name.value : null;

            // Change to call imperative insted of wire for data refreshes
            getApplication({recordId: this.recordId})
                .then((data) => {
                    console.log('queryGrantApplication: Grant Name: '+data.name);
                    this.sections = []; // Clear to reload
                    this.currentSections = [];
                    this.recordId = data.recordid; // reset record ID from data in some navi patterns URL parameters can be null
                    this.grantName = data.name;
                    if(data.name){
                        this.displayTitle = GRANT_TITLE_HEADER + data.name;
                    }else{
                        this.displayTitle = GRANT_TITLE_ERROR;
                    }
                    this.status = data.status;
                    
                    if (data.selectedContentBlock){
                        this.sectioncount = data.selectedContentBlock.length;
                        for(var i=0; i<data.selectedContentBlock.length; i++)  {
                            var item = data.selectedContentBlock[i];
                            var tmpText = item.displaytext ? item.displaytext : 'Text placeholder'; // Set text value condition for null
                            this.sections = [...this.sections ,{label: item.sectionname, 
                                                                displaytitle: '['+item.sortorder+'] ' + item.sectionname,
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
                        // Save temp section value
                        this.currentSections = this.sections;           
                    }      
                    this.error = undefined;
                    //updateRecord({ fields: { Id: this.recordId } });
                })
                .catch((error) => {
                    console.log(error);
                    this.error = error;
                    this.sections = undefined;   
                    this.displayTitle = GRANT_TITLE_ERROR; 
                });
        }, 5);
    }    
    // when the component is first initialized assign an initial value to sections and other Grant App variables    
    connectedCallback() {
        this.queryGrantApplication();
        //this.sections = this.currentSections;
    }
    handleDeleteSection(){
        // Section - selected item data has been deleted by Section component action
        // here we only refresh UI/UX
        // Remove section from a UI list, call APEX
        this.queryGrantApplication();
        this.sections = this.currentSections;
    }
    // Open section Modal to reorder
    reorderSections(){
        console.log('REORDER MODAL for App: '+this.recordId);
        this.openModal = true;
    }

    hanldeSelectedTextChange(event){
        //this.textBlock = event.detail;
        console.log('hanldeSelectedTextChange: Section:'+event.detail.section+' TXT: '+event.detail.text+' BlockID:'+event.detail.blockid);
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
       // MOdal Action box still not refresh, for now solve close box repoen will show new order.
       console.log('handleSectionOrderChange: ORDER Change event:'+this.recordId);
        // Arange new order sections on UI on client side
        //refreshApex(this.handleLoad());
        // Close modal
        //this.openModal = false;
        this.closeModal();
        if(event.detail.items){
            // Display toaster message if data was updated
            const evt = new ShowToastEvent({
                title: this._title,
                message: 'Updated grant sections order or add new section',
                variant: this.variant,
            });
            this.dispatchEvent(evt);    
        }
        // Reload data
        this.queryGrantApplication();
        this.sections = this.currentSections;
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
     *
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
    }*/

}