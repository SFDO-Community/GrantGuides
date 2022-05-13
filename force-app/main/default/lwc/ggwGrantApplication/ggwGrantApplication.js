import { LightningElement ,wire , api, track } from "lwc";
import getSections from '@salesforce/apex/GGW_ApplicationCtrl.getSections';

export default class GgwGrantApplication extends LightningElement {
	@api
	recordId;
	@api
	objectApiName;

    toggleIconName = 'utility:preview';
    toggleButtonLabel = 'Add Content';

    sections = [];

    @wire(getSections)
    wireIntro({error,data}){
        if (data) {

            for(var i=0; i<data.length; i++)  {
                if(data[i].selected == true){
                    this.sections = [...this.sections ,{label: data[i].label, value: data[i].recordid, hasblocks: data[i].hasblocks, textblock: 'Text placeholder'} ];  
                }
            }                
            this.error = undefined;
        }else if(error){
            console.log(error);
            this.error = error;
            this.sections = undefined;
        }else{
            // eslint-disable-next-line no-console
            console.log('unknown error')
        }
    }


    // when the component is first initialized assign an initial value to the `greekLetter` variable
    //connectedCallback() {
    //    this.greekLetter = this.getRandomGreekLetter();
    //}

    // Handles click on the 'Show/hide content' button
    handleToggleClick() {
        // retrieve the classList from the specific element
        const contentBlockClasslist = this.template.querySelector(
            '.lgc-id_content-toggle'
        ).classList;
        // toggle the hidden class
        contentBlockClasslist.toggle('slds-hidden');

        // if the current icon-name is `utility:preview` then change it to `utility:hide`
        if (this.toggleIconName === 'utility:preview') {
            this.toggleIconName = 'utility:hide';
            this.toggleButtonLabel = 'Add content';
        } else {
            this.toggleIconName = 'utility:preview';
            this.toggleButtonLabel = 'Add content';
        }
    }

}