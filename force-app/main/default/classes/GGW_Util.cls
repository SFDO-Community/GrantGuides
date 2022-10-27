
/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_Util class for support utility methods on Grant application.
 * Used by standard and Custom controller
 */
public without sharing class GGW_Util {
    // Pass Grant application ID record
    // return a list of selected Items (sections+blocks)
    public static List<GGW_Selected_Item__c> getSelectedItems(String appId) {
        system.debug('### Grant ID:'+appId);
        List<GGW_Selected_Item__c> items = new List<GGW_Selected_Item__c>();
        items = [SELECT Id, Name, Application_Name__c, Grant_Application__c, Selected_Block__c, 
                        GGW_Section__c, Section_Name__c, Text_Block__c,  Sort_Order__c
                    FROM GGW_Selected_Item__c 
                    WHERE Grant_Application__c =: appId WITH SECURITY_ENFORCED ORDER BY Sort_Order__c];
        return items;
    }
    public static GGW_Grant_Application__c queryGrantApp(String appId){
        return [SELECT Id, Name, Application_Name__c, Logo_Download_Url__c, 
                        DistributionPublicUrl__c, Status__c, Description__c 
                FROM GGW_Grant_Application__c 
                WHERE Id =: appId WITH SECURITY_ENFORCED LIMIT 1];
    }

    // Save Grant state for User
    public static void saveGrantState(String grantId){
        GGW_Grant_State__c st = getGrantState();
        if(st != null && st.Id != null){
            // Update existing single state
            st.Grant_Application__c = grantId;
            update st;
        }else{
            st = new GGW_Grant_State__c();
            st.Current_User__c = UserInfo.getUserId(); // save state for current user
            st.Grant_Application__c = grantId;
            insert st;
        }
    }
    // Get state
    public static GGW_Grant_State__c getGrantState(){
        List<GGW_Grant_State__c> lst = [SELECT Id, Current_User__c, Grant_Application__c 
                                        FROM GGW_Grant_State__c 
                                        WHERE Current_User__c =:UserInfo.getUserId() WITH SECURITY_ENFORCED];
        GGW_Grant_State__c grant = new GGW_Grant_State__c();                
        if(lst != null && lst.size()>0){
            grant = lst[0];
        }
        return grant;
    }
}
