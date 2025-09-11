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
    static void includeLogoTest(){

        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();
        
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }

        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('MyTest Grant', sections);

        Test.startTest();
        String msg = GGW_ApplicationCtrl.includeLogo(app.Id, true);
        Test.stopTest();

        System.assertEquals('Application logo updated', msg, 'Invalid message returnd for Logo include into Grant'); 
        GGW_GrantApplicationWrapper grant = GGW_ApplicationCtrl.getApplication(app.Id);
        System.assertEquals(app.Id, grant.recordid, 'Invalid grant application Id');
        System.assertEquals(true, grant.logostate, 'Logo include state is not valid');
        }
    }

    static void excludeLogoTest(){
        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();
 
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }

        }

        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('MyTest Grant', sections);

        Test.startTest();
        String msg = GGW_ApplicationCtrl.includeLogo(app.Id, false);
        Test.stopTest();

        System.assertEquals('Application logo updated', msg, 'Invalid message returnd for Logo include into Grant'); 
        GGW_GrantApplicationWrapper grant = GGW_ApplicationCtrl.getApplication(app.Id);
        System.assertEquals(app.Id, grant.recordid, 'Invalid grant application Id');
        System.assertEquals(false, grant.logostate, 'Logo exclude state is not valid');
        }
    }

    @isTest
    static void deleteLogoTest(){

        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();

        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('Grant Logo delete Test', sections);

        //ContentDocument cdoc = new ContentDocument();
        //cdoc.Title = 'Grant test logo';
        //insert cdoc;

        ContentVersion cvo = new Contentversion();
        //cvo.ContentDocumentId = cdoc.Id;
        cvo.Title = 'Test Content file'; 
        cvo.PathOnClient = 'test'; 
        cvo.VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body'); 
        //List<ContentVersion> cvl = new List<ContentVersion>(); 
        //cvl.add(cvo); 
        insert cvo;

        ContentVersion cvtmp = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id =: cvo.Id];
        // Create content document Link
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = app.Id;
        cdl.ContentDocumentId = cvtmp.ContentDocumentId;
        insert cdl;
        
        String downloadURL = GGW_ApplicationCtrl.createContentDistribution(app.Id, cvo.Id);

        Test.startTest();
        String result = GGW_ApplicationCtrl.deleteLogo(app.Id);

        Test.stopTest();
        System.assertEquals('Logo image deleted', result, 'Logo delete is not valid');
        }
    }
    @isTest
    static void createContentDistributionTest(){
        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();

        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('Content Distribution Test', sections);

        System.debug('Grant App: '+ app.Id);
        
        ContentVersion cvo = new Contentversion();
        cvo.Title = 'Test Content file'; 
        cvo.PathOnClient = 'test'; 
        cvo.VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body'); 
        insert cvo;
        ContentVersion cvtmp = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id =: cvo.Id];
        // Create content document Link
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = app.Id;
        cdl.ContentDocumentId = cvtmp.ContentDocumentId;
        insert cdl;

        Test.startTest();
        String downloadURL = GGW_ApplicationCtrl.createContentDistribution(app.Id, cvo.Id);
        Test.stopTest();

        System.assertNotEquals(null, downloadURL, 'Content distribution is invalid');
        GGW_GrantApplicationWrapper grant = GGW_ApplicationCtrl.getApplication(app.Id);
        System.assertEquals(downloadURL, grant.logodisplayurl, 'Logo download URL is not valid');
        }
    }
    @isTest
    static void testNewGrant(){
        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();

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
        System.assertEquals('In Progress', app.Status__c, 'Initial grant status not set correctly to In Progress'); 
        // Check if all section are created for app
        List<GGW_Selected_Item__c> selectedItems = [SELECT Id, Name, Grant_Application__c, GGW_Section__c, Sort_Order__c 
                                                    FROM GGW_Selected_Item__c WHERE Grant_Application__c =:app.Id];
        System.assertEquals(sections.size(), selectedItems.size(), 'Clone for grant sections to items did not complete'); 
        }
    }
    @isTest
    static void testFindSections(){

        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
        LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
        FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];

        System.runAs(u) {

        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();

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
    }
    @isTest
    static void testGetSections(){

        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();

        Test.startTest();
        List<GGW_SectionWrapper> sw = GGW_ApplicationCtrl.getSections();
        Test.stopTest();
        System.assertEquals(3, sw.size(), 'No sample section data found');
        }
    }
    @isTest
    static void testContentBlocks(){
        
        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();

        List<GGW_Section__c> sectionList = [SELECT Id, Name FROM GGW_Section__c WHERE Name = 'Statement of need'];
        String sectionid = sectionList[0].Id;
        Test.startTest();
        List<GGW_ContentBlockWrapper> blockList = GGW_ApplicationCtrl.getContentBlocks(sectionId);
        Test.stopTest();
        // TODO add detailed assertions
        System.assertNotEquals(0, blockList.size(), 'No sample data content blocks are found');
        }
    }
    @isTest
    static void testAddTextBlockToLibrary(){

        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();

        List<GGW_Section__c> sectionList = [SELECT Id, Name FROM GGW_Section__c WHERE Name = 'Statement of need'];
        String sectionid = sectionList[0].Id;
        String richtext = 'Adding new block text content to section to reuse. Example text';
        Test.startTest();
        String str = GGW_ApplicationCtrl.addTextBlockToLibrary(sectionid, richtext, 'Test block');
        Test.stopTest();
        // Check if new block was created with default name
        GGW_Content_Block__c block = [SELECT Id, Name, Section__c, Language__c, Description__c FROM GGW_Content_Block__c WHERE Id =:str ];
        System.assertEquals('Test block', block.Name, 'Block name not matching');
        System.assertEquals(str, block.Id, 'No Block ID found');
        System.assertEquals('en_US', block.Language__c, 'No Language__c set for Block');
        System.assertEquals(sectionList[0].Id, block.Section__c, 'Block link to Section missing');
            }
        }
    @isTest
    static void testCreateNewSection(){
        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();

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
    }

    @isTest
    static void testGetApplication(){
        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();

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
        System.assertEquals('In Progress', appWrapper.status, 'Default grant status did not match expected - In Progress');
        // Check selected Items created as content blocks wraper to number of sections
        System.assertEquals(sections.size(),appWrapper.selectedContentBlock.size(), 'The copy of created blocks from template did not match expected number');
            }
        }
    @isTest
    static void testSaveSelectedSectionText(){
        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();
    
        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('MyTest Grant Sections', sections);
        List<GGW_Selected_Item__c> selItemList = GGW_SectionSelector.querySelectedItemsByGrant(app.Id);
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
        List<GGW_Selected_Item__c> savedItemList = GGW_SectionSelector.querySelectedItemsByGrant(app.Id);
        System.assertEquals(blocktext, savedItemList[0].Text_Block__c, 'Block text did not match template'); 
            }
        }
    @isTest
    static void testReorderSections(){
        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();

        // Query all suggested sections
        List<GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('Grant App Order', sections);
        List<GGW_Selected_Item__c> selItemList = GGW_SectionSelector.querySelectedItemsByGrant(app.Id);
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
        List<GGW_Selected_Item__c> selOrderedList = GGW_SectionSelector.querySelectedItemsByGrant(app.Id);
        System.assertEquals(last, selOrderedList[0].Id, 'Last seleected section item did not match expected');                                             
        System.assertEquals(first, selOrderedList[selOrderedList.size()-1].Id, 'First seleectd section item did not match selected');
            }
        }
    @isTest
    static void testUpdateSelectedItemText(){
        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();

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
        }

    @isTest
    static void testDeleteSectionItem(){
        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();

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
        }
    @isTest
    static void  testGetSupportedLanguages(){
    
        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();

        Test.startTest();
        List<GGW_Util.PickList> pl = GGW_ApplicationCtrl.getSupportedLanguages();
        Test.stopTest();
        System.assertEquals(pl.size()>0, true, 'Supported langauges found');   
        }
    }
    @isTest
    static void testGetLanguageSelection(){
        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();

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
        String strLngWire = GGW_ApplicationCtrl.getLanguageSelectionForWire(app.Id);
        Test.stopTest();
        System.assertEquals(str, 'en_US', 'Failed to get application language');
        // NO application ID
        System.assertEquals(strNoApp, 'en_US', 'Negative test failed to get language selectino');
        System.assertEquals(strLngWire, 'en_US', 'Failed to get application language in wired method');
            }
        }
    @isTest
    static void testSaveLanguageSelection(){
        // This code runs as the Grant Guide User with GGW Permission Set from the TestSetup makeData() method.
        User u = [SELECT Alias, Email, EmailEncodingKey, LastName, LanguageLocaleKey,
                    LocaleSidKey, ProfileId, TimeZoneSidKey, UserName 
                    FROM User WHERE Email = 'grantuser@labsorg.com' AND Alias='standt' LIMIT 1];
        
        System.runAs(u) {
        
        //Create sample data
        GGW_TestDataFactory.createGrantContentTestData();

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
}
