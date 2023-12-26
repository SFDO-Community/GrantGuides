/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_ContentSelector Grant Section data selector class support GGW.
 * 
 */
public with sharing class GGW_SectionSelector {
    public static List<GGW_Selected_Item__c> querySelectedItemsByGrant(String appId){
        List<GGW_Selected_Item__c> appItems = [SELECT Id, Application_Name__c, Grant_Application__c, GGW_Section__c, 
                                    Section_Name__c,Selected_Block__c, Sort_Order__c, Grant_Application__r.Status__c,
                                    Selected_Block__r.Description__c, Text_Block__c, Language__c 
                                    FROM GGW_Selected_Item__c 
                                    WHERE Grant_Application__c =: appId WITH SECURITY_ENFORCED ORDER BY Sort_Order__c];
        return appItems;
    }
    
    public static List<GGW_Section__c> querySectionsByLanguage(String lang){
        List<GGW_Section__c> sectionList = [SELECT Id, Name, CreatedDate, Recommended__c, Suggested__c, 
                                                Sort_Order__c, Language__c 
                                            FROM GGW_Section__c 
                                            WHERE Suggested__c = true AND Language__c =: lang 
                                            WITH SECURITY_ENFORCED ORDER BY Sort_Order__c];
        return sectionList;
    }
    public static List<GGW_Section__c> querySections(){
        List<GGW_Section__c> sectionList = [SELECT Id, Name, CreatedDate, Recommended__c, Suggested__c, 
                                                    Sort_Order__c, Language__c 
                                            FROM GGW_Section__c WITH SECURITY_ENFORCED ORDER BY Sort_Order__c];
        return sectionList;
    }
    public static List<GGW_Section__c> querySectionsByName(String searchKey){
        String key = '%' + searchKey + '%';
        List<GGW_Section__c> sectionList = [SELECT Id, Name, CreatedDate, Recommended__c, Suggested__c, 
                                                    Sort_Order__c, Language__c 
                                            FROM GGW_Section__c 
                                            WHERE Name LIKE :key AND Suggested__c = false 
                                            WITH SECURITY_ENFORCED ORDER BY Sort_Order__c LIMIT 20];
        return sectionList;
    }
    // Return section with max order to add next section
    public static GGW_Section__c findMaxOrderSection(){
        List<GGW_Section__c> maxOrderList = [SELECT Sort_Order__c 
                                                    FROM GGW_Section__c 
                                                    WHERE Suggested__c = true WITH SECURITY_ENFORCED ORDER BY Sort_Order__c desc];
        GGW_Section__c maxOrder = null;
            // Handle situation when Sort order is null - TODO MAY be good to require it
        for(GGW_Section__c section : maxOrderList ){
            if(section.Sort_Order__c != null && section.Sort_Order__c > 0){
                maxOrder = section; // assigned MAX order object first found END LOOP here
                break; // EXIT Loop
            }
        }
        return maxOrder;
    }
    
}