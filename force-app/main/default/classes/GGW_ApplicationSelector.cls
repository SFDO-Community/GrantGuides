/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_ApplicationSelector SOQL Query class support GGW.
 * 
 */
public with sharing class GGW_ApplicationSelector {
    public static List<GGW_Grant_Application__c> getGrantApplications(){
        return [SELECT Id, Name, Application_Name__c, Logo_Download_Url__c, 
                        DistributionPublicUrl__c, Status__c, Description__c, 
                        Language__c, Include_Logo__c  
                FROM GGW_Grant_Application__c 
                WITH SECURITY_ENFORCED];
    }

    public static GGW_Grant_Application__c queryGrantApp(String appId){
        return [SELECT Id, Name, Application_Name__c, Logo_Download_Url__c, 
                        DistributionPublicUrl__c, Status__c, Description__c, 
                        Language__c, Include_Logo__c  
                FROM GGW_Grant_Application__c 
                WHERE Id =: appId WITH SECURITY_ENFORCED LIMIT 1];
    }

}