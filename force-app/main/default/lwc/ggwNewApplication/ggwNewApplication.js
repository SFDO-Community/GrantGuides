import { LightningElement , wire } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import getSections from '@salesforce/apex/GGW_ApplicationCtrl.getSections'; 
import findSections from '@salesforce/apex/GGW_ApplicationCtrl.findSections';
/** The delay used when debouncing event handlers before invoking Apex method. */
const DELAY = 300;

export default class GgwNewApplication extends NavigationMixin(LightningElement) {
    value = []; //['Statement of need','Plan of action','Budget narrative']; // Sample recommends selected items
    options = []; // List of Suggested sections
    searchKey = ''; // Seach key for find Sections

    valueSectionAdd = [];
    optionsSectionAdd = [];

    //@wire(findSections, { searchKey: '$searchKey' })
    //sections;
    @wire(findSections, { searchKey: '$searchKey' })
        wireFoundSections({error,data}){
            if (data) {
                this.optionsSectionAdd = []; // Clear list to reset values
                for(var i=0; i<data.length; i++)  {
                    this.optionsSectionAdd = [...this.optionsSectionAdd ,{label: data[i].label, value: data[i].recordid} ];  
                    if(data[i].selected == true){
                        this.valueSectionAdd.push(data[i].recordid);
                    }
                }                
                this.error = undefined;
                
            }else if(error){
                console.log(error);
                this.error = error;
                this.optionsSectionAdd = undefined;
            }else{
                // eslint-disable-next-line no-console
                console.log('unknown error')
            }
        }

    // Select new section found from Search action
    handleNewSectionAdd(e){
        this.valueSectionAdd = e.detail.value;
        console.log('Select Section: '+e.detail.value);
        // Include selected section to Grap application list
        // Collection has CSV list ov values need to split and get element/s selected by this event
        const selArr = this.valueSectionAdd; //.split(',');
        console.log('Split array: '+this.valueSectionAdd);
        for(var i=0; i<this.optionsSectionAdd.length; i++)  {
            // Get label
            console.log('Section ID: '+this.optionsSectionAdd[i].value);
            if(this.optionsSectionAdd[i].value == this.valueSectionAdd){
                console.log('Add section: '+this.optionsSectionAdd[i].label+' ID:'+this.optionsSectionAdd[i].value);
                // Lets push select new section to main list
                this.options.push(this.optionsSectionAdd[i]);
                this.value.push(this.optionsSectionAdd[i].value);
            }
    /*    
            for(var j=0; j<selArr.length; j++){
                if(this.optionsSectionAdd[i].value === selArr[j]){
                    console.log('Add section: '+this.optionsSectionAdd[i]);
                    // Lets push select new section to main list
                    this.options.push(this.optionsSectionAdd[i]);
                }
            }*/
        }
    }

    // Seach method
    handleSectionSearchChange(event) {
        // Debouncing this method: Do not update the reactive property as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            this.searchKey = searchKey;
        }, DELAY);
    }

    // CREATE NEW Section - use standard page layout
    // Navigate to New Section record page
    handleNewSection(){
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'GGW_Section__c',
                actionName: 'new'
            }
        });  
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
        wireSugestedSection({error,data}){
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

    handleIncludeSectionChange(e) {
        this.value = e.detail.value;
    }

}