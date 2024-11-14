/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_ExportCtrlTest unt test for APEX controller extension 
 * class support GGW_Grant_Application__c record page.
 * Used to render preview of Grant application as PDF
 */
@IsTest
public class GGW_ExportCtrlTest {
    @TestSetup
    static void makeData(){

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

        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);                 
    }

    @isTest
    static void testExportCtrl(){

        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();
 
        // Unit test for conroller extention when used as part of record page context
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        // Create new Gran application and set up selected Items
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('MyTest Grant', sections);

        Test.startTest();
        ApexPages.StandardController stdGrant = new ApexPages.StandardController(app);
	    GGW_ExportCtrl grantExportController  = new GGW_ExportCtrl(stdGrant);
        Test.stopTest();

        // Check data created in ctrl contructor
        System.assertEquals(app.Id, grantExportController.recordId, 'Grant ID for export not valid'); 
        System.assertEquals(app.Name, grantExportController.appName, 'Grant name selected for export does not exist - MyTest Grant');
        // 3 section expected to be added to grand
        System.assertEquals(3, grantExportController.items.size(), 'Grant expected 3 items for export, size did not match test.');
            }
        }

    @isTest
    static void testExportWithPage(){

        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();
 
        // Unit test for conroller extention when NOT Record page but pass parameter recordId
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        // Create new Gran application and set up selected Items
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('MyTest Grant', sections);
        // Need to save state record
        GGW_Grant_State__c st = new GGW_Grant_State__c();
        st.Grant_Application__c = app.Id;
        insert st;

        // Create dummy Grant object as empty
        GGW_Grant_Application__c app_empty = new GGW_Grant_Application__c();
        Test.startTest();
        ApexPages.StandardController stdGrant = new ApexPages.StandardController(app_empty);
	    GGW_ExportCtrl grantExportController  = new GGW_ExportCtrl(stdGrant);
        Test.stopTest();

        System.assertEquals(null, grantExportController.recordId, 'Negative test with empty Grant for export expected null value'); 
        System.assertEquals('This view requires a Grant record, missing.', grantExportController.appName, 'Negative test empty Grant expect missing name error message');
            }
    }
}
