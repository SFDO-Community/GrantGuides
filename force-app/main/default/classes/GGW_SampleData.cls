/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_SampleData class to seed sample section and related content blocks data for Grants.
 * Used by LWC component to read sample data from file stored in static resource with Grants package
 */
public with sharing class GGW_SampleData {
    public class GGW_Attributes {
        public String type;
        public String referenceId;
    }

    public class GGW_Section {
        public GGW_Attributes attributes;
        public String Name;
        public Boolean Recommended;
        public String Section_Details;
        public Integer Sort_Order {get; set;}
        public Boolean Suggested {get; set;}
    }

    public class GGW_Content_Block {
        public GGW_Attributes attributes;
        public String Name;
        public String Description;
        public String Section;
        public String Short_Description;
    }
    /**
     List<GGW_Section__c> lst = [SELECT Id, Name from GGW_Section__c];
     delete lst;
     */
    @AuraEnabled
    public static String insertSampleSections(){
        system.debug('## enter insertSampleSections');
        String str = 'Sample section data';
        if(!isSectionExists()){ 
            List<GGW_Section> lst = readSectionData();
            List<GGW_Section__c> sectionNewList = new List<GGW_Section__c>();
            for(GGW_Section s : lst){
                GGW_Section__c gs = new GGW_Section__c();
                gs.Name = s.Name;
                gs.Recommended__c = s.Recommended;
                gs.Section_Details__c = s.Section_Details;
                gs.Sort_Order__c = s.Sort_Order;
                gs.Suggested__c = s.Suggested;
                sectionNewList.add(gs);
            }
            if(sectionNewList.size() > 0){
                insert sectionNewList;
                str += ' import complete. ';
                system.debug('## enter insertSampleSections: data inserted OK');
                // Sections inserted in same order as initial list
                // Map new section IDs to references in JSON file to link with related text blocks
                Map<String,String> sectionMap = new Map<String,String>();
                Integer count = 0;
                for (GGW_Section__c s : sectionNewList){
                    GGW_Section dataJsonSection = lst[count];
                    system.debug('## Ref Section: '+dataJsonSection.attributes.referenceId + ' sfid: '+s.Id);
                    sectionMap.put(dataJsonSection.attributes.referenceId, s.Id);
                    count++;
                }
                str += insertContentBlocks(sectionMap);
            }
        }
        return str;
    }
    // Insert all related Content Blocks as records for parent sections
    /**
     List<GGW_Content_Block__c> blst = [SELECT Id, Name from GGW_Content_Block__c];
     delete blst;
     */
    public static String insertContentBlocks(Map<String,String> sectionMap){
        String str = 'Sample block data';
        // Read sample block data from JSON resource file
        List<GGW_Content_Block> lstBlock = readContentBlockData();
        List<GGW_Content_Block__c> blockNewList = new List<GGW_Content_Block__c>();
        for(GGW_Content_Block b : lstBlock){
            GGW_Content_Block__c newBlock = new GGW_Content_Block__c();
            newBlock.Name = b.Name;
            newBlock.Description__c = b.Description;
            newBlock.Short_Description__c = b.Short_Description;
            
            if(sectionMap.containsKey(b.Section)){
                String v1 = (String)sectionMap.get(b.Section);
                newBlock.Section__c = v1;
                system.debug('## Link Section: '+v1+' with Block ref: '+b.Section);
            }
            blockNewList.add(newBlock);
        }
        if(blockNewList.size() > 0){
           insert blockNewList;
           str += ' import complete.';
           system.debug('## enter insertContentBlocks: data inserted OK');
        }
        return str;
    }
    // GGW_SampleData.insertSections();
    public static List<GGW_Section> readSectionData(){
        StaticResource sr= [SELECT Id, body FROM StaticResource WHERE Name = 'GGWSectionData'];
        String contents = sr.body.toString();
        List<GGW_Section> sectionData = (List<GGW_Section>)System.JSON.deserialize(contents, List<GGW_Section>.class);

        //System.debug('###'+sectionData);
        return sectionData;
    }
    public static List<GGW_Content_Block> readContentBlockData(){
        StaticResource sr= [SELECT Id, body FROM StaticResource WHERE Name = 'GGWContentBlockData'];
        String contents = sr.body.toString();
        List<GGW_Content_Block> contentBlockData = (List<GGW_Content_Block>)System.JSON.deserialize(contents, List<GGW_Content_Block>.class);
        return contentBlockData;
    }
    // Check if any section records exists
    @AuraEnabled
    public static Boolean isSectionExists(){
        List<GGW_Section__c> lst = [SELECT Id, Name FROM GGW_Section__c LIMIT 10];
        Boolean state = false;
        if (lst != null && lst.size()>0){
            state = true;
        }
        return state;
    }
}
