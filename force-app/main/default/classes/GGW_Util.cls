
/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_Util class for support utility methods on Grant application.
 * Used by standard and Custom controller
 */
public with sharing class GGW_Util {
    public static String ggGtSteObj = GGW_Grant_State__c.sobjecttype.getDescribe().getName();
    public static String ggGtStLanField = GGW_Grant_State__c.Language__c.getDescribe().getName();
   
    // Pass Grant application ID record
    // return a list of selected Items (sections+blocks)
    public static List<GGW_Selected_Item__c> getSelectedItems(String appId) {
        system.debug('### Grant ID:'+appId);
        List<GGW_Selected_Item__c> items = new List<GGW_Selected_Item__c>();
        items = [SELECT Id, Name, Application_Name__c, Grant_Application__c, Selected_Block__c, 
                        GGW_Section__c, Section_Name__c, Text_Block__c,  Sort_Order__c, Language__c
                FROM GGW_Selected_Item__c 
                WHERE Grant_Application__c =: appId WITH SECURITY_ENFORCED ORDER BY Sort_Order__c];
        return items;
    }
    public static Boolean isValidString(String str){
        Boolean res = false;
        if(str != null && str.length() > 0){
            res = true;
        }
        return res;
    }
    // Method save Langugae selection to user state
    public static String saveGrantLanguage(String lang, String grantId){
        String msg = 'Save language select failed.';
        GGW_Grant_State__c st = getGrantState();
        if(st != null && st.Id != null){
            if(isValidString(lang)){
                st.Language__c = lang;
            }
            if(isValidString(grantId)){
                st.Grant_Application__c = grantId;
            }
            if(Schema.sObjectType.GGW_Grant_State__c.isUpdateable()){
                update st;
                msg = 'Language state is updated';
            }
        }else{
            msg = insertNewState(lang, grantId);
        }
        return msg;
    }
    // Create New Grant state record for user when there is NONE exists
    private static String insertNewState(String lang, String grantId){
        String msg = 'New state insert failed.';
        GGW_Grant_State__c st = new GGW_Grant_State__c();
        st.Current_User__c = UserInfo.getUserId(); // save state for current user
        if(isValidString(lang)){
            st.Language__c = lang;
        }else{
            st.Language__c = UserInfo.getLanguage();
        }
        if(isValidString(grantId)){
            st.Grant_Application__c = grantId;
        }
        if(Schema.sObjectType.GGW_Grant_State__c.isCreateable()){
            insert st;
            msg = 'NEW Language state is inserted';
        }
        return msg;
    }
    // Save Grant state for User
    public static void saveGrantState(String grantId){
        GGW_Grant_State__c st = getGrantState();
        if(st != null && st.Id != null){
            // Update existing single state
            st.Grant_Application__c = grantId;
            if(Schema.sObjectType.GGW_Grant_State__c.isUpdateable()){
                update st;
            }
        }else{
            st = new GGW_Grant_State__c();
            st.Current_User__c = UserInfo.getUserId(); // save state for current user
            st.Grant_Application__c = grantId;
            if(Schema.sObjectType.GGW_Grant_State__c.isCreateable()){
                insert st;
            }
        }
    }
    public static String getGrantLanguage(){
        String lang = 'en_US';
        GGW_Grant_State__c st = getGrantState();
        if(st != null && isValidString(st.Language__c)){
            lang = st.Language__c;
        }
        return lang;
    }
    // Get current application state
    // Cannot use WITH SECURITY SOQL becuase of UserInfo not compatible
    public static GGW_Grant_State__c getGrantState(){
        List<GGW_Grant_State__c> lst = [SELECT Id, Current_User__c, Grant_Application__c, Language__c  
                                        FROM GGW_Grant_State__c 
                                        WHERE Current_User__c =:UserInfo.getUserId() ];
        GGW_Grant_State__c grant = new GGW_Grant_State__c();                
        if(lst != null && lst.size()>0){
            grant = lst[0];
        }
        return grant;
    }


  /**
   * Return select options list from any Object Picklist values and their translation
   * labels if any
   *
   * @param objectName - String name of the object to look for pick values and translations
   * @param fieldName - String API name for a field to look up pick values for
   * @param isNone - Boolean value state to add --None-- selector to start of the list if true
   * @return List - SelectOption for picklist object
   * Example use: 
 	List<SelectOption> sl = Util.getSelectOptionFromPicklist('GGW_Grant_State__c', 'Language__c', false);
	for (SelectOption s : sl){
      System.debug('#### '+s.getValue()+' '+s.getLabel());
	}   
    */
    public static List<PickList> getSelectOptionFromPicklist(String objectName, String fieldName, Boolean isNone){
        List<PickList> options = new List<PickList>();
        Map<String, Schema.SObjectType> globalObjectMap = Schema.getGlobalDescribe();
        Schema.SObjectType s = globalObjectMap.get(objectName);
        if (s != null) {
            Map<String, Schema.SObjectField> fMap = s.getDescribe().fields.getMap();
            Schema.DescribeFieldResult fieldResult = fMap.get(fieldName).getDescribe();
            if(fieldResult != null && fieldResult.isAccessible()){
                if (isNone){
                    options.add(new PickList('--None--','--None--'));
                }    
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for(Schema.PicklistEntry f : ple){
                    options.add(new PickList(f.getValue(),f.getLabel())); 
                }   
            }
        }    

        return options;    
    }
    public static String toLanguageLabel(String langcode){
        String langlbl = 'English';
        Map<String, String> valMap = getValueMapFromPicklist(ggGtSteObj, ggGtStLanField);
        if(valMap.containsKey(langcode)){
            langlbl = valMap.get(langcode);
        }
        return langlbl;
    } 
    // Translate Picklist values to label for display puroposes
    public static Map<String, String> getValueMapFromPicklist(String objectName, String fieldName){
        Map<String, String> valMap = new  Map<String, String>();
        List<PickList> valueList = getSelectOptionFromPicklist(objectName, fieldName, false);
        for(PickList pl : valueList){
            valMap.put(pl.value,pl.label);
        }
        return valMap;
    }
    public class PickList {   	
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}
        
        public PickList(String val, String lbl) {
            this.label = lbl;
            this.value = val;
        }
   }
}
