/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement, api, wire  } from "lwc";
import getContentBlocks from '@salesforce/apex/GGW_ApplicationCtrl.getContentBlocks';

export default class GgwContentBlockModal extends LightningElement {
    @api section; //= 'a021D000007NGK8QAO';
    @api application;
    titleAvailableBlocks = 'No content blocks available'; // set default value
    contentblocks = [];
    selectedText = 'Text sample';
    selectedBlockId;

    @wire(getContentBlocks, { sectionId: '$section' })
    wireIntro({error,data}){
        if (data) {
            this.contentblocks = data; // Copy or clone [...data] Array.new(data) no effect on read only error
            this.titleAvailableBlocks = data[0].sectionname + ' (' + data[0].totalblocks + ' available)';
            this.error = undefined;
        }else if(error){
            console.log(error);
            this.error = error;
        }else{
            // eslint-disable-next-line no-console
            console.log('unknown error')
        }
    }
    // Select a block method
    handleSelectClick(evt){
        //console.log('### Button event: '+evt.target.name);
        //--- MUST do tehse JSON tricks to clone arraye to update data
        // if not get error Cannot assign to read only property
        let tmpBlocks = JSON.parse(JSON.stringify(this.contentblocks));
        // When selecting block with statefull button ensure all otehrs are DESELECTED Only one allowed selected
        for(var i=0; i<tmpBlocks.length; i++)  {
            try {
                if(tmpBlocks[i].recordid === evt.target.name){
                    //console.log('### Selected: '+ tmpBlocks[i].recordid + 'TTTT');
                    this.selectedBlockId = undefined;
                    if(tmpBlocks[i].isselected){
                        tmpBlocks[i].isselected = false;
                    }else{
                        tmpBlocks[i].isselected = true;
                        // set text value
                        this.selectedText = tmpBlocks[i].displaytext;
                        this.selectedBlockId = tmpBlocks[i].recordid;
                    }
                }else{
                    tmpBlocks[i].isselected = false;
                }
            }catch(err) {
                console.log('## ERROR: '+err.message);
            }
        }                
        this.contentblocks = tmpBlocks;

        // Creates the selectedblockchange event with the text data.
        if(this.selectedBlockId){
            var block = {blocktext: this.selectedText, blockid: this.selectedBlockId};
            const selectedBlockEvent = new CustomEvent("selectedblockchange", {
                detail: block,
                bubbles: true
            });
    
            // Dispatches the event.
            this.dispatchEvent(selectedBlockEvent);
        }
    }
}