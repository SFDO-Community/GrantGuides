/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_UtilTest unit test for utility class support GGW.
 */
@IsTest
public class GGW_UtilTest {
    @TestSetup
    static void makeData(){
        // Create test sections
        GGW_Section__c stmt_need = new GGW_Section__c();
        stmt_need.Name = 'Statement of need';
        stmt_need.Sort_Order__c = 1;
        stmt_need.Suggested__c = true;
        stmt_need.Recommended__c = true;
        insert stmt_need;
        // create related Blocks
        GGW_Content_Block__c cblock = new GGW_Content_Block__c();
        cblock.Name = 'Project XYZ';
        cblock.Section__c = stmt_need.Id; // Link thsi block to Statement of need
        cblock.Description__c = 'The oceans are in more trouble than ever before. Right now it is estimated that up to 12 million metric tons of plastic—everything from plastic bottles and bags to microbeads—end up in the oceans each year. That’s a truckload of trash every minute.';
        cblock.Short_Description__c = 'Project XYZ';
        insert cblock;
        // -----------
        GGW_Section__c goal = new GGW_Section__c();
        goal.Name = 'Goals and objectives';
        goal.Sort_Order__c = 2;
        goal.Suggested__c = true;
        goal.Recommended__c = true;
        insert goal;
        // create related Blocks
        GGW_Content_Block__c bblock = new GGW_Content_Block__c();
        bblock.Name = 'New text';
        bblock.Section__c = goal.Id; // Link thsi block to Statement of need
        bblock.Description__c = 'Text placeholder try edit this text and save lets edit this text. Then add to library to reuse later on.';
        bblock.Short_Description__c = 'New block';
        insert bblock;
        // -----------
        // Create test sections
        GGW_Section__c program = new GGW_Section__c();
        program.Name = 'Program narrative';
        program.Sort_Order__c = 3;
        program.Suggested__c = true;
        program.Recommended__c = true;
        insert program;
        // create related Blocks
        GGW_Content_Block__c dblock = new GGW_Content_Block__c();
        dblock.Name = 'Green Pilot Program';
        dblock.Section__c = program.Id; // Link thsi block to Statement of need
        dblock.Description__c = 'The Environmental Green Pilot Program Proposal is an example of a proposal using Proposal Pack to pitch an environmental green pilot program to a community to reduce utility costs through renewable energy use.';
        dblock.Short_Description__c = 'Project XYZ';
        insert dblock;

        // Not selected section for search
        GGW_Section__c src = new GGW_Section__c();
        src.Name = 'Test search';
        src.Sort_Order__c = 2;
        src.Suggested__c = false;
        src.Recommended__c = false;
        insert src;
        // create related Blocks
        GGW_Content_Block__c sblock = new GGW_Content_Block__c();
        sblock.Name = 'Search block';
        sblock.Section__c = src.Id; // Link thsi block to Statement of need
        sblock.Description__c = 'Text placeholder try edit this text and save lets edit this text. Then add to library to reuse later on.';
        sblock.Short_Description__c = 'Search block';
        insert sblock;

    }

    @isTest
    static void testNewsaveGrantState(){
        // Query all suggested sections
        List<GGW_ApplicationCtrl.GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_ApplicationCtrl.GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }

        String uniqueUserName = 'grantuser' + DateTime.now().getTime() + '@labsorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='grantuser@labsorg.com',
                        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id,
                        TimeZoneSidKey='America/Los_Angeles',
                        UserName=uniqueUserName);   
                        
        System.runAs(u) {
            GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('Grant App', sections);

            Test.startTest();
                GGW_Util.saveGrantState(app.Id);
            Test.stopTest();
            GGW_Grant_State__c st = GGW_Util.getGrantState();
            System.assertNotEquals(null, st);  
            System.assertNotEquals(null, st.Id);   
            // Check app ID
            System.assertEquals(app.Id, st.Grant_Application__c); 
        } 
    }

    @isTest
    static void testExistingGrantState(){
        // Query all suggested sections
        List<GGW_ApplicationCtrl.GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_ApplicationCtrl.GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        String uniqueUserName = 'grantuser' + DateTime.now().getTime() + '@labsorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='grantuser@labsorg.com',
                        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id,
                        TimeZoneSidKey='America/Los_Angeles',
                        UserName=uniqueUserName);   
                        
        System.runAs(u) {

            GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('Grant App', sections);
            GGW_Util.saveGrantState(app.Id);

            Test.startTest();
            GGW_Grant_State__c st = GGW_Util.getGrantState();
            Test.stopTest();
        
            System.assertNotEquals(null, st);   
            System.assertNotEquals(null, st.Id);   
            System.assertEquals(app.Id, st.Grant_Application__c); 
        } 
    }

    @isTest
    static void testGetSelectedItems(){
        // Query all suggested sections
        List<GGW_ApplicationCtrl.GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_ApplicationCtrl.GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('Grant App', sections);

        Test.startTest();
        List<GGW_Selected_Item__c> lstItems = GGW_Util.getSelectedItems(app.Id);
        Test.stopTest();    
        System.assertEquals(sections.size(), lstItems.size()); 

    }
}
