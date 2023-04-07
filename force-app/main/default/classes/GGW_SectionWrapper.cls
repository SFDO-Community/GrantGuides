/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_SectionWrapper wrapper class support Grant sections.
 * 
 */

public class GGW_SectionWrapper {
    @AuraEnabled public String recordid;
    @AuraEnabled public String label;
    @AuraEnabled public Boolean selected; 
    @AuraEnabled public Boolean hasblocks;
    @AuraEnabled public String language;

    // BASIC Constrauctior Create Section object mapp from GGW_Section__c
    public GGW_SectionWrapper(GGW_Section__c s){
        this.recordid = s.Id;
        this.label = s.Name;
        this.selected = s.Recommended__c;
        this.hasblocks = true; // default assuming blocks exist
    }

    // Create Section object mapp from GGW_Section__c and find Blocks
    public GGW_SectionWrapper(GGW_Section__c s, Set<String> setOfSectionsWithBlock){
        this.recordid = s.Id;
        this.label = s.Name;
        this.selected = s.Recommended__c;
        this.hasblocks = setOfSectionsWithBlock.contains(s.Id);
    }
}