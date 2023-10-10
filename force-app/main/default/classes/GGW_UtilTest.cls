/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_UtilTest unit test for utility class support GGW.
 */
@IsTest
public class GGW_UtilTest {
    public static String ggGtSteObj = GGW_Grant_State__c.sobjecttype.getDescribe().getName();
    public static String ggGtStLanField = GGW_Grant_State__c.Language__c.getDescribe().getName();
    
    @TestSetup
    static void makeData(){
        // Samlple content data for testing methods
        GGW_TestDataFactory.createGrantContentTestData();

        String uniqueUserName = 'grantuser' + DateTime.now().getTime() + '@labsorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'GGW_User_Permissions'];
        User u = new User(Alias = 'standt', Email='grantuser@labsorg.com',
                        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id,
                        TimeZoneSidKey='America/Los_Angeles',
                        UserName=uniqueUserName);   
        insert u;

    }

    @isTest
    static void testNewsaveGrantState(){
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }

        // This code runs as the system user
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'GGW_User_Permissions'];
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);                 

        System.runAs(u) {
            GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('Grant App', sections);

            Test.startTest();
                GGW_Util.saveGrantState(app.Id);
            Test.stopTest();
            system.debug('### TEST '+app.Id);
            
            
            GGW_Grant_State__c st = GGW_Util.getGrantState();
            system.debug('### TEST STATE '+st.Id);
            
            System.assertNotEquals(null, app,'Application is invalid'); 
            System.assertNotEquals(null, app.Id,'New Application did not save'); 
            System.assertNotEquals(null, st,'Application state is invalid');  
            System.assertNotEquals(null, st.Id, 'Application state is invalid');   
            // Check app ID
            System.assertEquals(app.Id, st.Grant_Application__c, 'NO Grant application found'); 
        } 
    }

    @isTest
    static void testExistingGrantState(){
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        // This code runs as the system user
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'GGW_User_Permissions'];
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                        LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                        FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);                 
                    
        System.runAs(u) {
   
            GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('Grant App', sections);
            GGW_Util.saveGrantState(app.Id);

            Test.startTest();
            GGW_Grant_State__c st = GGW_Util.getGrantState();
            Test.stopTest();
        
            System.assertNotEquals(null, st, 'Application state is invalid');   
            System.assertNotEquals(null, st.Id, 'Application state is invalid');   
            System.assertEquals(app.Id, st.Grant_Application__c, 'State missing Grant application'); 
        } 
    }

    @isTest
    static void testGetSelectedItems(){
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('Grant App', sections);

        Test.startTest();
        List<GGW_Selected_Item__c> lstItems = GGW_Util.getSelectedItems(app.Id);
        Test.stopTest();    
        System.assertEquals(sections.size(), lstItems.size(), 'Grant app missing selected items'); 

    }
    @isTest
    static void testQueryGrantApp(){
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('Grant App', sections);

        Test.startTest();
        GGW_Grant_Application__c grant = GGW_Util.queryGrantApp(app.Id);
        Test.stopTest();    
        System.assertEquals(grant.Name, 'Grant App', 'Could not create a new grant application'); 
        
    }
    @isTest
    static void testSelectOptionFromPicklist(){
        Test.startTest();
        List<GGW_Util.PickList> picList = GGW_Util.getSelectOptionFromPicklist(ggGtSteObj, ggGtStLanField, true);
        Test.stopTest();
        System.assertNotEquals(picList, null, 'No supported language found in mentadata'); 
        // Find English Code selector
        String lcode = '';
        for (GGW_Util.PickList p : picList){
            if(p.value == 'en_US' && p.label == 'English'){
                lcode = p.value;
            }
        }
        System.assertEquals(lcode, 'en_US', 'Supported Language not found in metadata'); 
    }
    @isTest
    static void testToLanguageLabel(){
        Test.startTest();
        // Translate ISO language code to language label en_US -> English
        String lang = GGW_Util.toLanguageLabel('en_US');
        // Test false value - fo NOT existing values expect to default to English
        String langNegative = GGW_Util.toLanguageLabel('pi_NG');
        Test.stopTest();
        System.assertEquals(lang, 'English', 'No language label found for code en_US');
        System.assertEquals(lang, 'English', 'No language label found for code pi_NG'); // Defalt to English
    }
    @isTest
    static void testGetValueMapFromPicklist(){
        Test.startTest();
        Map<String, String> valMap = GGW_Util.getValueMapFromPicklist(ggGtSteObj, ggGtStLanField);
        Test.stopTest();
        System.assertEquals(valMap.size()>0,true,'State has some supported Languages');
        if(valMap.containsKey('en_US')){
            String ln = valMap.get('en_US');
            System.assertEquals(ln, 'English', 'No language label found for code en_US');
        }
    }
    @isTest
    static void saveGrantLanguage(){
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }

        // This code runs as the system user
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'GGW_User_Permissions'];
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                        LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                        FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);                 
                        
        System.runAs(u) {

            GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('Grant App', sections);
            Test.startTest();
                String  str = GGW_Util.saveGrantLanguage('en_US', app.Id);
            Test.stopTest();

            GGW_Grant_State__c st = GGW_Util.getGrantState();
            System.assertNotEquals(null, st, 'Application state is invalid');   
            System.assertNotEquals(null, st.Id, 'Application state is invalid');   
            System.assertEquals(app.Id, st.Grant_Application__c, 'State missing Grant application'); 
            // New state in new user context
            System.assertEquals(str, 'NEW Language state is inserted', 'Language selection did not match state');
        }
    }
}
