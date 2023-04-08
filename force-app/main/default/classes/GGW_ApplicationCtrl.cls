/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_ApplicationCtrl controller class support GGW.
 * 
 */
public without sharing class GGW_ApplicationCtrl {

    // Return Grant Aplication Wrapper object
    @AuraEnabled
    public static GGW_GrantApplicationWrapper getApplication(String recordId){
        String tempId = validateAppId(recordId);

        List<GGW_Selected_Item__c> appItems = querySelectedItemsByGrant(tempId);
        GGW_Grant_Application__c grant = GGW_Util.queryGrantApp(tempId);
        // Save current app state
        GGW_Util.saveGrantState(tempId);

        GGW_GrantApplicationWrapper app = new GGW_GrantApplicationWrapper();
        if(!appItems.isEmpty()){
            app.recordid = grant.Id;
            app.logodisplayurl = getValidLogoURL(grant);
            app.name = appItems[0].Application_Name__c;
            app.status = appItems[0].Grant_Application__r.Status__c;
            app.unselectSectionList = getLeftoverSections(appItems);
            app.selectedContentBlock = createContentBlockWrapperList(appItems);
        }
        return app;
    }

    private static String getValidLogoURL(GGW_Grant_Application__c grant){
        String logourl = null;
        if(grant != null && grant.Logo_Download_Url__c != null){
            logourl = grant.Logo_Download_Url__c;
        }
        return logourl;
    }
    // Map content block wrapper object fromrecords
    private static List<GGW_ContentBlockWrapper> createContentBlockWrapperList(List<GGW_Selected_Item__c> appItems){
        List<GGW_ContentBlockWrapper> contentList = new List<GGW_ContentBlockWrapper>();
        for(GGW_Selected_Item__c item : appItems){
            GGW_ContentBlockWrapper cbw = mapContentBlockWrapper(item);
            contentList.add(cbw);
        }
        return contentList;
    }
    private static GGW_ContentBlockWrapper mapContentBlockWrapper(GGW_Selected_Item__c item){
        GGW_ContentBlockWrapper cbw = new GGW_ContentBlockWrapper();
        cbw.selecteditemid = item.Id;
        cbw.recordid = item.Selected_Block__c;
        cbw.sectionid = item.GGW_Section__c;
        cbw.sectionname = item.Section_Name__c;
        cbw.totalblocks = 1; // Always only 1 per section in Grant
        cbw.displaytext = item.Text_Block__c; //Selected_Block__r.Description__c;
        cbw.isselected = true;
        cbw.sortorder = item.Sort_Order__c.intValue(); // APEX SOQL return NUmber decimal need convert to Int Illegal assignment from Decimal to Integer
        return cbw;
    }
    private static String validateAppId(String recordId){
        String tempId = recordId;
        if(recordId == null){
            tempId = getAppIdFromSavedState();
        }
        return tempId;
    }
    private static String getAppIdFromSavedState(){
        GGW_Grant_State__c st = GGW_Util.getGrantState();
        if (st != null && st.Grant_Application__c != null ){
            return st.Grant_Application__c;
        }
        return null;
    }
    /**
     * Creating ContentDistribution record 
     * parameter: contentVersionId
     * response return URL image
     * 
     * SELECT Id, LinkedEntityId, ContentDocumentId, ShareType, Visibility FROM ContentDocumentLink WHERE LinkedEntityId = 'a010R00000FYjbAQAT'
        SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE ContentDocumentId = '0690R000001qBEgQAM'
     */
    @AuraEnabled
    public static String createContentDistribution(String grantId, String cvid){
        ContentVersion file = getContentFile(cvid);
        // Creating ContentDistribution record 
        ContentDistribution cdr = insertContentDistribution(file);
        if(cdr.Id == null){
            return null; // could not insert ContentDistribution no CRUD
        }
        // After Distribution record need to get DistributionPublicUrl, ContentDownloadUrl 
        // and update Grant record to use these for display
        ContentDistribution cdURL = getContentDistributionById(cdr.Id);
        System.debug('## ContentDownloadUrl:'+cdURL.ContentDownloadUrl);
        System.debug('## DistributionPublicUrl: '+cdURL.DistributionPublicUrl);
        // Update Grant with new logo
        updateGrantAppLogoURL(grantId, cdURL);

        return cdURL.ContentDownloadUrl;
    }
    private static void updateGrantAppLogoURL(String grantId, ContentDistribution cdURL){
        // Update Grant with new logo
        if(cdURL.ContentDownloadUrl != null){
            GGW_Grant_Application__c app = new GGW_Grant_Application__c();
            app.Id = grantId;
            app.DistributionPublicUrl__c = cdURL.DistributionPublicUrl; // Logo public URL
            app.Logo_Download_Url__c = cdURL.ContentDownloadUrl; // Logo display URL
            // Check object CRUD
            if(Schema.sObjectType.GGW_Grant_Application__c.isUpdateable()){
                update app;
            }
        }
    }
    private static ContentDistribution getContentDistributionById(Id cdid){
        ContentDistribution cdr = [SELECT Id, Name, ContentVersionId, 
                                            ContentDownloadUrl, DistributionPublicUrl 
                                    FROM ContentDistribution 
                                    WHERE Id =: cdid WITH SECURITY_ENFORCED LIMIT 1];
        return cdr;
    }
    // Query ContentVersion by id
    private static ContentVersion getContentFile(String cvid){
        ContentVersion file = [SELECT Id, Title 
                                FROM ContentVersion 
                                WHERE Id =: cvid WITH SECURITY_ENFORCED];
        return file;
    }
    private static ContentDistribution insertContentDistribution(ContentVersion file){
        ContentDistribution cdr = new ContentDistribution(
                                            Name = file.Title,
                                            ContentVersionId = file.Id,
                                            PreferencesAllowViewInBrowser = true );
        // Check object CRUD
        if(Schema.sObjectType.ContentDistribution.isCreateable()){
            insert cdr;
        }
        return cdr;
    }
    /**
     * Update text block selection, wire block to item and copy block text data for display and edits
     * 
     */
    @AuraEnabled
    public static void saveSelectedSectionText(String itemid, String blockid){
        GGW_Content_Block__c cBlock = queryContentBlockById(blockid);
        // Construct selected Item to update
        GGW_Selected_Item__c item = new GGW_Selected_Item__c();
        item.Id = itemid;
        item.Selected_Block__c = blockid;
        item.Text_Block__c = cBlock.Description__c; // Copy rich text from block to item for edits
        if(Schema.sObjectType.GGW_Selected_Item__c.isUpdateable()){
            update item;
        }
    }
    /**
     * Create new section on Grant landing home page component
     * with defaulted values of Sugested and recommended.
     * Assumption user needs new section on Grant that do not exist yet, this is
     * general section NOT related yet to Grant record.
     */
    @AuraEnabled
    public static GGW_SectionWrapper createNewSection(String name){
        GGW_Section__c maxOrder = findMaxOrderSection();
        GGW_Section__c s = new GGW_Section__c();
        s.Name = name;
        s.Recommended__c = true;
        s.Suggested__c = true;
        s.Sort_Order__c = getSectionSortOrder(maxOrder);
        if(Schema.sObjectType.GGW_Section__c.isCreateable()){
            insert s;
        }
        return new GGW_SectionWrapper(s);
    }
    // Return section with max order to add next section
    private static GGW_Section__c findMaxOrderSection(){
        List<GGW_Section__c> maxOrderList = [SELECT Sort_Order__c 
                                                FROM GGW_Section__c 
                                                WHERE Suggested__c = true WITH SECURITY_ENFORCED ORDER BY Sort_Order__c desc];
        GGW_Section__c maxOrder = null;
        // Handle situation when Sort order is null - TODO MAY be good to require it
        for(GGW_Section__c section : maxOrderList ){
            if(section.Sort_Order__c != null && section.Sort_Order__c > 0){
                maxOrder = section; // assigned MAX order object first found END LOOP here
                break; // EXIT Loop
            }
        }
        return maxOrder;
    }
    // Fix for issue #67 WHne pkg installed omn fresh org NO sample section data defult sort to 1
    // Use decimal  insted on Integer a s fieds number ais decimal
    private static Decimal getSectionSortOrder(GGW_Section__c maxOrder){
        Decimal order = 1; // Initial 1st value section
        if(maxOrder != null && maxOrder.Sort_Order__c != null){
            order = maxOrder.Sort_Order__c + 1;
        }
        return order;
    }
    // Edit rich text inside item method called from Section component when edit rich text
    @AuraEnabled
    public static void updateSelectedItemText(String itemid, String richtext){
        GGW_Selected_Item__c item = new GGW_Selected_Item__c();
        item.Id = itemid;
        item.Text_Block__c = richtext; // Update rich text from block to item on edit button click
        if(Schema.sObjectType.GGW_Selected_Item__c.isUpdateable()){
            update item;
        }
    }
    // Delete Section as selected item junction for grant - remoes a section
    @AuraEnabled
    public static void deleteSection(String itemId){
        GGW_Selected_Item__c item = new GGW_Selected_Item__c();
        item.Id = itemId;
        if(Schema.sObjectType.GGW_Selected_Item__c.isDeletable()){
            delete item;
        }
    }

    @AuraEnabled
    public static void reorderSections(List<String> sectionList, String appId){
        List<GGW_Selected_Item__c> updateOrderList = new List<GGW_Selected_Item__c>();
        // Clean up items for reorder, delete items that are NOT on this list
        cleanSelectedSections(sectionList, appId);
        Integer cnt = 1;
        for (String s : sectionList){

            Id sectionId = s; 
            GGW_Selected_Item__c ggws = new GGW_Selected_Item__c();
            System.debug('### reorderSections APP ID: '+appId);
            if(isSectionId(s)){ // Create new selected item junction for section
                ggws.GGW_Section__c = sectionId;
                System.debug('## Add new section: '+s);
            }else{ // Update selected existing item junction
                ggws.Id = s;
                System.debug('## Update existing section: '+s);
            }

            ggws.Grant_Application__c = appId;
            ggws.Sort_Order__c = cnt;
            updateOrderList.add(ggws);
            cnt++;
        }
        if(Schema.sObjectType.GGW_Selected_Item__c.isUpdateable() || 
            Schema.sObjectType.GGW_Selected_Item__c.isCreateable()){
                upsert updateOrderList; // Some records here exist some may be new added sections
        }
    }
    // Check if giveb string ID is Id of Section record
    private static Boolean isSectionId(String s){
        Boolean res = false;
        Id sectionId = s; 
        String objName = sectionId.getsobjecttype()+'';
        System.debug('### Obj: '+objName+' ID: '+s);
        if(objName.equals('GGW_Section__c')){ // Create new selected item junction for section
            res = true;
        }
        return res;
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
        if(!removeItems.isEmpty()){
            if(Schema.sObjectType.GGW_Selected_Item__c.isDeletable()){
                delete removeItems;
            }
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
                                Selected_Block__r.Description__c, Text_Block__c, Language__c 
                                FROM GGW_Selected_Item__c 
                                WHERE Grant_Application__c =: appId WITH SECURITY_ENFORCED ORDER BY Sort_Order__c];
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
        cb.name = getValidBlockName(name); // strange error Layout  Field:Name must not be Readonly
        cb.Section__c = sectionid;
        cb.Description__c = richtext;
        if(Schema.sObjectType.GGW_Content_Block__c.isCreateable()){
            insert cb;
        }
        return cb.Id+'';
    }
    // Always return valid string, default block name if given name is null
    private static String getValidBlockName(String name){
        String blockName = '[CHANGE] New Text Block';
        if(GGW_Util.isValidString(name)){
            blockName = name;
        }
        return blockName;
    }
    // Return all Suggested section for shorter list
    @AuraEnabled //(cacheable=true)
    public static List<GGW_SectionWrapper> getSections(){
        List<GGW_SectionWrapper> swList = new List<GGW_SectionWrapper>();
        String lang = GGW_Util.getGrantLanguage();
        Set<String> setOfSectionsWithBlock = getBlocksForSection();
        List<GGW_Section__c> sectionList = querySectionsByLanguage(lang);
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
        List<GGW_Section__c> sectionList = querySections();

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
            List<GGW_Section__c> sectionList = querySectionsByName(searchKey);
                
            for(GGW_Section__c s : sectionList){
                GGW_SectionWrapper sw = new GGW_SectionWrapper(s);
                swList.add(sw);
            }
        }
        return swList;
    }
    private static Set<String> getBlocksForSection(){
        Set<String> s1 = new Set<String>();
        List<GGW_Content_Block__c> cbList = queryContentBlocks();
        for(GGW_Content_Block__c c : cbList){
            s1.add(c.Id);
        }   

        return s1;
    }
    /** DEPERCATED
     * Not used method, leaving commented code for reference
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
        List<GGW_Content_Block__c> cbList = queryContentBlocksBySection(sectionId);
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
        Map<String,List<String>> mapTags = new Map<String,List<String>>();
        List<TopicAssignment> lst = queryTopicAssignments();                                        
        for (TopicAssignment t : lst){
            List<String> badgeList = new List<String>();
            if(mapTags.containsKey(t.EntityId)){
                badgeList = mapTags.get(t.EntityId);
            }
            badgeList.add(t.Topic.Name);
            mapTags.put(t.EntityId, badgeList); 
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
        GGW_Grant_Application__c gapp = insertGrantRecord(name);
        insertSelectedItemsForGrant(gapp.Id, sections);
        System.debug('## NEW GRANT: '+name+' ID:'+gapp.Id+' SECTIONS:'+sections);
        return gapp;
    }
    private static GGW_Grant_Application__c insertGrantRecord(String name){
        GGW_Grant_Application__c gapp = new GGW_Grant_Application__c();
        if (GGW_Util.isValidString(name)){
            gapp.Name = name;
            gapp.Status__c = 'Progress';
            gapp.Language__c = GGW_Util.getGrantLanguage();
            if(Schema.sObjectType.GGW_Grant_Application__c.isCreateable()){
                insert gapp;            
            }
        }
        return gapp;
    }
    private static void insertSelectedItemsForGrant(Id appId, List<String> sections){
        // Add selected sections itterate over selected section IDs param
        List<GGW_Selected_Item__c> selectedItems = new List<GGW_Selected_Item__c>();
        Integer itemSortOrder = 1;
        for(String sect : sections){
            GGW_Selected_Item__c item = new GGW_Selected_Item__c();
            item.GGW_Section__c = sect;
            item.Grant_Application__c = appId;
            item.Sort_Order__c = itemSortOrder;
            selectedItems.add(item);
            itemSortOrder++; // increment sort order set as default
        }
        if(Schema.sObjectType.GGW_Selected_Item__c.isCreateable()){
            insert selectedItems;
        }
    }
    /**
     Save user selected langauge for Grant in a Grant/User state
     State record is used to store small setting selection data to drive 
     logic. In this case Language filtering for content.
     This method is called from LWC language selector 
     */
    @AuraEnabled
    public static String saveLanguageSelection(String lang, String appId){
        // If lang = null then User langauge SFDC setting will be used by default
        return GGW_Util.saveGrantLanguage(lang, appId);
    }

    @AuraEnabled
    public static String getLanguageSelection(String appId){
        String lang = 'en_US'; // Default to US English code
        if(GGW_Util.isValidString(appId)){
            lang = getApplicationLanguage(appId);
        }else{
            lang = GGW_Util.getGrantLanguage();
        }
        return lang;
    }
    @AuraEnabled (cacheable=true)
    public static List<GGW_Util.PickList> getSupportedLanguages(){
        return GGW_Util.getSelectOptionFromPicklist('GGW_Grant_State__c', 'Language__c', false); 
    }
    // Get application language from existing Grant record
    private static String getApplicationLanguage(String appId){
        String lang = 'en_US'; // Default to US English code
        GGW_Grant_Application__c app = [SELECT Id, Name, Language__c FROM GGW_Grant_Application__c WHERE Id =: appId WITH SECURITY_ENFORCED LIMIT 1];
        if(GGW_Util.isValidString(app.Language__c)){
            lang = app.Language__c;
        }
        return lang;
    }

    ///--- BASIC SELECTOR METHODS
    private static List<GGW_Section__c> querySectionsByLanguage(String lang){
        List<GGW_Section__c> sectionList = [SELECT Id, Name, CreatedDate, Recommended__c, Suggested__c, 
                                                Sort_Order__c, Language__c 
                                            FROM GGW_Section__c 
                                            WHERE Suggested__c = true AND Language__c =: lang 
                                            WITH SECURITY_ENFORCED ORDER BY Sort_Order__c];
        return sectionList;
    }
    private static List<GGW_Section__c> querySections(){
        List<GGW_Section__c> sectionList = [SELECT Id, Name, CreatedDate, Recommended__c, Suggested__c, 
                                                    Sort_Order__c, Language__c 
                                            FROM GGW_Section__c WITH SECURITY_ENFORCED ORDER BY Sort_Order__c];
        return sectionList;
    }
    private static List<GGW_Section__c> querySectionsByName(String searchKey){
        String key = '%' + searchKey + '%';
        List<GGW_Section__c> sectionList = [SELECT Id, Name, CreatedDate, Recommended__c, Suggested__c, 
                                                    Sort_Order__c, Language__c 
                                            FROM GGW_Section__c 
                                            WHERE Name LIKE :key AND Suggested__c = false 
                                            WITH SECURITY_ENFORCED ORDER BY Sort_Order__c LIMIT 20];
        return sectionList;
    }

    // Return list of TopicAssignments for ContentBlocks
    private static List<TopicAssignment> queryTopicAssignments(){
        List<TopicAssignment> lst = [SELECT EntityType, EntityId, Topic.Name 
                                    FROM TopicAssignment 
                                    WHERE EntityType = 'GGW_Content_Block' WITH SECURITY_ENFORCED];
        return lst;
    }

    // BLOCK Query
    private static GGW_Content_Block__c queryContentBlockById(String blockid){
        GGW_Content_Block__c cBlock = [SELECT Id, Name, Description__c 
                                        FROM GGW_Content_Block__c 
                                        WHERE Id =: blockid WITH SECURITY_ENFORCED LIMIT 1];
        return cBlock;
    }
    private static List<GGW_Content_Block__c> queryContentBlocksBySection(String sectionId){
        List<GGW_Content_Block__c> cbList = [SELECT Id, Name, Description__c, Short_Description__c, 
                                                Section__c, Section__r.Name, CreatedDate, 
                                                Language__c  
                                                FROM GGW_Content_Block__c 
                                                WHERE Section__c =: sectionId WITH SECURITY_ENFORCED];
        return cbList;
    }
    private static List<GGW_Content_Block__c> queryContentBlocks(){
        List<GGW_Content_Block__c> cbList = [SELECT Id, Name, Description__c, Short_Description__c, 
                                                Section__c, Section__r.Name, CreatedDate, 
                                                Language__c 
                                            FROM GGW_Content_Block__c WITH SECURITY_ENFORCED ORDER BY Section__c];
        return cbList;
    }

}
