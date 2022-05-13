import { LightningElement , wire } from "lwc";
import getSections from '@salesforce/apex/GGW_ApplicationCtrl.getSections'; 
// APEX COUNT WORDS in Rich text
//GGW_Content_Block__c block = [SELECT Id, Name, Description__c, Section__c, CreatedDate FROM GGW_Content_Block__c WHERE Id = 'a011D000009yi31QAA'  LIMIT 1];

//integer cnt = block.Description__c.normalizeSpace().stripHtmlTags().replaceAll('\\S','').length() ;
//System.debug('### RICH Text words: '+cnt);

export default class GgwNewApplication extends LightningElement {
    value = []; //['Statement of need','Plan of action','Budget narrative']; // Sample selected items
    options = [];
    queryTerm;

    handleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey) {
            this.queryTerm = evt.target.value;
        }
    }  
    
    handleNewSection(){
        
    }

/** Sample data for options
    get options() {
        return [
            { label: 'Statement of need', value: 'Statement of need' },
            { label: 'Program narrative', value: 'Program narrative' },
            { label: 'Plan of action', value: 'Plan of action' },
            { label: 'Goals and objectives', value: 'Goals and objectives' },
            { label: 'Measurable outcomes', value: 'Measurable outcomes' },
            { label: 'Budget narrative', value: 'Budget narrative' },

        ];
    }
*/
    @wire(getSections)
        wireIntro({error,data}){
            if (data) {

                for(var i=0; i<data.length; i++)  {
                    this.options = [...this.options ,{label: data[i].label, value: data[i].recordid} ];  
                    if(data[i].selected == true){
                        this.value.push(data[i].recordid);
                    }
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


    get selectedValues() {
        return this.value.join(',');
    }

    handleChange(e) {
        this.value = e.detail.value;
    }

}