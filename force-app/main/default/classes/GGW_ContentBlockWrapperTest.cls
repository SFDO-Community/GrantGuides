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
    static void testBlockWrapperConstructors(){

        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();
 
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

}