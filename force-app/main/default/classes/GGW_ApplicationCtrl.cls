/**
 * GGW_ApplicationCtrl controller class support GGW.
 * 
 * 
 * @author Igor Androsov
 * @version 1.0
 */
public without sharing class GGW_ApplicationCtrl {
    public GGW_ApplicationCtrl() {

    }

    // ------------------------------------    
    // shared classes
    public class GGW_SectionWrapper {
        @AuraEnabled public String recordid;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean selected; 
        @AuraEnabled public Boolean hasblocks;
    }
    public class GGW_SectionWrapperList {
        @AuraEnabled public List<GGW_SectionWrapper> sectionlist;
    }
    public class GGW_ContentBlockWrapper {
        @AuraEnabled public String recordid;
        @AuraEnabled public String sectionid;
        @AuraEnabled public String sectionname;
        @AuraEnabled public String title; // Display title map to Name
        @AuraEnabled public String displaytext; // map to Description__c
        @AuraEnabled public Integer wordcount; // Derived from Rich tect field in APEX count words
        @AuraEnabled public String displaybadge; // Tage to display on the badge (Winner etc)
        @AuraEnabled public String displaydate; // Created date
        @AuraEnabled public Integer totalblocks;
        @AuraEnabled public Boolean isselected;

        //. Construct and map Block fields
        public GGW_ContentBlockWrapper(GGW_Content_Block__c block, Integer cnt){
            this.isselected = false;
            this.recordid = block.Id;
            this.sectionid  = block.Section__c;
            this.sectionname = block.Section__r.Name;
            this.title = block.Name;
            this.displaytext = block.Description__c; // Rich text
            // Count words in rich text with APEX methods
            integer words = block.Description__c.normalizeSpace().stripHtmlTags().replaceAll('\\S','').length() ;
            this.wordcount = words;
            this.displaydate = block.CreatedDate.format('YYYY-MM-DD'); // Format this to short
            // TODO
            this.displaybadge = 'Winner'; // TODO find how to fill this what make a tag?
            this.totalblocks = cnt;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<GGW_SectionWrapper> getSections(){
        List<GGW_SectionWrapper> swList = new List<GGW_SectionWrapper>();
        Set<String> setOfSectionsWithBlock = getBlocksForSection();
        List<GGW_Section__c> sectionList = [SELECT Id, Name, CreatedDate, Recommended__c, Suggested__c, Sort_Order__c 
                                                FROM GGW_Section__c WHERE Suggested__c = true ORDER BY Sort_Order__c];
        for(GGW_Section__c s : sectionList){
            GGW_SectionWrapper sw = new GGW_SectionWrapper();
            sw.recordid = s.Id;
            sw.label = s.Name;
            sw.selected = s.Recommended__c;
            sw.hasblocks = setOfSectionsWithBlock.contains(s.Id);
            swList.add(sw);
        }
        return swList;
    }
    private static Set<String> getBlocksForSection(){
        Set<String> s1 = new Set<String>();
        List<GGW_Content_Block__c> cbList = [SELECT Id, Name, Description__c, Short_Description__c, 
                                                Section__c, Section__r.Name, CreatedDate 
                                                FROM GGW_Content_Block__c ORDER BY Section__c];
        for(GGW_Content_Block__c c : cbList){
            s1.add(c.Id);
        }   

        return s1;
    }
    private static Map<String, List<GGW_Content_Block__c>> getSectionBlocks(){
        Map<String, List<GGW_Content_Block__c>> blockMap = new Map<String, List<GGW_Content_Block__c>>();
        List<GGW_Content_Block__c> cbList = [SELECT Id, Name, Description__c, Short_Description__c, 
                                                Section__c, Section__r.Name, CreatedDate 
                                                FROM GGW_Content_Block__c ORDER BY Section__c];
        for(GGW_Content_Block__c c : cbList){
        
        }
        return blockMap;
    }

    @AuraEnabled(cacheable=true)
    public static List<GGW_ContentBlockWrapper> getContentBlocks(String sectionId){
        List<GGW_ContentBlockWrapper> cbwResultList = new List<GGW_ContentBlockWrapper>();
        List<GGW_Content_Block__c> cbList = [SELECT Id, Name, Description__c, Short_Description__c, 
                                                Section__c, Section__r.Name, CreatedDate 
                                                FROM GGW_Content_Block__c WHERE Section__c =: sectionId];
        for(GGW_Content_Block__c c : cbList){
            GGW_ContentBlockWrapper cbw = new GGW_ContentBlockWrapper(c, cbList.size());
            cbwResultList.add(cbw);
        }
        return cbwResultList;
    }
}
