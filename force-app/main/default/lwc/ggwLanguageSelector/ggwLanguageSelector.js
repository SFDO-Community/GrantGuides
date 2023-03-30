import { LightningElement, api, track } from 'lwc';
import saveLanguageSelection from '@salesforce/apex/GGW_ApplicationCtrl.saveLanguageSelection'; 
export default class GgwLanguageSelector extends LightningElement {
    // Language setting uses ISO language country code (language_COUNTRY) 
    @api langauge;
    @track langOptions = [{ label: 'English', value: 'en_US' },{ label: 'German', value: 'de_DE' },{ label: 'Japanese', value: 'ja_JP' }];
    error;
    _title = 'Language selector';
    message = 'Language selected';
    variant = 'success';

    //gettter to return items which is mapped with options attribute
    get langaugeOptions() {
        return this.langOptions;
    }
    langaugeChange(event) {
        this.langauge = event.target.value;
        this.sname = event.target.name;
        console.log('Event SELECTED LANG: '+this.langauge);
        const isEmpty = (str) => (!str?.length);
        // save to state
        if (!isEmpty(this.langauge)){
            // Call save SFDC method
            console.log('isEmpty function worked SELECTED LANG: '+this.langauge);
            saveLanguageSelection({lang: this.langauge})
                .then((result) => {
                    //this.contacts = result;
                    console.log('Function call response: '+result);
                    console.log('SAVED Language selection: '+this.langauge);
                    this.error = undefined;
                    this.message = 'Selected language for Grant Application: '+this.langauge;
                    this.variant = 'success';
                    // Display toaster message
                    const evt = new ShowToastEvent({
                        title: this._title,
                        message: this.message,
                        variant: this.variant,
                    });
                    this.dispatchEvent(evt);
                })
                .catch((error) => {
                    this.error = error;
                    //this.contacts = undefined;
                    this.message = this.error;
                    this.variant = 'error';
                    // Display toaster message
                    const evt = new ShowToastEvent({
                        title: this._title,
                        message: this.message,
                        variant: this.variant,
                    });
                    this.dispatchEvent(evt);
                });

        }
        // Creates the event with the selected language data.
        const selectedEvent = new CustomEvent('languageselected', { detail: this.langauge });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);    
    }
}