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
        // Samlple content data for testing methods
        GGW_TestDataFactory.createGrantContentTestData();
    }

    @isTest
    static void testGrantApplicationWrapperConstructor(){

        Test.startTest();
        GGW_GrantApplicationWrapper app = new GGW_GrantApplicationWrapper();
        app.name = 'Test Grant';
        app.status = 'Progress';
        app.language = 'en_US';
        app.logodisplayurl = 'https://grant.logo.org/logo.png';
        app.unselectSectionList = GGW_ApplicationCtrl.getSections();
        Test.stopTest();

        System.assertNotEquals(null, app, 'Default constructor faild to create wrapper grant object');
    }
}