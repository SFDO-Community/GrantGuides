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
    public class GGW_GrantApplicationWrapper {
        @AuraEnabled public String recordid;
        @AuraEnabled public String name;
        @AuraEnabled public String status;

        @AuraEnabled public List<GGW_ContentBlockWrapper> selectedContentBlock; // Include Section and Text block
    }
    public class GGW_SectionWrapper {
        @AuraEnabled public String recordid;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean selected; 
        @AuraEnabled public Boolean hasblocks;

        // BASIC Constrauctior Create Section object mapp from GGW_Section__c
        public GGW_SectionWrapper(GGW_Section__c s){
            this.recordid = s.Id;
            this.label = s.Name;
            this.selected = s.Recommended__c;
            this.hasblocks = true; // default assuming blocks exist
        }

        // Create Section object mapp from GGW_Section__c and find Blocks
        public GGW_SectionWrapper(GGW_Section__c s, Set<String> setOfSectionsWithBlock){
            this.recordid = s.Id;
            this.label = s.Name;
            this.selected = s.Recommended__c;
            this.hasblocks = setOfSectionsWithBlock.contains(s.Id);
        }
    }
    //public class GGW_SectionWrapperList {
    //    @AuraEnabled public List<GGW_SectionWrapper> sectionlist;
    //}

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
        @AuraEnabled public String selecteditemid; // Id of selecetd item on application
        @AuraEnabled public Integer sortorder;
        public GGW_ContentBlockWrapper(){

        }
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
            this.displaydate = block.CreatedDate.format('YYYY-MM'); // Format this to short
            // TODO
            this.displaybadge = 'Winner'; // TODO find how to fill this what make a tag?
            this.totalblocks = cnt;
        }
    }

    // Return Grant Aplication Wrapper object
    @AuraEnabled
    public static GGW_GrantApplicationWrapper getApplication(String recordId){
        List<GGW_Selected_Item__c> appItems = [SELECT Id, Application_Name__c, Grant_Application__c, GGW_Section__c, 
                                Section_Name__c,Selected_Block__c, Sort_Order__c, Grant_Application__r.Status__c,
                                Selected_Block__r.Description__c, Text_Block__c  
                                FROM GGW_Selected_Item__c 
                                WHERE Grant_Application__c =: recordId ORDER BY Sort_Order__c];
        GGW_GrantApplicationWrapper app = new GGW_GrantApplicationWrapper();
        if(appItems != null && appItems.size()>0){
            app.recordid = recordId;
            app.name = appItems[0].Application_Name__c;
            app.status = appItems[0].Grant_Application__r.Status__c;

            List<GGW_ContentBlockWrapper> contentList = new List<GGW_ContentBlockWrapper>();
            for(GGW_Selected_Item__c item : appItems){
                GGW_ContentBlockWrapper cbw = new GGW_ContentBlockWrapper();
                cbw.selecteditemid = item.Id;
                cbw.recordid = item.Selected_Block__c;
                cbw.sectionid = item.GGW_Section__c;
                cbw.sectionname = item.Section_Name__c;
                cbw.totalblocks = 1; // Alway only 1 per section in Grant
                cbw.displaytext = item.Text_Block__c; //Selected_Block__r.Description__c;
                cbw.isselected = true;
                cbw.sortorder = item.Sort_Order__c.intValue(); // APEX SOQL return NUmber decimal need convert to Int Illegal assignment from Decimal to Integer
                contentList.add(cbw);
            }
            app.selectedContentBlock = contentList;
        }
        return app;
    }
    /**
     * Update text block selection, wire block to item and copy block text data for display and edits
     * 
     */
    @AuraEnabled
    public static void saveSelectedSectionText(String itemid, String blockid){
        GGW_Content_Block__c cBlock = [SELECT Id, Name, Description__c FROM GGW_Content_Block__c WHERE Id =: blockid LIMIT 1];
        // Construct selected Item to update
        GGW_Selected_Item__c item = new GGW_Selected_Item__c();
        item.Id = itemid;
        item.Selected_Block__c = blockid;
        item.Text_Block__c = cBlock.Description__c; // Copy rich text from block to item for edits
        update item;
    }
    /**
     * Create new section on Grant landing home page component
     * with defaulted values of Sugested and recommended.
     * Assumption user needs new section on Grant that do not exist yet, this is
     * general section NOT related yet to Grant record.
     */
    @AuraEnabled
    public static GGW_SectionWrapper createNewSection(String name){
        GGW_Section__c maxOrder = [SELECT Sort_Order__c FROM GGW_Section__c WHERE Suggested__c = true  ORDER BY Sort_Order__c desc LIMIT 1];
        GGW_Section__c s = new GGW_Section__c();
        s.Name = name;
        s.Recommended__c = true;
        s.Suggested__c = true;
        s.Sort_Order__c = maxOrder.Sort_Order__c + 1;
        insert s;
        return new GGW_SectionWrapper(s);
    }
    // Edit rich text inside item method called from Section component when edit rich text
    @AuraEnabled
    public static void updateSelectedItemText(String itemid, String richtext){
        GGW_Selected_Item__c item = new GGW_Selected_Item__c();
        item.Id = itemid;
        item.Text_Block__c = richtext; // Update rich text from block to item on edit button click
        update item;
    }
    @AuraEnabled
    public static void reorderSections(List<String> sectionList){
        List<GGW_Selected_Item__c> updateOrderList = new List<GGW_Selected_Item__c>();
        Integer cnt = 1;
        for (String s : sectionList){
            GGW_Selected_Item__c ggws = new GGW_Selected_Item__c();
            ggws.Id = s;
            ggws.Sort_Order__c = cnt;
            updateOrderList.add(ggws);
            cnt++;
        }
        if(updateOrderList.size()>0){
            update updateOrderList;
        }
    }
    /**
     * Method to create a new ContentBlock add to section as part a library to later reuse
     * on other Grant applications.
     * 
     */
    @AuraEnabled
    public static String addTextBlockToLibrary(String sectionid, String richtext){
        GGW_Content_Block__c cb = new GGW_Content_Block__c();
        cb.name = '[CHANGE] New Text Block'; // strange error Layout  Field:Name must not be Readonly
        cb.Section__c = sectionid;
        cb.Description__c = richtext;
        insert cb;

        return cb.Id+'';
    }

    // Return all Suggested section for shorter list
    @AuraEnabled(cacheable=true)
    public static List<GGW_SectionWrapper> getSections(){
        List<GGW_SectionWrapper> swList = new List<GGW_SectionWrapper>();
        Set<String> setOfSectionsWithBlock = getBlocksForSection();
        List<GGW_Section__c> sectionList = [SELECT Id, Name, CreatedDate, Recommended__c, Suggested__c, Sort_Order__c 
                                                FROM GGW_Section__c WHERE Suggested__c = true ORDER BY Sort_Order__c];
        for(GGW_Section__c s : sectionList){
            GGW_SectionWrapper sw = new GGW_SectionWrapper(s,setOfSectionsWithBlock);
            swList.add(sw);
        }
        return swList;
    }
    // Search any section by text key
    @AuraEnabled(cacheable=true)
    public static  List<GGW_SectionWrapper> findSections(String searchKey) {
        List<GGW_SectionWrapper> swList = new List<GGW_SectionWrapper>();
        if(searchKey != null && searchKey.length() > 0){
            String key = '%' + searchKey + '%';
            List<GGW_Section__c> sectionList = [SELECT Id, Name, CreatedDate, Recommended__c, Suggested__c, Sort_Order__c 
                FROM GGW_Section__c WHERE Name LIKE :key AND Suggested__c = false ORDER BY Sort_Order__c LIMIT 20];
                
                for(GGW_Section__c s : sectionList){
                    GGW_SectionWrapper sw = new GGW_SectionWrapper(s);
                    swList.add(sw);
                }
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

    /**
     * Create a new Grant Application record and also add all selected list of sections
     * as selected items.
     * Application starting point, user can add text blocks to build out thsi record
     * 
     */
    @AuraEnabled
    public static GGW_Grant_Application__c newGrant(String name, List<String> sections){
        System.debug('## NEW GRANT Parm: '+name+' SECTIONS:'+sections);
        GGW_Grant_Application__c gapp = new GGW_Grant_Application__c();
        if (name != null && name.length() > 0){
            gapp.Name = name;
            gapp.Status__c = 'Progress';
            insert gapp;            
            // Add selected sections itterate over selected section IDs param
            List<GGW_Selected_Item__c> selectedItems = new List<GGW_Selected_Item__c>();
            Integer itemSortOrder = 1;
            for(String sect : sections){
                GGW_Selected_Item__c item = new GGW_Selected_Item__c();
                item.GGW_Section__c = sect;
                item.Grant_Application__c = gapp.Id;
                item.Sort_Order__c = itemSortOrder;
                selectedItems.add(item);
                itemSortOrder++; // increment sort order set as default
            }
            if(selectedItems.size()>0){
                insert selectedItems;
            }
            System.debug('## NEW GRANT: '+name+' ID:'+gapp.Id+' SECTIONS:'+sections);
        }
        return gapp;
    }
}
