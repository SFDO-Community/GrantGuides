/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_SampleDataTest unt test for APEX  
 * class support GGW_SampleData.
 * Used to test sample data import
 */
@IsTest
public class GGW_SampleDataTest {

    @isTest
    static void testInsertSampleSections(){
        // POSITIVE Test validation
        // Call this method to insert Sections & Content Block sample data
        Test.startTest();
        String str = GGW_SampleData.insertSampleSections();
        Test.stopTest();
        System.assertNotEquals(null, str, 'Result string should not be null');
        System.assertEquals('Sample section data import complete. Sample block data import complete.', str, 'Result string is expected as success message');
        // Validate if sample data had been created for Section and Content Block
        List<GGW_Section__c> lstSection = [SELECT Id, Name FROM GGW_Section__c WITH SECURITY_ENFORCED];
        System.assertEquals(9, lstSection.size(), 'Sections list is expected to have records');
        List<GGW_Content_Block__c> lstContentBlock = [SELECT Id, Name FROM GGW_Content_Block__c WITH SECURITY_ENFORCED];
        System.assertEquals(23, lstContentBlock.size(), 'Block list is expected to have records');
    }

    @isTest
    static void testInsertSampleSectionsWithExisting(){
        // NEGATIVE Fail test validation
        // Create sample sections before test
        GGW_Section__c gs = new GGW_Section__c();
        gs.Name = 'Test Section';
        gs.Recommended__c = false;
        gs.Section_Details__c = 'Some details text here';
        gs.Sort_Order__c = 1;
        gs.Suggested__c = true;
        insert gs;

        // Call this method to insert Sections & Content Block sample data when data already exists
        Test.startTest();
        String str = GGW_SampleData.insertSampleSections();
        Test.stopTest();
        System.assertNotEquals(null, str, 'Result string should not be null');
        System.assertEquals('Section data already exists. IMPORT CANCELLED', str, 'Result string is expected as IMPORT CANCELED message');

    }
}
