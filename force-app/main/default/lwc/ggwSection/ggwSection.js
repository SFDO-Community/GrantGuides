/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement, api , track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import LightningConfirm from 'lightning/confirm';
import LightningPrompt from 'lightning/prompt';

import saveSelectedSectionText from '@salesforce/apex/GGW_ApplicationCtrl.saveSelectedSectionText';
import updateSelectedItemText from '@salesforce/apex/GGW_ApplicationCtrl.updateSelectedItemText';
import addTextBlockToLibrary  from '@salesforce/apex/GGW_ApplicationCtrl.addTextBlockToLibrary';
import deleteSection from '@salesforce/apex/GGW_ApplicationCtrl.deleteSection';
import {errorMessage} from 'c/ggwErrorHandler'; // Default Error handling helper function utility

export default class GgwSection extends LightningElement {
    @api sectionTitle = 'Default Section';
    @api textBlock = 'Text placeholder';
    @api sectionId;
    @api sectionHasBlocks; // Boolean value if section has block allow to save
    @api applicationId;
    @api selectedItemId;
    @api sectioncount;
    @api sortorder;
    @api displayTitle;

    @track openModal = false;
    @track confirmation;
    @track buttonVariant = 'neutral';

    blockId;
    saveSelectedText;
    selectedItemOrderValue;
    sectionorder = ['1','2','3','4'];
    _title = 'Section';
    enableEdit = false;
    textChanged = false;  // Track if user changed some text in section
    textBlockBuffer; // Store temporary
    textBlockOrigin; // Keep original text block
    charCounter = '0 out of 32K'; // default message

    maxBlockSize = 32768; //32K

    showToastSuccess(msg){
        const evt = new ShowToastEvent({
            title: this._title,
            message: msg,
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }
    showToastError(msg){
        let msgTxt = errorMessage(msg);

        const evt = new ShowToastEvent({
            title: this._title,
            message: msgTxt,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }
    convertToPlainText(rtf) {
        let newLine = rtf.replace(/(?:<br>|<li>|<p>)/g,'\r\n');
        return newLine.replace( /(<([^>]+)>)/ig, '');
    }
    copyText(){
        let tempText = this.convertToPlainText(this.textBlock);
        navigator.clipboard.writeText(tempText).then(
            () => {
                this.showToastSuccess(`Data copied to clipboard`);
            },
            () => {
                this.showToastError(`Copy FAILED ERROR`);
            },
          );
    }
    // count charcters in textBlock
    getCharacterCount(str) {
        // Check if input is a string
        if (typeof str !== 'string') {
            return 0;
        }
        //let textTemp = this.convertToPlainText(this.textBlock);
        let cnt = str.length;
        if (cnt > this.maxBlockSize) {
            this.buttonVariant = 'destructive-text';
        }else{
            this.buttonVariant = 'neutral';
        }
        return cnt;
    }
    showModal() {
        console.log(`# Section ID: ${this.key}`);
        this.openModal = true;
        // Save initial selected text to restore later
        this.saveSelectedText = this.textBlock;
    }
    // Close model no section change as cancel action
    closeModal() {
        this.openModal = false;
        this.textBlock = this.saveSelectedText; // Restore initial text
    }
    /**
     * Toggle Edit mode ON/OFF with text changes validations
     * Including Save text to temporary buffer to rollback to original text
     * Uses Lightning Confirmation modal box
     * 
     * @param {*} NONE
     */
    async handleEnableEdit(){
        if(this.textChanged === true){
            const result = await LightningConfirm.open({
                message: `You have unsaved changes. Are you sure you want to cancel edits.`,
                label: 'Confirm Cancel Edit',
            });
            if(result == true){
                this.enableEdit = false;
                this.textChanged = false;
                this.textBlock = this.textBlockOrigin;
            }else{
                console.log(`cancel delete section!`)
            }
        }else{
            this.enableEdit = this.enableEdit ? false : true;
        }
    }
    // Save set selected section text and close modal
    saveCloseModal() {
        this.openModal = false;

        // Save selected text block data in SFDC
        saveSelectedSectionText({itemid: this.selectedItemId, blockid: this.blockId})
            .then((result) => {
                console.log(`Update App selected item: ${JSON.stringify(result)}`);
                this.error = undefined;    
                this.showToastSuccess(`Grant Application was updated with text block.`)
            })
            .catch((error) => {
                this.error = error;
                this.showToastError(error);                    
            });
    }
    // Delete Item section Button click handler call APEX method to delete here with 
    // confirmation Modal
    // This only delete selected ITEM junction from Grant and refresh UI for sections.
    async handleDeleteSection(){
        // Before delete add confirmation modal ensure user action not a mistake
        // Define the properties of our confirmation modal
        const result = await LightningConfirm.open({
                message: `Are you sure you want to delete section ${this.sectionTitle} from this grant?`,  // Modal body text
                //variant: 'headerless',
                label: `Confirm Delete Section`,
                // setting theme would have no effect
        });
        //Confirm has been closed
        //result is true if OK was clicked
        //and false if cancel was clicked
        if(result == true){
            // Delete section
            this.deleteSectionCall();
        }else{
            console.log(`cancel delete section!`)
        }
        //console.log('Delete Confirm: '+result);
        
    }
    /**
     * Call APEX Method to delete selected item - section from grant
     */
    deleteSectionCall(){
        deleteSection({itemId: this.selectedItemId})
            .then((result) => {
                //this.contacts = result;
                console.log(`Delete item: ${this.selectedItemId}`);
                this.error = undefined;

                // Fire delete event to parent
                // Bubble UP the delete section event to parent.
                var sectionObject = { section: this.selectedItemId };
                const selectedBlockEvent = new CustomEvent('deletesection', {
                    detail: sectionObject,
                    bubbles: true
                });
        
                // Dispatches the event.
                this.dispatchEvent(selectedBlockEvent);

                // Display toaster message for selected section item deleted from Salesforce completed
                this.showToastSuccess(`Delete Grant section.`);
            })
            .catch((error) => {
                this.error = error;
                this.showToastError(error);
            });
    }
    connectedCallback() {
        this.displayTitle = `[${this.sortorder}] ${this.sectionTitle}`;
        this.sectionorder = [];
        for(var i=0; i<this.sectioncount; i++)  {
            this.sectionorder.push(i+1);
        }
        this.textBlockOrigin = this.textBlock;
        let cnt = this.getCharacterCount(this.textBlock);
        this.charCounter = `${cnt} out of 32K`;
    }
    /**
     * Action button handler User selects on ContentBlockModal one of the blocks by a button click
     * to add text block to a section
     * @param {*} event - on button click holds text adn block ID
     */
    handleSelectedBlockChange(event){
        this.textBlock = event.detail.blocktext;
        this.blockId = event.detail.blockid;
        // Bubble UP the selectedblockchange event with the text data.
        var sectionObject = { section: this.sectionId, text: this.textBlock, blockid: this.blockId };
        const selectedBlockEvent = new CustomEvent("selectedtext", {
            detail: sectionObject,
            bubbles: true
        });
  
        // Dispatches the event.
        this.dispatchEvent(selectedBlockEvent);

    }
    /**
     * Action button handler SAVE on section toolbar, commit save changes to text in Salesforce
     * Call Apex method imperatively: updateSelectedItemText to update a copy of text on selected item
     * record
     * @param {*} event - on button click event not used in this action
     */
    saveRichText(event){
        if(!this.textChanged){
            this.showToastSuccess(`Nothing to update.`);
            return;
        }
        this.textBlock = this.textBlockBuffer;
        updateSelectedItemText({itemid: this.selectedItemId, richtext: this.textBlock})
        .then((result) => {
            console.log(`Updated text on selected item: ${JSON.stringify(result)}`);
            this.error = undefined;
            this.showToastSuccess(`Text block updated.`);

            // Disable Edit panel
            this.enableEdit = false;
            this.textChanged = false;
            this.textBlockOrigin = this.textBlock; // Set Origin text same as current saved text
        })
        .catch((error) => {
            this.error = error;
            this.showToastError(error); 
        });
    }
    /**
     * Rich Text input change event handler, fire when  user changes rich text in the text box
     * This event used to update text data in a variable to use later to save call.
     * @param {*} event  - contains rich text changed value 
     */
    handleTextBlockChange(event){
        //this.textBlock = event.target.value;
        this.textBlockBuffer = event.target.value;
        this.textChanged = true;
        let cnt = this.getCharacterCount(this.textBlockBuffer);
        this.charCounter = `${cnt} out of 32K`;
    }
    /**
     * TBD - NOT FULLY IMPLEMENTED
     * This is menu handler for sorting section
     * NOT yet decided if we actually be using this
     * @param {*} event 
     */
    handleReorderOnselect(event){
        this.selectedItemOrderValue = event.detail.value;
        this.sortorder = this.selectedItemOrderValue;
        this.displayTitle = this.sectionTitle + ' Order - '+this.sortorder;
        // call method apex to update sort order for selected item
        // TODO ----- IMPLEMENT IF WE DECIDE to use this sorting event
    }
    /**
     * Action button handler ADD Block TO LIBRARY on section toolbar, 
     * confirm the action and commit save changes adding new text block in Salesforce
     * Add block text record to a related section record, to collect content blocks library
     * 
     * @param {*} event 
     */
    addBlockToLibrary(){
        // Before delete add confirmation modal ensure user action not a mistake
        LightningPrompt.open({
            message: `Are you sure you want to add this text block to section ${this.sectionTitle}? If yes please enter block name.`,  // Modal body text
            // theme defaults to "default"
            label: 'Add Block to Library', // this is the header text
            defaultValue: 'name new block', //this is optional
        }).then((result) => {
            //Prompt has been closed
            //result is input text if OK clicked
            //and null if cancel was clicked
            if(result != null){
                console.log(`New block save Name: ${result}`);
                // Add save new block to library
                this.saveNewTextBlock(result);
            }else{
                console.log(`cancel save block!`)
            }    
        });

    }
    /**
     * Call APEX methods to save new text block for given section
     * to reuse later in other applications.
     * This new blocks can be tagged by users by adding Topic labels
     * 
     * @param {*} blockname 
     */
    saveNewTextBlock(blockname){
        // Create new text block to save for future use
        addTextBlockToLibrary({sectionid: this.sectionId, richtext: this.textBlock, name: blockname})
        .then((result) => {
            this.error = undefined;
            this.showToastSuccess(`New text block added to library for Section: ${this.sectionTitle}`);
        })
        .catch((error) => {
            this.error = error;
            console.log(error);
            console.log(`ERROR saveNewTextBlock: ${errorMessage(error)}`);  
            if(this.error){
                this.showToastError(error);
            }
        });
    }

}