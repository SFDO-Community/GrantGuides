import { LightningElement, api, track } from 'lwc';

export default class GgwLanguageSelector extends LightningElement {
    @api variant = 'English';
    @track langOptions = [{ label: 'English', value: 'English' },{ label: 'German', value: 'German' },{ label: 'Japanese', value: 'Japanese' }];

    //gettter to return items which is mapped with options attribute
    get variantOptions() {
        return this.langOptions;
    }
    variantChange(event) {
        this.variant = event.target.value;
        this.sname = event.target.name;

        // Creates the event with the selected language data.
        const selectedEvent = new CustomEvent('languageselected', { detail: this.variant });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);    
    }
}