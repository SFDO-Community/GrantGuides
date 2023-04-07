
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
    @AuraEnabled public String name;
    @AuraEnabled public String status;
    @AuraEnabled public String logodisplayurl;
    @AuraEnabled public String language;
    @AuraEnabled public List<GGW_SectionWrapper> unselectSectionList; // Used to add new sections to Grant
    @AuraEnabled public List<GGW_ContentBlockWrapper> selectedContentBlock; // Include Section and Text block
}