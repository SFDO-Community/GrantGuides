/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_ContentBlockSelector Salesforce Content Block text data selector class support GGW.
 * 
 */
public with sharing class GGW_ContentBlockSelector {
    public static GGW_Content_Block__c queryContentBlockById(Id blockId){
        GGW_Content_Block__c cBlock = [SELECT Id, Name, Description__c 
                                        FROM GGW_Content_Block__c 
                                        WHERE Id =: blockId WITH SECURITY_ENFORCED LIMIT 1];
        return cBlock;
    }
    public static List<GGW_Content_Block__c> queryContentBlocksBySection(Id sectionId){
        List<GGW_Content_Block__c> cbList = [SELECT Id, Name, Description__c, Short_Description__c, 
                                                Section__c, Section__r.Name, CreatedDate, 
                                                Language__c  
                                                FROM GGW_Content_Block__c 
                                                WHERE Section__c =: sectionId WITH SECURITY_ENFORCED];
        return cbList;
    }
    public static List<GGW_Content_Block__c> queryContentBlocks(){
        List<GGW_Content_Block__c> cbList = [SELECT Id, Name, Description__c, Short_Description__c, 
                                                Section__c, Section__r.Name, CreatedDate, 
                                                Language__c 
                                            FROM GGW_Content_Block__c WITH SECURITY_ENFORCED ORDER BY Section__c];
        return cbList;
    }
}