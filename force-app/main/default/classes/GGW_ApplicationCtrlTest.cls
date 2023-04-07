/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_ApplicationCtrlTest unt test for controller class support GGW.
 */
@IsTest
public class GGW_ApplicationCtrlTest {
    
    @TestSetup
    static void makeData(){
        // Samlple content data for testing methods
        GGW_TestDataFactory.createGrantContentTestData();
    }

    @isTest
    static void testNewGrant(){
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }

        Test.startTest();
        
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('MyTest Grant', sections);

        Test.stopTest();
        
        System.assertEquals('MyTest Grant', app.Name, 'Grant name did not match'); 
        System.assertEquals('Progress', app.Status__c, 'Initial grant status not set correctly to Progress'); 
        // Check if all section are created for app
        List<GGW_Selected_Item__c> selectedItems = [SELECT Id, Name, Grant_Application__c, GGW_Section__c, Sort_Order__c 
                                                    FROM GGW_Selected_Item__c WHERE Grant_Application__c =:app.Id];
        System.assertEquals(sections.size(), selectedItems.size(), 'Clone for grant sections to items did not complete'); 
    }
    @isTest
    static void testFindSections(){
        String searchKey = 'Test';
        Test.startTest();
        List<GGW_SectionWrapper> sw = GGW_ApplicationCtrl.findSections(searchKey);
        Test.stopTest();
        System.assertNotEquals(0, sw.size(), 'No sections found in test data');
        System.assertEquals('Test search', sw[0].label, 'First Section label did not match value - Test search');
        System.assertEquals(false, sw[0].selected, 'First section selected not correct');

        // Negative test asserts not found section by key
        searchKey = 'fail';
        List<GGW_SectionWrapper> swfail = GGW_ApplicationCtrl.findSections(searchKey);
        System.assertEquals(0, swfail.size(), 'Section search for hidden section did not return valid data');
    }
    @isTest
    static void testGetSections(){
        Test.startTest();
        List<GGW_SectionWrapper> sw = GGW_ApplicationCtrl.getSections();
        Test.stopTest();
        System.assertEquals(3, sw.size(), 'No sample section data found');
    }
    @isTest
    static void testContentBlocks(){
        List<GGW_Section__c> sectionList = [SELECT Id, Name FROM GGW_Section__c WHERE Name = 'Statement of need'];
        String sectionid = sectionList[0].Id;
        Test.startTest();
        List<GGW_ContentBlockWrapper> blockList = GGW_ApplicationCtrl.getContentBlocks(sectionId);
        Test.stopTest();
        // TODO add detailed assertions
        System.assertNotEquals(0, blockList.size(), 'No sample data content blocks are found');
    }
    @isTest
    static void testAddTextBlockToLibrary(){
        List<GGW_Section__c> sectionList = [SELECT Id, Name FROM GGW_Section__c WHERE Name = 'Statement of need'];
        String sectionid = sectionList[0].Id;
        String richtext = 'Adding new block text content to section to reuse. Example text';
        Test.startTest();
        String str = GGW_ApplicationCtrl.addTextBlockToLibrary(sectionid, richtext, 'Test block');
        Test.stopTest();
        // Check if new block was created with default name
        GGW_Content_Block__c block = [SELECT Id, Name, Section__c, Description__c FROM GGW_Content_Block__c WHERE Id =:str ];
        System.assertEquals('Test block', block.Name, 'Block name not matching');
        System.assertEquals(str, block.Id, 'No Block ID found');
        System.assertEquals(sectionList[0].Id, block.Section__c, 'Block link to Section missing');
    }
    @isTest
    static void testCreateNewSection(){
        String name = 'Test section';
        Test.startTest();
        GGW_SectionWrapper sw = GGW_ApplicationCtrl.createNewSection(name);
        Test.stopTest();
        // assertion checks and set up
        GGW_Section__c maxOrder = [SELECT Sort_Order__c FROM GGW_Section__c WHERE Suggested__c = true  ORDER BY Sort_Order__c desc LIMIT 1];
        GGW_Section__c newSec = [SELECT Id, Name, Sort_Order__c, Recommended__c, Suggested__c FROM GGW_Section__c WHERE ID =: sw.recordid];
        System.assertEquals(name, sw.label, 'Section name did not match');
        // Ensure the order was set correct for new section as last in list
        System.assertEquals(maxOrder.Sort_Order__c, newSec.Sort_Order__c, 'Section order not valid');
        // Ensure defaults selected check
        System.assertEquals(newSec.Recommended__c,sw.selected, 'Recommended section vs selected not matching');
        System.assertEquals(true, newSec.Recommended__c, 'Default recommended section not valid');
        System.assertEquals(true, newSec.Suggested__c, 'Default suggested section not set');
    }

    @isTest
    static void testGetApplication(){
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
        GGW_GrantApplicationWrapper appWrapper = GGW_ApplicationCtrl.getApplication(app.Id);
        Test.stopTest();
        // assertion checks happy path and set up
        System.assertEquals(app.Id, appWrapper.recordid, 'No new grant was created');
        System.assertEquals('Grant App',appWrapper.name, 'Default grant name did not match - Grant App');
        System.assertEquals('Progress', appWrapper.status, 'Default grant status did not match expected - Progress');
        // Check selected Items created as content blocks wraper to number of sections
        System.assertEquals(sections.size(),appWrapper.selectedContentBlock.size(), 'The copy of created blocks from template did not match expected number');
    }
    @isTest
    static void testSaveSelectedSectionText(){
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('MyTest Grant Sections', sections);
        List<GGW_Selected_Item__c> selItemList = GGW_ApplicationCtrl.querySelectedItemsByGrant(app.Id);
        //List<GGW_Selected_Item__c> selItemList = [SELECT Id, Name, GGW_Section__c,Grant_Application__c, Sort_Order__c 
        //                                        FROM GGW_Selected_Item__c WHERE Grant_Application__c =:app.Id];
        String itemid = selItemList[0].Id; 
        String sectionId = selItemList[0].GGW_Section__c;
        Test.startTest();
        List<GGW_ContentBlockWrapper> bwList = GGW_ApplicationCtrl.getContentBlocks(sectionId);
        String blocktext = bwList[0].displaytext; // Save rich text from Block Wrappert to assert later
        GGW_ApplicationCtrl.saveSelectedSectionText(itemid, bwList[0].recordid);
        Test.stopTest();
        // assertion checks that item saved the Block text
        List<GGW_Selected_Item__c> savedItemList = GGW_ApplicationCtrl.querySelectedItemsByGrant(app.Id);
        System.assertEquals(blocktext, savedItemList[0].Text_Block__c, 'Block text did not match template'); 
    }
    @isTest
    static void testReorderSections(){
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('Grant App Order', sections);
        List<GGW_Selected_Item__c> selItemList = GGW_ApplicationCtrl.querySelectedItemsByGrant(app.Id);
        // List of selected Iteam IDs - GGW_Selected_Item__c
        List<String> itemList =  new List<String>();
        // FLip order first/last
        String first = selItemList[0].Id;
        String last = selItemList[selItemList.size()-1].Id;
        for (GGW_Selected_Item__c item:selItemList){
            itemList.add(item.Id);
        }
        itemList[0] = last;
        itemList[selItemList.size()-1] = first;
        Test.startTest();
        GGW_ApplicationCtrl.reorderSections(itemList, app.Id);
        Test.stopTest();
        // Check fliped order
        List<GGW_Selected_Item__c> selOrderedList = GGW_ApplicationCtrl.querySelectedItemsByGrant(app.Id);
        System.assertEquals(last, selOrderedList[0].Id, 'Last seleected section item did not match expected');                                             
        System.assertEquals(first, selOrderedList[selOrderedList.size()-1].Id, 'First seleectd section item did not match selected');
    }
    @isTest
    static void testUpdateSelectedItemText(){
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('MyTest Grant', sections);
        List<GGW_Selected_Item__c> selItemList = [SELECT Id, Name, Text_Block__c, GGW_Section__c,Grant_Application__c, Sort_Order__c 
                                                FROM GGW_Selected_Item__c WHERE Grant_Application__c =:app.Id];
        String itemid = selItemList[0].Id; 
        String richtext = 'Update this text for section block.';
        Integer count = selItemList.size();
        Test.startTest();
        GGW_ApplicationCtrl.updateSelectedItemText(itemid, richtext);
        Test.stopTest();

        System.assertEquals(count, selItemList.size(), 'Count of selected items not valid');
        // Check text was updated, query again to get updated record
        GGW_Selected_Item__c selItem = [SELECT Id, Name, Text_Block__c, GGW_Section__c, Grant_Application__c, Sort_Order__c 
                                                FROM GGW_Selected_Item__c WHERE Id =:itemid];
        System.assertEquals(richtext, selItem.Text_Block__c, 'Rich text in block not matching expected text');
    }

    @isTest
    static void testDeleteSectionItem(){
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('Grant Delete section', sections);
        List<GGW_Selected_Item__c> selItemList = [SELECT Id, Name,GGW_Section__c,Grant_Application__c, Sort_Order__c 
                                                FROM GGW_Selected_Item__c WHERE Grant_Application__c =:app.Id];
        String itemid = selItemList[0].Id; 
        Integer sectionCount = selItemList.size();
        Test.startTest();
        GGW_ApplicationCtrl.deleteSection(itemId);
        Test.stopTest();

        List<GGW_Selected_Item__c> newItemList = [SELECT Id, Name,GGW_Section__c,Grant_Application__c, Sort_Order__c 
                                                FROM GGW_Selected_Item__c WHERE Grant_Application__c =:app.Id];

        // Check that item was deleted
        System.assertEquals(sectionCount-1, newItemList.size(),'Assert failed DeleteSectionItem');
    }
    @isTest
    static void  testGetSupportedLanguages(){
        Test.startTest();
        List<GGW_Util.PickList> pl = GGW_ApplicationCtrl.getSupportedLanguages();
        Test.stopTest();
        System.assertEquals(pl.size()>0, true, 'Supported langauges found');   
    }
    @isTest
    static void testGetLanguageSelection(){
         // Query all suggested sections
         List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
         List<String> sections = new List<String>();
         for (GGW_SectionWrapper gww : lst){
             if(gww.selected){
                 sections.add(gww.recordid);
             }
         }
         GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('Grant Delete section', sections);
        
        Test.startTest();
        String str = GGW_ApplicationCtrl.getLanguageSelection(app.Id);
        // Test when there is NO application ID
        String strNoApp = GGW_ApplicationCtrl.getLanguageSelection(null);
        Test.stopTest();
        System.assertEquals(str, 'en_US', 'Failed to get application language');
        // NO application ID
        System.assertEquals(strNoApp, 'en_US', 'Negative test failed to get language selectino');
    }
    @isTest
    static void testSaveLanguageSelection(){
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('Grant Delete section', sections);
        
        Test.startTest();
        String str = GGW_ApplicationCtrl.saveLanguageSelection('en_US', app.Id);
        Test.stopTest();

        System.assertEquals(str, 'NEW Language state is inserted', 'Language select was not saved');
        String lang = GGW_ApplicationCtrl.getLanguageSelection(app.Id);
        System.assertEquals(lang, 'en_US', 'Failed to get saved language');
    }
}
