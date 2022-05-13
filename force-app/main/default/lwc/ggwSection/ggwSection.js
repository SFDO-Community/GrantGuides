import { LightningElement, api , track } from "lwc";

export default class GgwSection extends LightningElement {
    @api sectionTitle = 'Default Section';
    @api textBlock = 'Text placeholder';
    @api sectionId;
    @api sectionHasBlocks; // Boolean value if section has block allow to save
    @track openModal = false;
    
    showModal() {
        console.log('# Section ID: '+this.key);
        this.openModal = true;
        this.textBlock = 'Text placehold';
    }
    // Close model no section change as cancel action
    closeModal() {
        this.openModal = false;
        this.textBlock = 'Text placehold';
    }
    // Save set selected section text and close modal
    saveCloseModal() {
        this.openModal = false;

        // TODO
        //if(this.sectionTitle == 'Statement of need'){
        //    this.textBlock = 'The oceans are in more trouble than ever before. Right now it is estimated that up to 12 million metric tons of plastic—everything from plastic bottles and bags to microbeads—end up in the oceans each year. That is a truckload of trash every minute. Traveling on ocean currents, this plastic is now turning up in every corner of our planet, from Florida beaches to uninhabited Pacific islands. It is even being found in the deepest part of the ocean and trapped in Arctic ice.';
        //}else{
        //    this.textBlock = 'Donate to our online programs to learn more about protecting our oceans. Give The Gift Which Could Last A Lifetime, Inspire A Career, and Help Our Oceans. Fun Online Classes. Experienced Educators. Amenities: Outdoor Fun, Educational, Safe, Experienced Educators.';
        //}
    }

    connectedCallback() {
        //this.subscribeToMessageChannel();
        this.textBlock = 'Text placehold';
    }

    hanldeSelectedBlockChange(event){
        this.textBlock = event.detail;
    }
}