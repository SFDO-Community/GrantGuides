/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement, wire  } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import insertSampleSections from '@salesforce/apex/GGW_SampleData.insertSampleSections';
import isSectionExists from '@salesforce/apex/GGW_SampleData.isSectionExists';
import GGW_AGNOSTIC from '@salesforce/resourceUrl/ggw_start_image';

export default class GgwIntro extends NavigationMixin(LightningElement) {
    title;
    header; // = 'Grant';
    displaytext;
    error;
    _title = 'Notification';
    camaImage;
    ggwAgnostic = GGW_AGNOSTIC;
    showIntro = true;
    showStart = false;
    showDataImportBtn = true;
    showStartAppBtn = false;

    handleStart(){
        this.showIntro = false;
        this.showStart = true; 
    }
    handleDataImport(){
        insertSampleSections()
            .then((result) => {
                //this.contacts = result;
                console.log('SAMPL DATA: '+JSON.stringify(result));
                this.error = undefined;

                this.showStartAppBtn=true;
                this.showDataImportBtn=false;

                // Display toaster message
                const evt = new ShowToastEvent({
                    title: this._title,
                    message: 'Sample data sections imported.',
                    variant: 'success',
                });
                this.dispatchEvent(evt);

            })
            .catch((error) => {
                this.error = error;            
                // Display toaster message
                const evt = new ShowToastEvent({
                    title: this._title,
                    message: this.error,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            });
    }
    handleNaviTest(){
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'GGW_Grant_Editor'
            },
            state: {
                c__recordId: 'a001D000005DsP7QAK'
            }
        });
    }  
    
    @wire(isSectionExists)
    wireIsSectionExists({error,data}){
        if (data) {
            this.showDataImportBtn = data;
            if(this.showDataImportBtn){
                this.showStartAppBtn = false;
            }else{
                this.showStartAppBtn = true;
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

}