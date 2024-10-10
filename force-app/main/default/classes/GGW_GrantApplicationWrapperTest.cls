/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * Test class for GGW_GrantApplicationWrapper wrapper class support Grant.
 * 
 */
@IsTest
public class GGW_GrantApplicationWrapperTest {
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
    static void testGrantApplicationWrapperConstructor(){

        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        System.runAs(u) {
        // Samlple content data for testing methods
        GGW_TestDataFactory.createGrantContentTestData();
        Test.startTest();
        GGW_GrantApplicationWrapper app = new GGW_GrantApplicationWrapper();
        app.name = 'Test Grant';
        app.status = 'In Progress';
        app.language = 'en_US';
        app.logodisplayurl = 'https://grant.logo.org/logo.png';
        app.unselectSectionList = GGW_ApplicationCtrl.getSections();
        Test.stopTest();

        System.assertNotEquals(null, app, 'Default constructor faild to create wrapper grant object');
        }
    }
}