
/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_GrantApplicationWrapper wrapper class support Grant Application data.
 * 
 */
public class GGW_GrantApplicationWrapper {
    @AuraEnabled public String recordid;
    @AuraEnabled public String name; // This can hold a Lookup standard records URL link to Grant by Name
    @AuraEnabled public String textname; // Save only grant name as text
    @AuraEnabled public String status;
    @AuraEnabled public String logodisplayurl;
    @AuraEnabled public Boolean logostate;
    @AuraEnabled public String language;
    @AuraEnabled public List<GGW_SectionWrapper> unselectSectionList; // Used to add new sections to Grant
    @AuraEnabled public List<GGW_ContentBlockWrapper> selectedContentBlock; // Include Section and Text block
    public GGW_GrantApplicationWrapper(){
        this.language = 'en_US'; // default
    }
}