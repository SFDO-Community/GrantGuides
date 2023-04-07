/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * Test class for GGW_ContentBlockWrapper wrapper class support Grant content block.
 * 
 */
@IsTest
public class GGW_ContentBlockWrapperTest {
    @TestSetup
    static void makeData(){
        // Samlple content data for testing methods
        GGW_TestDataFactory.createGrantContentTestData();
    }

    @isTest
    static void testBlockWrapperConstructors(){
        List<GGW_Content_Block__c> cbList = [SELECT Id, Name, Description__c, Short_Description__c, 
                                                    Section__c, Section__r.Name, CreatedDate, 
                                                    Language__c 
                                            FROM GGW_Content_Block__c ORDER BY Section__c];
        GGW_Content_Block__c firstBlock = cbList[0];
        Test.startTest();
        GGW_ContentBlockWrapper emptyBlock = new GGW_ContentBlockWrapper();
        GGW_ContentBlockWrapper textBlock =  new GGW_ContentBlockWrapper(firstBlock, 2);
        Test.stopTest();
        
        System.assertEquals('English', emptyBlock.languagelabel, 'Default constructor did not set default language label - English'); 
        System.assertEquals('en_US', emptyBlock.language, 'Default constructor did not set default language ISO code value - en_US'); 

        System.assertEquals(2, textBlock.totalblocks, 'Expected total block 2 did not match'); 
        System.assertEquals(firstBlock.Name, textBlock.title, 'Expected block name to tile did not match'); 
        System.assertEquals(firstBlock.Section__c, textBlock.sectionid, 'Block parent section not valid'); 
    }

}