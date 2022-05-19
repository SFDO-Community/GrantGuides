import { LightningElement  } from "lwc";
import GGW_AGNOSTIC from '@salesforce/resourceUrl/ggw_start_image';
export default class GgwIntro extends LightningElement {
    title;
    header; // = 'Grant';
    displaytext;
    camaImage;
    ggwAgnostic = GGW_AGNOSTIC;
    showIntro = true;
    showStart = false;

    handleStart(){
        // TODO
        this.showIntro = false;
        this.showStart = true; 
    }
}