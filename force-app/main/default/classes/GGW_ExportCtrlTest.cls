/**
 * GGW_ExportCtrlTest unt test for APEX controller extension 
 * class support GGW_Grant_Application__c record page.
 * Used to render preview of Grant application as PDF
 * 
 * @author Igor Androsov
 * @version 1.0
 */
@IsTest
public class GGW_ExportCtrlTest {
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
    
    }

    @isTest
    static void testExportCtrl(){
        // Unit test for conroller extention
        // Query all suggested sections
        List<GGW_ApplicationCtrl.GGW_SectionWrapper> lst = GGW_ApplicationCtrl.getSections();
        List<String> sections = new List<String>();
        for (GGW_ApplicationCtrl.GGW_SectionWrapper gww : lst){
            if(gww.selected){
                sections.add(gww.recordid);
            }
        }
        // Create new Gran application and set up selected Items
        GGW_Grant_Application__c app = GGW_ApplicationCtrl.newGrant('MyTest Grant', sections);

        Test.startTest();
        ApexPages.StandardController stdGrant = new ApexPages.StandardController(app);
	    GGW_ExportCtrl grantExportController  = new GGW_ExportCtrl(stdGrant);
        Test.stopTest();

        // Check data created in ctrl contructor
        System.assertEquals(app.Id, grantExportController.recordId); 
        System.assertEquals(app.Name, grantExportController.appName);
        // 3 section expected to be added to grand
        System.assertEquals(3, grantExportController.items.size());
    }
}
