/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement, api , track } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import LightningConfirm from 'lightning/confirm';
import LightningPrompt from 'lightning/prompt';

import saveSelectedSectionText from '@salesforce/apex/GGW_ApplicationCtrl.saveSelectedSectionText';
import updateSelectedItemText from '@salesforce/apex/GGW_ApplicationCtrl.updateSelectedItemText';
import addTextBlockToLibrary  from '@salesforce/apex/GGW_ApplicationCtrl.addTextBlockToLibrary';
import deleteSection from '@salesforce/apex/GGW_ApplicationCtrl.deleteSection';

export default class GgwSection extends LightningElement {
    @api sectionTitle = 'Default Section';
    @api textBlock = 'Text placeholder';
    @api textBlockFormated = 'Text placeholder';
    @api sectionId;
    @api sectionHasBlocks; // Boolean value if section has block allow to save
    @api applicationId;
    @api selectedItemId;
    @api sectioncount;
    @api sortorder;
    @api displayTitle; // Assmeble dynamic title '['+this.sortorder+'] '+this.sectionTitle;

    @track openModal = false;
    @track confirmation;

    blockId;
    saveSelectedText;
    selectedItemOrderValue;
    sectionorder = ['1','2','3','4'];
    _title = 'Section';
    enableEdit = false;
    showModal() {
        console.log('# Section ID: '+this.key);
        this.openModal = true;
        // Seve initial selecetd text to restore later
        this.saveSelectedText = this.textBlock;
    }
    // Close model no section change as cancel action
    closeModal() {
        this.openModal = false;
        this.textBlock = this.saveSelectedText; // Restore initial text
    }
    handleEnableEdit(){
        this.enableEdit = !this.enableEdit;
    }
    // Save set selected section text and close modal
    saveCloseModal() {
        this.openModal = false;

            // Save selected text block data in SFDC
            saveSelectedSectionText({itemid: this.selectedItemId, blockid: this.blockId})
                .then((result) => {
                    //this.contacts = result;
                    console.log('Update App selected item: '+JSON.stringify(result));
                    this.error = undefined;
    
                    // Display toaster message
                    const evt = new ShowToastEvent({
                        title: this._title,
                        message: 'Grant Application was updated with text block.',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
                })
                .catch((error) => {
                    this.error = error;
    
                    // Display ERROR toaster message
                    const evt = new ShowToastEvent({
                        title: this._title,
                        message: this.error,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    
                });
    
    }
    // Delete Item section BUtton click handler call APEX method to delete here with 
    // confirmation Modal
    // This only delete selected ITEM junction from Grant and refresh UI for sections.
    async handleDeleteSection(){
        // Before delete add confirmation modal ensure user action not a mistake
        // Define the properties of our confirmation modal
            const result = await LightningConfirm.open({
                message: 'Are you sure you want to delete section "'+ this.sectionTitle +'" from this grant?',  // Modal body text
                //variant: 'headerless',
                label: 'Confirm Delete Section',
                // setting theme would have no effect
            });
            //Confirm has been closed
            //result is true if OK was clicked
            //and false if cancel was clicked
            if(result == true){
                // Delete section
                this.deleteSectionCall();
            }else{
                console.log('cancel delete section!')
            }
            //console.log('Delete Confirm: '+result);
        
    }
    /** DEPRECATED Using Lightning promprt Summer 22
     * Generic Modal Action button handler User confirms button click
     * called to handle the confirmation modal's custom onbuttonclick event
     * This method can be called for confirming many actions such as 
     * delete section or save block to library
     * @param {*} event - on button click
     *
    handleConfirmationButtonModal(event){
        // We pass the event to the function in the utility class along with the confirmation object
        handleConfirmationButtonClick(event, this.confirmation);
    }*/
    /**
     * Call APEX Method to delete selected item - setion from grant
     */
    deleteSectionCall(){
        deleteSection({itemId: this.selectedItemId})
            .then((result) => {
                //this.contacts = result;
                console.log('Delete item: '+this.selectedItemId);
                this.error = undefined;

                // Fire delete event to parent
                // Bubble UP the deletesection event to parent.
                var sectionObject = { section: this.selectedItemId };
                const selectedBlockEvent = new CustomEvent("deletesection", {
                    detail: sectionObject,
                    bubbles: true
                });
        
                // Dispatches the event.
                this.dispatchEvent(selectedBlockEvent);

                // Display toaster message for selected section item deleted from Salesforce completed
                const evt = new ShowToastEvent({
                    title: this._title,
                    message: 'Delete Grant section.',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
            })
            .catch((error) => {
                this.error = error;

                // Display ERROR toaster message
                const evt = new ShowToastEvent({
                    title: this._title,
                    message: this.error,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            });
    }
    connectedCallback() {
        //this.subscribeToMessageChannel();
        //this.textBlock = 'Text placehold';
        //this.sectionTitle += ' Order - '+this.sortorder; 
        this.displayTitle = '['+this.sortorder+'] '+this.sectionTitle;
        this.sectionorder = [];
        for(var i=0; i<this.sectioncount; i++)  {
            this.sectionorder.push(i+1);
        }
    }
    /**
     * Action button handler User selects on ContentBlockModal one of the blocks by a button click
     * to add text block to a section
     * @param {*} event - on button click holds text adn block ID
     */
    hanldeSelectedBlockChange(event){
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
        updateSelectedItemText({itemid: this.selectedItemId, richtext: this.textBlock})
        .then((result) => {
            //this.contacts = result;
            console.log('Updated text on selected item: '+JSON.stringify(result));
            this.error = undefined;

            // Display toaster message
            const evt = new ShowToastEvent({
                title: this._title,
                message: 'Text block updated.',
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // Disable Edit panel
            this.enableEdit = false;
        })
        .catch((error) => {
            this.error = error;

            // Display ERROR toaster message
            const evt = new ShowToastEvent({
                title: this._title,
                message: this.error,
                variant: 'error',
            });
            this.dispatchEvent(evt);
            
        });
    }
    /**
     * Rich Text input change event handler, fire when  user changes rich text in the text box
     * This even used to update text data in a variable to use later to save call.
     * @param {*} event  - contains rich text changed value 
     */
    handleTextBlockChange(event){
        this.textBlock = event.target.value;
    }
    /**
     * TBD - NOT FULLY IMPLIMENTED
     * This is menue handler for sorting section
     * NOT yet decided if we actually be using this
     * @param {*} event 
     */
    handleReorderOnselect(event){
        this.selectedItemOrderValue = event.detail.value;
        this.sortorder = this.selectedItemOrderValue;
        this.displayTitle = this.sectionTitle + ' Order - '+this.sortorder;
        // call method apex to update sort order for selected item
        // TODO ----- IMPLIMENT IF WE DCIDE to use this sorting event
    }
    /**
     * Action button handler ADD Block TO LIBRARY on section toolbar, 
     * cofirm the action and commit save changes adding new text block in Salesforce
     * Add block text record to a related section recod, to collect content blocks library
     * 
     * @param {*} event 
     */
    addBlockToLibrary(){
        // Before delete add confirmation modal ensure user action not a mistake
        LightningPrompt.open({
            message: 'Are you sure you want to add this text block to section "'+ this.sectionTitle +'"? If yes please enter block name.',  // Modal body text
            //theme defaults to "default"
            label: 'Add Block to Library', // this is the header text
            defaultValue: 'name new block', //this is optional
        }).then((result) => {
            //Prompt has been closed
            //result is input text if OK clicked
            //and null if cancel was clicked
            if(result != null){
                console.log('New block save Name: '+result);
                // Add save ne block to libarary
                this.saveNewTextBlock(result);
            }else{
                console.log('cancel save block!')
            }    
        });

    }
    /**
     * Call APEX methods to save new text block for given section
     * to reuse later in other applications.
     * This new blocks can be tagged by users by adding Topic labels
     */
    saveNewTextBlock(blockname){
        // Create new text block to save for future use
        addTextBlockToLibrary({sectionid: this.sectionId, richtext: this.textBlock, name: blockname})
        .then((result) => {
            //this.contacts = result;
            //console.log('Updated text on selected item: '+result);
            this.error = undefined;

            // Display toaster message
            const evt = new ShowToastEvent({
                title: this._title,
                message: 'New text block added to library for Section:'+this.sectionTitle,
                variant: 'success',
            });
            this.dispatchEvent(evt);
        })
        .catch((error) => {
            this.error = error;
            console.log(error);
            if(this.error){
                // Display ERROR toaster message
                const evt = new ShowToastEvent({
                    title: this._title,
                    message: this.error,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }
        });
    }
}