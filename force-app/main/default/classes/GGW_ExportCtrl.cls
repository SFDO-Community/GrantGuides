/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_ExportCtrl controller class for VFP Export and render.
 * Standard controller extension used for Standard record page action 
 */
public with sharing class GGW_ExportCtrl {
    public String recordId {get; set;}
    public String appName {get;set;}
    public String logoURL {get; set;}
    public Boolean isDisplayLogo {get; set;}
    public List<GGW_Selected_Item__c> items {get; set;}
    private final GGW_Grant_Application__c app;

    public GGW_ExportCtrl(ApexPages.StandardController stdController) {
        this.isDisplayLogo = false;
        this.app = (GGW_Grant_Application__c)stdController.getRecord();
        if(this.app != null && this.app.Id != null){
            this.recordId = this.app.Id;
        }else{
            this.recordId = ApexPages.currentPage().getParameters().get('c__recordId');
        }
        // Get from saved state
        if(this.recordId == null || this.recordId.length() == 0){
            GGW_Grant_State__c st = GGW_Util.getGrantState();
            if(st != null && st.Grant_Application__c != null){
                this.recordId = st.Grant_Application__c;
            }
        }
        // set from URL Parm record ID
        //this.recordId = this.app.Id; //'a001D0000058zp2QAA';//ApexPages.currentPage().getParameters().get('id');
        system.debug('### PDF VIew ID:'+this.recordId);
        this.appName = 'This view requires a Grant record, missing.';
        if(this.recordId != null && this.recordId.length() > 0){
            GGW_Grant_Application__c app = GGW_ApplicationSelector.queryGrantApp(this.recordId.escapeHtml4());
            if(app != null && app.Logo_Download_Url__c != null){
                this.logoURL = app.Logo_Download_Url__c;
                if(app.Include_Logo__c == true){
                    this.isDisplayLogo = true;
                }
            }
        
            this.items = GGW_Util.getSelectedItems(this.recordId.escapeHtml4());
            if(items != null && items.size()>0){
                this.appName = items[0].Application_Name__c;
            }
        }

    }
}
