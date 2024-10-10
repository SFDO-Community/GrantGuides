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
    static void testSectionWrapperConstructors(){
        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();
        
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
}