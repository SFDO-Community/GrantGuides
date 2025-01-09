/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import insertSampleSections from '@salesforce/apex/GGW_SampleData.insertSampleSections';
import isSectionExists from '@salesforce/apex/GGW_SampleData.isSectionExists';
import GGW_AGNOSTIC_IMG from '@salesforce/resourceUrl/ggw_start_image';

const INTRO_HEADER_TXT = 'Start New Grant';
const INTRO_TXT = 'Select new grant sections';
const INTRO_HEADER_IMPORT_TXT = 'No Data';
const INTRO_IMPORT_TXT = 'Initialize Grant Kit from sample data';    

export default class GgwIntro extends NavigationMixin(LightningElement) {
    title;
    displaytext;
    error;
    _title = 'Notification';
    header = INTRO_HEADER_TXT;
    introtext = INTRO_TXT;
    camaImage;
    ggwAgnostic = GGW_AGNOSTIC_IMG;
    showIntro = true;
    showStart = false;
    showDataImportBtn = true;
    showStartAppBtn = true;
    isloaded = true;

    handleStart(){
        this.showIntro = false;
        this.showStart = true; 
    }
    handleDataImport(){
        this.isloaded = false; // Show Spinner
        insertSampleSections()
            .then((result) => {
                //this.contacts = result;
                console.log('SAMPL DATA: '+result); //JSON.stringify(result));
                this.error = undefined;
                this.header = INTRO_HEADER_TXT;
                this.introtext = INTRO_TXT;
                this.showStartAppBtn=true;
                this.showDataImportBtn=false;

                // Display toaster message
                const evt = new ShowToastEvent({
                    title: this._title,
                    message: result, //'Sample data sections imported.',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
                this.isloaded = true; // Hide Spinner - DONE
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
                this.isloaded = true; // Hide Spinner - DONE
            });
    }
    handleNaviTest(){
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: '%%%NAMESPACED_ORG%%%GGW_Grant_Editor'
            },
            state: {
                c__recordId: 'a001D000005DsP7QAK'
            }
        });
    }  
    
    checkDataImport(){
        isSectionExists()    
            .then ((data) => {
                console.log('isSectionExists: '+data);
                
                if(data == true){ // If section exists TRUE NO Import
                    this.header = INTRO_HEADER_TXT;
                    this.introtext = INTRO_TXT;            
                    this.showDataImportBtn = false;
                    this.showStartAppBtn = true;
                }else{
                    this.header = INTRO_HEADER_IMPORT_TXT;
                    this.introtext = INTRO_IMPORT_TXT;    
                    this.showStartAppBtn = false;
                    this.showDataImportBtn = true;
                }
                this.error = undefined;
            })
            .catch((error) => {
                console.log(error);
                this.error = error;
            });
    }
    connectedCallback() {
        this.checkDataImport();
    }
    
}