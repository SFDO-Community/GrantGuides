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
        // Create test sections
        // Samlple content data for testing methods
        GGW_TestDataFactory.createGrantContentTestData();
    }

    @isTest
    static void testExportCtrl(){
        // Unit test for conroller extention when used as part of record page context
        // Query all suggested sections
        List<GGW_ApplicationCtrl.GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_ApplicationCtrl.GGW_SectionWrapper gww : lst){
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

    @isTest
    static void testExportWithPage(){
        // Unit test for conroller extention when NOT Record page but pass parameter recordId
        // Query all suggested sections
        List<GGW_ApplicationCtrl.GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_ApplicationCtrl.GGW_SectionWrapper gww : lst){
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
