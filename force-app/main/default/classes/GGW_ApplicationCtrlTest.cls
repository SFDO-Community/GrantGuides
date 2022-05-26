/**
 * GGW_ApplicationCtrlTest unt test for controller class support GGW.
 * 
 * 
 * @author Igor Androsov
 * @version 1.0
 */
@IsTest
public class GGW_ApplicationCtrlTest {
    
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
    static void testNewGrant(){
        // Query all suggested sections
        List<GGW_ApplicationCtrl.GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_ApplicationCtrl.GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }

        Test.startTest();
        
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('MyTest Grant', sections);

        Test.stopTest();
        
        System.assertEquals('MyTest Grant', app.Name); 
        System.assertEquals('Progress', app.Status__c); 
        // Check if all section are created for app
        List<GGW_Selected_Item__c> selectedItems = [SELECT Id, Name, Grant_Application__c, GGW_Section__c, Sort_Order__c 
                                                    FROM GGW_Selected_Item__c WHERE Grant_Application__c =:app.Id];
        System.assertEquals(sections.size(), selectedItems.size()); 
    }
    @isTest
    static void testFindSections(){
        String searchKey = 'Test';
        Test.startTest();
        List<GGW_ApplicationCtrl.GGW_SectionWrapper> sw = GGW_ApplicationCtrl.findSections(searchKey);
        Test.stopTest();
        System.assertNotEquals(0, sw.size());
        System.assertEquals('Test search', sw[0].label);
        System.assertEquals(false, sw[0].selected);

        // Negative test asserts not found section by key
        searchKey = 'fail';
        List<GGW_ApplicationCtrl.GGW_SectionWrapper> swfail = GGW_ApplicationCtrl.findSections(searchKey);
        System.assertEquals(0, swfail.size());
    }
}
