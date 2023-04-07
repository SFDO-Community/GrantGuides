/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_ContentBlockWrapper wrapper class support Grant content block.
 * 
 */
public class GGW_ContentBlockWrapper {
    @AuraEnabled public String recordid;
    @AuraEnabled public String sectionid;
    @AuraEnabled public String sectionname;
    @AuraEnabled public String title; // Display title map to Name
    @AuraEnabled public String displaytext; // map to Description__c
    @AuraEnabled public Integer wordcount; // Derived from Rich tect field in APEX count words
    @AuraEnabled public String displaybadge; // DEPRECATE Tag to display on the badge (Winner etc)
    @AuraEnabled public List<String> badgeList; // Tags to display on the badge (Winner etc) from Topics
    @AuraEnabled public String displaydate; // Created date
    @AuraEnabled public Integer totalblocks;
    @AuraEnabled public Boolean isselected;
    @AuraEnabled public String selecteditemid; // Id of selecetd item on application
    @AuraEnabled public Integer sortorder;
    @AuraEnabled public String language; // ISO Country lnaguage Code
    @AuraEnabled public String languagelabel; // Langauge name to display translated code
    public GGW_ContentBlockWrapper(){
        this.language = 'en_US'; // Default language
        this.languagelabel = 'English';
    }
    //. Construct and map Block fields
    public GGW_ContentBlockWrapper(GGW_Content_Block__c block, Integer cnt){
        this.isselected = false;
        this.recordid = block.Id;
        this.sectionid  = block.Section__c;
        this.sectionname = block.Section__r.Name;
        this.title = block.Name;
        this.displaytext = block.Description__c; // Rich text
        this.language = block.Language__c; // Language ISO CODE
        this.languagelabel = GGW_Util.toLanguageLabel(block.Language__c); // Language label
        // Count words in rich text with APEX methods
        integer words = block.Description__c.normalizeSpace().stripHtmlTags().replaceAll('\\S','').length() ;
        this.wordcount = words;
        this.displaydate = block.CreatedDate.format('YYYY-MM'); // Format this to short
        // Temporary value for tag default
        //this.displaybadge = ''; // TODO find how to fill this what make a tag?
        this.totalblocks = cnt;
        this.badgeList = new List<String>(); // init empty list fill in later
    }
}