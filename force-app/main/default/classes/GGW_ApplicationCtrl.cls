/**
 * GGW_ApplicationCtrl controller class support GGW.
 * 
 * 
 * @author Igor Androsov
 * @version 1.0
 */
public without sharing class GGW_ApplicationCtrl {

    // ------------------------------------    
    // shared classes
    public class GGW_GrantApplicationWrapper {
        @AuraEnabled public String recordid;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public List<GGW_SectionWrapper> unselectSectionList; // Used to add new sections to Grant
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
        @AuraEnabled public String displaybadge; // DEPRECATE Tag to display on the badge (Winner etc)
        @AuraEnabled public List<String> badgeList; // Tags to display on the badge (Winner etc) from Topics
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
            // Temporary value for tag default
            //this.displaybadge = ''; // TODO find how to fill this what make a tag?
            this.totalblocks = cnt;
            this.badgeList = new List<String>(); // init empty list fill in later
        }
    }

    // Return Grant Aplication Wrapper object
    @AuraEnabled
    public static GGW_GrantApplicationWrapper getApplication(String recordId){
        String tempId = recordId;
        if(recordId == null){
            GGW_Grant_State__c st = GGW_Util.getGrantState();
            if (st != null && st.Grant_Application__c != null ){
                tempId = st.Grant_Application__c;
            }
        }

        List<GGW_Selected_Item__c> appItems = querySelectedItemsByGrant(tempId);

        // Save state
        GGW_Util.saveGrantState(tempId);
        //List<GGW_SectionWrapper> unselectedSections = getLeftoverSections(appItems);
        GGW_GrantApplicationWrapper app = new GGW_GrantApplicationWrapper();
        if(appItems != null && appItems.size()>0){
            app.recordid = tempId;
            app.name = appItems[0].Application_Name__c;
            app.status = appItems[0].Grant_Application__r.Status__c;
            app.unselectSectionList = getLeftoverSections(appItems);
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
        List<GGW_Section__c> maxOrderList = [SELECT Sort_Order__c FROM GGW_Section__c WHERE Suggested__c = true  ORDER BY Sort_Order__c desc];
        GGW_Section__c maxOrder = null;
        /// Hnadle situation when Sort order is null - TODO MAY be goosd to require it
        for(GGW_Section__c section : maxOrderList ){
            if(section.Sort_Order__c != null && section.Sort_Order__c > 0){
                maxOrder = section; // assigned MAX order object first found END LOOP here
                break; // EXIST Loop
            }
        }
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
    // Delete Section as selected item junction for grant - remoes a section
    @AuraEnabled
    public static void deleteSection(String itemId){
        GGW_Selected_Item__c item = new GGW_Selected_Item__c();
        item.Id = itemId;
        delete item;
    }

    @AuraEnabled
    public static void reorderSections(List<String> sectionList, String appId){
        List<GGW_Selected_Item__c> updateOrderList = new List<GGW_Selected_Item__c>();
        // Clean up items for reorder, delete items that are NOT on this list
        cleanSelectedSections(sectionList, appId);
        Integer cnt = 1;
        for (String s : sectionList){
            Id sectionId = s; 
            String objName = sectionId.getsobjecttype()+'';
            GGW_Selected_Item__c ggws = new GGW_Selected_Item__c();
            System.debug('### Obj: '+objName+' ID: '+s +' APP ID: '+appId);
            if(objName.equals('GGW_Section__c')){ // Create new selected item junction fro section
                ggws.GGW_Section__c = sectionId;
                ggws.Grant_Application__c = appId;
                ggws.Sort_Order__c = cnt;
                System.debug('## Add new section: '+s);
            }else{ // Update selected existing item junction
                ggws.Id = s;
                ggws.Grant_Application__c = appId;
                ggws.Sort_Order__c = cnt;
                System.debug('## Update existing section: '+s);
            }
            updateOrderList.add(ggws);
            cnt++;
        }
        if(updateOrderList.size()>0){
            upsert updateOrderList; // Some records here exist some may be new added sections
        }
    }
    // Delete Grant selected section items that are not on the list to reorder function
    private static void cleanSelectedSections(List<String> sectionList, String appId){
        List<GGW_Selected_Item__c> appItems = querySelectedItemsByGrant(appId);
        Set<String> sectionSet = new Set<String>(sectionList);
        List<GGW_Selected_Item__c> removeItems = new List<GGW_Selected_Item__c>();
        for(GGW_Selected_Item__c item : appItems){
            if(!sectionSet.contains(String.valueOf(item.Id))){
                removeItems.add(item);
            }
        }
        if(removeItems.size()>0){
            delete removeItems;
        }
    }
    // Convert Selecetd Item to Map - NOT USED AT THIS TIME COMMENT
    /** 
    private Map<String,GGW_Selected_Item__c> getSelectedItemsMap(String appId){
        List<GGW_Selected_Item__c> appItems = querySelectedItemsByGrant(appId);
        Map<String,GGW_Selected_Item__c> mapGrantSelected = new Map<String,GGW_Selected_Item__c>();
        for(GGW_Selected_Item__c item : appItems){
            mapGrantSelected.put(item.Id,item);
        }
        return mapGrantSelected;
    }
    */

    // Utility selector method
    public static List<GGW_Selected_Item__c> querySelectedItemsByGrant(String appId){
        List<GGW_Selected_Item__c> appItems = [SELECT Id, Application_Name__c, Grant_Application__c, GGW_Section__c, 
                                Section_Name__c,Selected_Block__c, Sort_Order__c, Grant_Application__r.Status__c,
                                Selected_Block__r.Description__c, Text_Block__c  
                                FROM GGW_Selected_Item__c 
                                WHERE Grant_Application__c =: appId ORDER BY Sort_Order__c];
        return appItems;
    }

    /**
     * Method to create a new ContentBlock add to section as part a library to later reuse
     * on other Grant applications.
     * 
     */
    @AuraEnabled
    public static String addTextBlockToLibrary(String sectionid, String richtext, String name){
        GGW_Content_Block__c cb = new GGW_Content_Block__c();
        cb.name = '[CHANGE] New Text Block'; // strange error Layout  Field:Name must not be Readonly
        if(name != null){
            cb.name = name; // replace given name
        }
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
    // Return all available section in library
    private static List<GGW_SectionWrapper> getLeftoverSections(List<GGW_Selected_Item__c> appItems){
        List<GGW_SectionWrapper> swList = new List<GGW_SectionWrapper>();
        Set<String> setExcludeSections = getExcludeSectionSet(appItems);
        Set<String> setOfSectionsWithBlock = getBlocksForSection();
        List<GGW_Section__c> sectionList = [SELECT Id, Name, CreatedDate, Recommended__c, Suggested__c, Sort_Order__c 
                                                FROM GGW_Section__c ORDER BY Sort_Order__c];
        for(GGW_Section__c s : sectionList){
            system.debug('## Left Section: '+s.Name+' ID: '+s.Id);
            if(!setExcludeSections.contains(s.Id)){
                system.debug('## Include Section: '+s.Name+' ID: '+s.Id);
                GGW_SectionWrapper sw = new GGW_SectionWrapper(s,setOfSectionsWithBlock);
                swList.add(sw);
            }
        }
        return swList;    
    }
    private static Set<String> getExcludeSectionSet(List<GGW_Selected_Item__c> appItems){
        Set<String> section = new Set<String>();
        for(GGW_Selected_Item__c item : appItems){
            section.add(item.GGW_Section__c);
        }
        return section;
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
    /** DEPERCATED
     * Not used method, leaving commende code for reference
    private static Map<String, List<GGW_Content_Block__c>> getSectionBlocks(){
        Map<String, List<GGW_Content_Block__c>> blockMap = new Map<String, List<GGW_Content_Block__c>>();
        List<GGW_Content_Block__c> cbList = [SELECT Id, Name, Description__c, Short_Description__c, 
                                                Section__c, Section__r.Name, CreatedDate 
                                                FROM GGW_Content_Block__c ORDER BY Section__c];
        for(GGW_Content_Block__c c : cbList){
        
        }
        return blockMap;
    }
    */
    @AuraEnabled(cacheable=true)
    public static List<GGW_ContentBlockWrapper> getContentBlocks(String sectionId){
        List<GGW_ContentBlockWrapper> cbwResultList = new List<GGW_ContentBlockWrapper>();
        List<GGW_Content_Block__c> cbList = [SELECT Id, Name, Description__c, Short_Description__c, 
                                                Section__c, Section__r.Name, CreatedDate 
                                                FROM GGW_Content_Block__c WHERE Section__c =: sectionId];
        // Get map of block tags to display as badges
        Map<String,List<String>> blockTags = getBlockTopics();
        for(GGW_Content_Block__c c : cbList){
            GGW_ContentBlockWrapper cbw = new GGW_ContentBlockWrapper(c, cbList.size());
            if(blockTags.containsKey(c.Id)){
                List<String> badgeList = blockTags.get(c.Id);
                // TODO - HERE we get 1st tag string assign to display
                // Only 1 badge tag shown today, this may need to be multiple Tags per block
                if (badgeList.size()>0){
                    cbw.displaybadge = badgeList[0]; // DEPRECATED: switch to use list
                    cbw.badgeList = badgeList;
                }  
            }
            cbwResultList.add(cbw);
        }
        return cbwResultList;
    }
    // Query Topics for content blocks, display tags/badge for each block
    private static Map<String,List<String>> getBlockTopics(){
        List<TopicAssignment> lst = [SELECT EntityType, EntityId, Topic.Name 
                                        FROM TopicAssignment WHERE EntityType = 'GGW_Content_Block'];
        Map<String,List<String>> mapTags = new Map<String,List<String>>();
        for (TopicAssignment t : lst){
            if(mapTags.containsKey(t.EntityId)){
                List<String> badgeList = mapTags.get(t.EntityId);
                badgeList.add(t.Topic.Name);
                mapTags.put(t.EntityId, badgeList);
            }else{
                List<String> badgeList = new List<String>();
                badgeList.add(t.Topic.Name);
                mapTags.put(t.EntityId, badgeList);
            }
        }
        return mapTags;
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
