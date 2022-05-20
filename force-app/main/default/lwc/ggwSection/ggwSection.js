import { LightningElement, api , track } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveSelectedSectionText from '@salesforce/apex/GGW_ApplicationCtrl.saveSelectedSectionText';
import updateSelectedItemText from '@salesforce/apex/GGW_ApplicationCtrl.updateSelectedItemText';
import addTextBlockToLibrary  from '@salesforce/apex/GGW_ApplicationCtrl.addTextBlockToLibrary';

export default class GgwSection extends LightningElement {
    @api sectionTitle = 'Default Section';
    @api textBlock = 'Text placeholder';
    @api sectionId;
    @api sectionHasBlocks; // Boolean value if section has block allow to save
    @api applicationId;
    @api selectedItemId;
    @api sectioncount;
    @api sortorder;
    @track openModal = false;
    blockId;
    saveSelectedText;
    selectedItemOrderValue;
    sectionorder = ['1','2','3','4'];
    displayTitle; // Assmeble dynamic title
    _title = 'Section';

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

    connectedCallback() {
        //this.subscribeToMessageChannel();
        //this.textBlock = 'Text placehold';
        //this.sectionTitle += ' Order - '+this.sortorder; 
        this.displayTitle = this.sectionTitle + ' Order - '+this.sortorder;
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
     * Action button handler ADD Block TO LIBRARY on section toolbar, commit save changes adding new text block in Salesforce
     * Add block text record to a related section recod, to collect content blocks library
     * 
     * @param {*} event 
     */
    addBlockToLibrary(event){
        // Create new text block to save for future use
        addTextBlockToLibrary({sectionid: this.sectionId, richtext: this.textBlock})
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