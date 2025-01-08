/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement, wire, api, track } from "lwc";
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getApplication from '@salesforce/apex/GGW_ApplicationCtrl.getApplication';
import getApplicationList from '@salesforce/apex/GGW_ApplicationCtrl.getApplicationList';
import includeLogo from '@salesforce/apex/GGW_ApplicationCtrl.includeLogo';
import deleteLogo from '@salesforce/apex/GGW_ApplicationCtrl.deleteLogo';
import createContentDistribution from '@salesforce/apex/GGW_ApplicationCtrl.createContentDistribution';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import NAMESPACE_FIELD_CHECK from '@salesforce/schema/GGW_Grant_Application__c.Application_Name__c';

const GRANT_TITLE = 'Grant Application';
const GRANT_TITLE_HEADER = 'Grant Application:';
const GRANT_TITLE_ERROR = 'Grant Application do not exist, please create new or select existing grant.';
const GRANT_TITLE_LOOKUP_ERROR = 'Grant Application do not contain sections, please add sections to grant using Reorder.';
const GRANT_RECORD_PAGE_URL = '/lightning/r/GGW_Grant_Application__c/'; // Add record ID
const NAMESPACE_PFX = 'GCKit__';
const TAB_GRANT_PREVIEW = 'Grant_Preview';
const TAB_GRANT_PREVIEW_WORD = 'Grant_Preview_Word';
const TAB_GRANT_PREVIEW_PDF = 'Grant_Preview_PDF';

export default class GgwGrantApplication extends NavigationMixin(LightningElement) {
	@api recordId;
	@api objectApiName;
    @api grantName;
    @api contentDownloadUrl;// = 'https://data-drive-2030-dev-ed.file.force.com/sfc/dist/version/renditionDownload?rendition=ORIGINAL_Png&versionId=0680R000001qFvW&operationContext=DELIVERY&contentId=05T0R0000069df5&page=0&d=/a/0R0000008lyn/kf5IDPjQuijS940z47u73Rnb2zSvfmkdSXUpc5S2oSU&oid=00D0R000000nmUQ&dpt=null&viewId=';
    @api language = 'en_US';
    @track logoState = false; // Exclude or include logo
    @track showLogoButtons = false;
    @track openModal = false; // OPen Reorder modal
    @track openVFPExportModal = false; // Open export modal
    @track grantPageURL = '';
    @track sections = [];
    @track grantRecordPage = GRANT_RECORD_PAGE_URL;
    @track currentPageReference;
 
    noLogoDisplay = true; // Display empty avatar instead of logo
    displayTitle;
    status;
    sectioncount;
    _title = GRANT_TITLE;
    message = 'Test';
    variant = 'success';
    toggleIconName = 'utility:preview';
    toggleButtonLabel = 'Add Content';
    currentSections = [];
    container = 'modal';
    showModalFooter = false;
    showCard = true; // Display Editor card if data grant exists ELSE show illustration
    grantOptions = []; // List of available Grants for combo box
    selectedGrant;

    is2GPNamespace(){
        let testVar = false;
        let partName = NAMESPACE_FIELD_CHECK.slice(0, 7);
        if(partName == 'GCKit__'){
            testVar = true;
        }
        console.log(`Derived name: ${partName}`);

        return testVar;
    }
    getPreviewTabName(){
        if(is2GPNamespace()){
            return NAMESPACE_PFX + TAB_GRANT_PREVIEW;
        }else{
            return TAB_GRANT_PREVIEW;
        }
    }

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

    @wire(getApplicationList) 
        grantApplications({ error, data }) {
            if (data) {
                this.grantOptions = [];
                for(let i = 0; i < data.length; i++)  {
                    let grantItem = data[i];
                    if(grantItem){
                        this.grantOptions.push({ label: grantItem.Name, value: grantItem.Id });
                    }
                }
                this.error = undefined;
            } else if (error) {
              this.error = error;
              this.grantOptions = undefined;
            }
        }
        
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
            this.displayGrantCard();
            this.queryGrantApplication();
        }

    handleGrantChange(event) {
        this.selectedGrant = event.detail.value;
        this.recordId = this.selectedGrant;
        this.displayGrantCard();
        this.queryGrantApplication();
    }

    handleLogoSelectorClick() {
        this.logoState = !this.logoState;
        includeLogo({recordId: this.recordId, state: this.logoState})
            .then((data) => {
                console.log(`Logo state was updated ${this.logoState}`);
                this.error = undefined;
                this.showToastSuccess(`${data} ${this.logoState ? 'included' : 'excluded'}`);    
            })
            .catch((error) => {
                console.log(error);
                this.error = error;
                this.showToastError('Logo selection error.');
            });
    }

    handleLogoDelete(event){
        deleteLogo({recordId: this.recordId})
        .then((data) => {
            console.log(`Logo file was deleted`);
            this.error = undefined;
            this.logoState = false; // OFF Include button on editor page
            this.showLogoButtons = false; // remove logo manage buttons
            this.noLogoDisplay = true;
            this.showToastSuccess(data);
    
        })
        .catch((error) => {
            console.log(error);
            this.error = error;
            this.showToastError(`Logo file delete error.`);
        });
    }

    reloadSections(){
        this.queryGrantApplication();
    }

	displayGrantCard(){
        if(this.recordId != null){
            this.showCard = true; // SHo current Grant
        }else{
            this.showCard = false; // Display Illustration NO Grant Data yet
        }
    }

    closeModal() {
		this.dispatchEvent(new CloseActionScreenEvent());
        this.openModal = false;
	}
    // This methods used for Logo image uploads accept only png or jpg files
    get acceptedFormats() {
        return ['.jpg', '.png'];
    }

    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        // Example of data result from upload operation
        // Need to create a public URL in APEX to get Download URL from file to display.
        // Todo that need to Create ContentDistribution record from data below, send contentVersionId as parameter
        // [{"name":"comm-acm.png","documentId":"0690R000001qBDEQA2","contentVersionId":"0680R000001qG2hQAE","contentBodyId":"05T0R0000069drGUAQ","mimeType":"image/png"}]
        console.log('## FILE: '+JSON.stringify(uploadedFiles));
        //alert('No. of files uploaded : ' + uploadedFiles.length + ' ID: ' + uploadedFiles[0].documentId);

        createContentDistribution({grantId: this.recordId, cvid: uploadedFiles[0].contentVersionId})
            .then((data) => {
                console.log('URL: '+data);
                //alert('IMAGE URL: ' + data);
                this.contentDownloadUrl = data;
                this.noLogoDisplay = false;
                this.showLogoButtons = true;
                this.error = undefined;
            })
            .catch((error) => {
                console.log(error);
                this.error = error;
                this.noLogoDisplay = true;
            });
    }    

    handleExportMenuSelect(event){
        const selectedItemValue = event.detail.value;
        console.log(`## handleExportMenuSelect: ${selectedItemValue}`);
        if(selectedItemValue === 'exportPDF'){
            this.exportGrantVFPdf();
        }
        if(selectedItemValue === 'exportWORD'){
           this.exportGrantVFWord(); 
        }
        if(selectedItemValue === 'exportHTML'){
            this.exportGrantVFHTML(); 
         }
    }

    exportGrantVFHTML(){
        let tabName = TAB_GRANT_PREVIEW;
        if(this.is2GPNamespace()){
            tabName = NAMESPACE_PFX + TAB_GRANT_PREVIEW;
        }
        console.log(`TAB Name: ${tabName}`);
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: tabName //'Grant_Preview'
            },
            state: {
                c__recordId: this.recordId,
                c__format: 'html'              // Need this state object to pass parameters in LEX
            }                               // LEX will strip all parameters such as recordID so  must add c__recordId
        });
    }

    exportGrantVFWord(){
        // Tab name - Grant Preview Word
        let tabName = TAB_GRANT_PREVIEW_WORD;
        if(this.is2GPNamespace()){
            tabName = NAMESPACE_PFX + TAB_GRANT_PREVIEW_WORD;
        } 

        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: tabName //'Grant_Preview_Word'
            },
            state: {
                c__recordId: this.recordId,  // Need this state object to pass parameters in LEX
                c__format: 'word'
            }                               // LEX will strip all parameters such as recordID so  must add c__recordId
        });
    }

    exportGrantVFPdf(){
        // Tab Name - Grant_Preview_PDF
        let tabName = TAB_GRANT_PREVIEW_PDF;
        if(this.is2GPNamespace()){
            tabName = NAMESPACE_PFX + TAB_GRANT_PREVIEW_PDF;
        } 

        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: tabName //'Grant_Preview_PDF'
            },
            state: {
                c__recordId: this.recordId,  // Need this state object to pass parameters in LEX
                c__format: 'pdf'
            }                               // LEX will strip all parameters such as recordID so  must add c__recordId
        });
    }

    closePDFModal(){
        this.openVFPExportModal = false;
    }

    setLogoDisplay(logoUrl){
        if (logoUrl != null){
            this.contentDownloadUrl = logoUrl; // load display URL logo
            this.noLogoDisplay = false;
            this.showLogoButtons = true;
        }else{
            this.noLogoDisplay = true;
            this.showLogoButtons = false;
        }
    }

    setDisplayTitle(name){
        if(name){
            this.displayTitle = ` ${GRANT_TITLE_HEADER} ${name}`;
        }else{
            this.displayTitle = GRANT_TITLE_LOOKUP_ERROR;
        }
    }

    setSectionsFromArray(selectedContentBlock){
        if (selectedContentBlock){
            this.sectioncount = selectedContentBlock.length;
            for(let i = 0; i < selectedContentBlock.length; i++)  {
                let item = selectedContentBlock[i];
                let tmpText = item.displaytext ? item.displaytext : 'Text placeholder'; // Set text value condition for null
                this.sections = [...this.sections ,{label: item.sectionname, 
                                                    displaytitle: `[${item.sortorder}] ${item.sectionname}`,
                                                    value: item.sectionid, // sfid for Section record
                                                    appid: this.recordId, // Id for Grant Application record 
                                                    hasblocks: true, 
                                                    sectioncount: this.sectioncount, // pass number of sections to LWC for sorting
                                                    sortorder: item.sortorder,
                                                    selecteditem: item.selecteditemid,
                                                    blockid: item.recordid, // sfid for Content Block record
                                                    textblock: tmpText} ];  
                
                console.log(`Text: ${item.displaytext}`);
            }     
            // Save temp section value
            this.currentSections = this.sections;           
        }      
    }

    queryGrantApplication() {
        // --- Need this timeout delay to allow record ID from Quick Action on record page to be set
        // For some crazy reason LEX/LWC does not init record ID fast enough to init this call
        setTimeout(() => {
            console.log(`queryGrantApplication: Init App with ID: ${this.recordId}`);
            // Change to call imperative instead of wire for data refreshes
            getApplication({recordId: this.recordId})
                .then((data) => {
                    console.log(`queryGrantApplication: Grant Name: ${data.name}`);
                    this.sections = []; // Clear to reload
                    this.currentSections = [];
                    this.recordId = data.recordid; // reset record ID from data in some navi patterns URL parameters can be null
                    this.grantName = data.textname;
                    this.logoState = data.logostate;
                    // Init record page URL used in HTML link on Editor page to open App standard record page it works in 2GP and source scratch
                    this.grantRecordPage = `${GRANT_RECORD_PAGE_URL}${this.recordId}/view`;
                    // Conditional display of logo if it is available or show empty placeholder image
                    this.setLogoDisplay(data.logodisplayurl);
                    this.displayGrantCard(); // handle UX display fo main card or illustration NO Data
                    this.setDisplayTitle(data.name)
                    this.status = data.status;
                    // set Sections UI from an array for section records
                    this.setSectionsFromArray(data.selectedContentBlock);
                    this.error = undefined;
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
        console.log(`REORDER MODAL for App: ${this.recordId}`);
        this.openModal = true;
    }

    handleSelectedTextChange(event){
        //this.textBlock = event.detail;
        console.log(`handleSelectedTextChange: Section: ${event.detail.section} TXT: ${event.detail.text} BlockID: ${event.detail.blockid}`);
    }

    updateGrant(){
        this.closeModal();
    }
    // Order section change
    handleSectionOrderChange(event){
        // TODO There strange problem refresh of section list is late even data is reloaded
        // Modal Action box still not refresh, for now workaround close box reopen will show new order.
        console.log(`handleSectionOrderChange: ORDER Change event: ${this.recordId}`);
        this.closeModal();
        if(event.detail.items){
            // Display toaster message if data was updated
            this.showToastSuccess(`Updated grant sections order or add new section`);
        }
        // Reload data
        this.queryGrantApplication();
        this.sections = this.currentSections;
    }
}