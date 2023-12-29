import { LightningElement , api } from "lwc";
export default class GgwStaticNoDataCard extends LightningElement {
	@api
	recordId;
	@api
	objectApiName;
    @api displayTitle;
}