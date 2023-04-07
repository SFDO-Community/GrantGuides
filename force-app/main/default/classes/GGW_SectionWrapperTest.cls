/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * Test class for GGW_SectionWrapper wrapper class support Grant content section.
 * 
 */
@IsTest
public class GGW_SectionWrapperTest {
    @TestSetup
    static void makeData(){
        // Samlple content data for testing methods
        GGW_TestDataFactory.createGrantContentTestData();
    }

    @isTest
    static void testSectionWrapperConstructors(){
        List<GGW_Section__c> sectionList = [SELECT Id, Name, CreatedDate, Recommended__c, Suggested__c, 
                                            Sort_Order__c, Language__c 
                                            FROM GGW_Section__c 
                                            WHERE Suggested__c = true ORDER BY Sort_Order__c];
        GGW_Section__c firstSection = sectionList[0];
        Set<String> s1 = new Set<String>();
        s1.add(firstSection.Id);

        Test.startTest();
        //GGW_SectionWrapper sw = new GGW_SectionWrapper();
        GGW_SectionWrapper swSection = new GGW_SectionWrapper(firstSection);
        GGW_SectionWrapper swBlock = new GGW_SectionWrapper(firstSection, s1);
        Test.stopTest();

        System.assertNotEquals(null, swBlock, 'Default constructor faild to create wrapper section object'); 
        System.assertEquals(firstSection.Name, swSection.label, 'Default constructor section label name not valid'); 
        System.assertEquals(true, swSection.hasblocks, 'Default constructor section has no blocks'); 

    }
}