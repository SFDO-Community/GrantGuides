public with sharing class GGW_SampleData {

    public class GGW_Section {
        public String Name;
        public Boolean Recommended;
        public String Section_Details;
        public Integer Sort_Order {get; set;}
        public Boolean Suggested {get; set;}
    }
    /**
     List<GGW_Section__c> lst = [SELECT Id, Name from GGW_Section__c];
     delete lst;
     */
    @AuraEnabled
    public static String insertSampleSections(){
        system.debug('## enter insertSampleSections');
        String str = 'Sample data';
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
                str += ' import complete.';
                system.debug('## enter insertSampleSections: data inserted OK');
            }
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
    // Check if any section records exists
    @AuraEnabled(cacheable=true)
    public static Boolean isSectionExists(){
        List<GGW_Section__c> lst = [SELECT Id, Name FROM GGW_Section__c LIMIT 10];
        Boolean state = false;
        if (lst != null && lst.size()>0){
            state = true;
        }
        return state;
    }
}
