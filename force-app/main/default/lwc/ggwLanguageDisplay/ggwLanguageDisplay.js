import { LightningElement, wire, api, track  } from "lwc";
import getSupportedLanguages from '@salesforce/apex/GGW_ApplicationCtrl.getSupportedLanguages';
import getLanguageSelectionWire from '@salesforce/apex/GGW_ApplicationCtrl.getLanguageSelectionForWire'; 

export default class GgwLanguageDisplay extends LightningElement {
    @api applicationid;
    // Language setting uses ISO language country code (language_COUNTRY) 
    // https://www.ibm.com/docs/en/radfws/9.6.1?topic=overview-locales-code-pages-supported
    @api language;// = 'en_US';
    @track langOptions = [];// = [{ label: 'English', value: 'en_US' },{ label: 'German', value: 'de_DE' },{ label: 'Japanese', value: 'ja_JP' }];
    error;
    
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
		        console.log(`wireSupportedLanguages: unknown error - ${error} data: ${data}`);
            }
        }

        @wire(getLanguageSelectionWire, { appId: '$applicationid' })
        wiregetLanguageSelectionWire({error,data}){
            if (data) {
                console.log('CALL wiredLanguageSelection');
                console.log('LANG data: '+data);
                console.log('APP ID: ' + this.applicationid);

                this.language = data;
                this.error = undefined;
            }else if(error){
                console.log(error);
                this.error = error;
            }else{
		        // eslint-disable-next-line no-console
		        console.log(`wiregetLanguageSelection: unknown error ${error} data: ${data}`);
            }
        }
    //gettter to return items which is mapped with options attribute
    get languageOptions() {
        return this.langOptions;
    }


}