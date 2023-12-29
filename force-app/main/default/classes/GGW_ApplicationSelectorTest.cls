/**
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class GGW_ApplicationSelectorTest {

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
        GGW_Grant_Application__c grant = GGW_ApplicationSelector.queryGrantApp(app.Id);
        Test.stopTest();    
        System.assertEquals(grant.Name, 'Grant App', 'Could not create a new grant application'); 
        
    }
    @isTest
    static void getGrantApplicationsTest(){
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        // Create 2 grants with same sections top test list
        GGW_ApplicationCtrl.newGrant('Grant App 1', sections);
        GGW_ApplicationCtrl.newGrant('Grant App 2', sections);

        Test.startTest();
        List<GGW_Grant_Application__c> grantList =  GGW_ApplicationSelector.getGrantApplications();
        Test.stopTest();    
        System.assertEquals(2, grantList.size(), 'Query grant application invalid'); 
    }
}