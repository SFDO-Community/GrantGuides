import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSupportedLanguages from '@salesforce/apex/GGW_ApplicationCtrl.getSupportedLanguages';
import saveLanguageSelection from '@salesforce/apex/GGW_ApplicationCtrl.saveLanguageSelection'; 
import getLanguageSelection from '@salesforce/apex/GGW_ApplicationCtrl.getLanguageSelection'; 
export default class GgwLanguageSelector extends LightningElement {
    @api applicationid;
    // Language setting uses ISO language country code (language_COUNTRY) 
    // https://www.ibm.com/docs/en/radfws/9.6.1?topic=overview-locales-code-pages-supported
    @api language;
    @track langOptions = [];// = [{ label: 'English', value: 'en_US' },{ label: 'German', value: 'de_DE' },{ label: 'Japanese', value: 'ja_JP' }];
    error;
    _title = 'Language selector';
    message = 'Language selected';
    variant = 'success';
    
    @wire(getSupportedLanguages)
        wireSupportedLanguages({error,data}){
            if (data) {
                for(var i = 0; i < data.length; i++)  {
                    this.langOptions = [...this.langOptions ,{label: data[i].label, value: data[i].value} ];  
                }                
                this.error = undefined;
            }else if(error){
                console.log(error);
                this.error = error;
            }else{
		        // eslint-disable-next-line no-console
		        console.log('unknown error')
            }
        }

    connectedCallback() {
        this.initLanguageSelection();
    }
    initLanguageSelection(){
        getLanguageSelection({ appId: this.applicationid }) 
            .then((result) => {
                console.log('CALL wiredLanguageSelection');
                console.log('LANG data: '+result);
                this.language = result;
                this.error = undefined;
            }) 
            .catch((error) => {
                this.error = error;
                this.language = undefined;
                console.log('LANG ERROR: '+JSON.stringify(error));
            });
    }
    //gettter to return items which is mapped with options attribute
    get languageOptions() {
        return this.langOptions;
    }
    languageChange(event) {
        this.language = event.target.value;
        this.sname = event.target.name;
        console.log('Event SELECTED LANG: '+this.language);
        const isEmpty = (str) => (!str?.length);
        // save to state
        if (!isEmpty(this.language)){
            // Call save SFDC method
            console.log('isEmpty function worked SELECTED LANG: '+this.language);
            saveLanguageSelection({ lang: this.language, appId: this.applicationid })
                .then((result) => {
                    //this.contacts = result;
                    console.log('Function call response: '+result);
                    console.log('SAVED Language selection: '+this.language);
                    this.error = undefined;
                    this.message = 'Selected language for Grant Application: '+this.language;
                    this.variant = 'success';
                    
                    // Creates the event with the selected language data.
                    const selectedEvent = new CustomEvent('languagechange', { detail: this.language });
                    // Dispatches the event.
                    this.dispatchEvent(selectedEvent);    

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
    }
}