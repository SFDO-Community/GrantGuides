/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_ApplicationCtrl controller class support GGW.
 * 
 */
public with sharing class GGW_ApplicationCtrl {
    public static String ggGtSteObj = GGW_Grant_State__c.sobjecttype.getDescribe().getName();
    public static String ggGtStLanField = GGW_Grant_State__c.Language__c.getDescribe().getName();
    // -- START LWC CONtroller Methods
    // Return Grant Aplication Wrapper object
    @AuraEnabled
    public static GGW_GrantApplicationWrapper getApplication(String recordId){
        String tempId = validateAppId(recordId);
        List<GGW_Selected_Item__c> appItems = GGW_SectionSelector.querySelectedItemsByGrant(tempId);
        GGW_Grant_Application__c grant = GGW_ApplicationSelector.queryGrantApp(tempId);
        // Save current app state
        GGW_Util.saveGrantState(tempId);
        GGW_GrantApplicationWrapper app = createGrantWrapper(grant, appItems);
        return app;
    }
    @AuraEnabled (cacheable=true)
    public static List<GGW_Grant_Application__c> getApplicationList(){
        return GGW_ApplicationSelector.getGrantApplications();
    }
    // Delete logo file from grant
    @AuraEnabled
    public static String deleteLogo(String recordId){
    
        GGW_Grant_Application__c app = new GGW_Grant_Application__c();
        app.Id = recordId;
        app.DistributionPublicUrl__c = null; // Logo public URL
        app.Logo_Download_Url__c = null; // Logo display URL
        app.Include_Logo__c = false;

        if(Schema.SObjectType.GGW_Grant_Application__c.isUpdateable()){
            update as User app;
        }
       

        // Find and delete content file and related records
        deleteImageLogo(recordId);
        return 'Logo image deleted';
    }
    // Include or exclude logo image into grant application
    @AuraEnabled
    public static String includeLogo(String recordId, Boolean state){
       
        GGW_Grant_Application__c app = new GGW_Grant_Application__c();
        app.Id = recordId;
        app.Include_Logo__c = state;

        // Check object CRUD

        if(Schema.SObjectType.GGW_Grant_Application__c.isUpdateable()){
            update as User app;
        }
       
        return 'Application logo updated';
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
        ContentVersion file = GGW_ContentSelector.getContentFile(cvid);
        // Creating ContentDistribution record 
        ContentDistribution cdr = insertContentDistribution(file);
        if(cdr.Id == null){
            return null; // could not insert ContentDistribution no CRUD
        }
        // After Distribution record need to get DistributionPublicUrl, ContentDownloadUrl 
        // and update Grant record to use these for display
        ContentDistribution cdURL = GGW_ContentSelector.getContentDistributionById(cdr.Id);
        System.debug('## ContentDownloadUrl:'+cdURL.ContentDownloadUrl);
        System.debug('## DistributionPublicUrl: '+cdURL.DistributionPublicUrl);
        // Update Grant with new logo
        updateGrantAppLogoURL(grantId, cdURL);

        return cdURL.ContentDownloadUrl;
    }
    /**
     * Update text block selection, wire block to item and copy block text data for display and edits
     * 
     */
    @AuraEnabled
    public static void saveSelectedSectionText(String itemid, String blockid){
    
        GGW_Content_Block__c cBlock = GGW_ContentBlockSelector.queryContentBlockById(blockid);

        GGW_Selected_Item__c item = new GGW_Selected_Item__c();
        item.Id = itemid;
        item.Selected_Block__c = blockid;
        item.Text_Block__c = cBlock.Description__c; // Copy rich text from block to item for edits

        if(Schema.SObjectType.GGW_Grant_Application__c.isUpdateable()){
            update as User item;
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

        GGW_Section__c maxOrder = GGW_SectionSelector.findMaxOrderSection();

        GGW_Section__c s = new GGW_Section__c();
        s.Name = name;
        s.Recommended__c = true;
        s.Suggested__c = true;
        s.Language__c = GGW_Util.getGrantLanguage();
        s.Sort_Order__c = getSectionSortOrder(maxOrder);
        

        if(Schema.sObjectType.GGW_Section__c.isCreateable()){
            insert as User s;
        }

    return new GGW_SectionWrapper(s);
    }
    // Edit rich text inside item method called from Section component when edit rich text
    @AuraEnabled
    public static void updateSelectedItemText(String itemid, String richtext){

        GGW_Selected_Item__c item = new GGW_Selected_Item__c();
        item.Id = itemid;
        item.Text_Block__c = richtext; // Update rich text from block to item on edit button click
        if(Schema.sObjectType.GGW_Selected_Item__c.isUpdateable()){
            update as User item;
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
        if((Schema.sObjectType.GGW_Selected_Item__c.isUpdateable() || 
            Schema.sObjectType.GGW_Selected_Item__c.isCreateable() )){
                upsert as User updateOrderList; // Some records here exist some may be new added sections
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<GGW_ContentBlockWrapper> getContentBlocks(String sectionId){
        List<GGW_ContentBlockWrapper> cbwResultList = new List<GGW_ContentBlockWrapper>();
        List<GGW_Content_Block__c> cbList = GGW_ContentBlockSelector.queryContentBlocksBySection(sectionId);
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
            insert as User cb;
        }
        return cb.Id+'';
    }
    // Return all Suggested section for shorter list
    @AuraEnabled //(cacheable=true)
    public static List<GGW_SectionWrapper> getSections(){
        List<GGW_SectionWrapper> swList = new List<GGW_SectionWrapper>();
        String lang = GGW_Util.getGrantLanguage();
        Set<String> setOfSectionsWithBlock = getBlocksForSection();
        List<GGW_Section__c> sectionList = GGW_SectionSelector.querySectionsByLanguage(lang);
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
            List<GGW_Section__c> sectionList = GGW_SectionSelector.querySectionsByName(searchKey);
                
            for(GGW_Section__c s : sectionList){
                GGW_SectionWrapper sw = new GGW_SectionWrapper(s);
                swList.add(sw);
            }
        }
        return swList;
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
    // app ID not used to init new grant pass it for copatible api
    // This method query user selected language from state record
    @AuraEnabled 
    public static String getLanguageSelection(String appId){
        return GGW_Util.getGrantLanguage();
    }
    @AuraEnabled (cacheable=true)
    public static String getLanguageSelectionForWire(String appId){
        return getApplicationLanguage(appId);
    }

    @AuraEnabled (cacheable=true)
    public static List<GGW_Util.PickList> getSupportedLanguages(){
        return GGW_Util.getSelectOptionFromPicklist(ggGtSteObj, ggGtStLanField, false); 
    }

    // --------------------------------
    // -- END LWC Controller Methods --
    // --------------------------------
    private static GGW_GrantApplicationWrapper createGrantWrapper(GGW_Grant_Application__c grant, List<GGW_Selected_Item__c> appItems){
        GGW_GrantApplicationWrapper app = new GGW_GrantApplicationWrapper();
        app.recordid = grant.Id;
        app.logostate = grant.Include_Logo__c;
        app.logodisplayurl = getValidLogoURL(grant);
        app.status = grant.Status__c;
        app.textname = grant.Name;
        app.name = getValidApplicationNameLookupURL(appItems); // Link to standard record
        app.unselectSectionList = getLeftoverSections(appItems);
        app.selectedContentBlock = createContentBlockWrapperList(appItems);
        return app;
    }
    private static String getValidApplicationNameLookupURL(List<GGW_Selected_Item__c> appItems){
        if(!appItems.isEmpty()){
            return appItems[0].Application_Name__c;
        }
        return null;
    }
    private static void deleteImageLogo(String recordId){
        /*
        ContentDocumentLink cdl = [SELECT Id, LinkedEntityId, ContentDocumentId, IsDeleted, Visibility, ShareType 
                                    FROM ContentDocumentLink 
                                    WHERE LinkedEntityId =: recordId WITH SECURITY_ENFORCED LIMIT 1];
        
        ContentDistribution cntdistr = [SELECT Id, Name, ContentVersionId, ContentDocumentId, RelatedRecordId, ContentDownloadUrl 
                                            FROM ContentDistribution 
                                            WHERE ContentDocumentId =: cdl.ContentDocumentId WITH SECURITY_ENFORCED LIMIT 1];
        */
        ContentDocumentLink cdl = GGW_ContentSelector.getDocLinkByLinkedEntity(recordId);
        ContentDistribution cntdistr = GGW_ContentSelector.getContentDistributionByDocId(cdl.ContentDocumentId);
        ContentDocument cd = new ContentDocument();
        cd.Id = cdl.ContentDocumentId;
        if(Schema.sObjectType.ContentDistribution.isDeletable()){
            delete cntdistr;
        }
        if(Schema.sObjectType.ContentDocument.isDeletable()){
            delete cd;
        }
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
    private static void updateGrantAppLogoURL(String grantId, ContentDistribution cdURL){

        // Update Grant with new logo
        if(cdURL.ContentDownloadUrl != null){
            GGW_Grant_Application__c app = new GGW_Grant_Application__c();
            app.Id = grantId;
            app.DistributionPublicUrl__c = cdURL.DistributionPublicUrl; // Logo public URL
            app.Logo_Download_Url__c = cdURL.ContentDownloadUrl; // Logo display URL
            // Check object CRUD
            if(Schema.sObjectType.GGW_Grant_Application__c.isUpdateable()){
                update as User app;
            }
        }
    }
    private static ContentDistribution insertContentDistribution(ContentVersion file){

        ContentDistribution cdr = new ContentDistribution(
                                            Name = file.Title,
                                            ContentVersionId = file.Id,
                                            PreferencesAllowViewInBrowser = true );
        // Check object CRUD
        if(Schema.sObjectType.ContentDistribution.isCreateable()){
            insert as User cdr;
        }
        return cdr;
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
    // Check if giveb string ID is Id of Section record
    private static Boolean isSectionId(String s){
        Boolean res = false;
        Id sectionId = s; 
        String objName = sectionId.getsobjecttype()+'';
        System.debug('### Obj: '+objName+' ID: '+s);
        if(objName.equals('%%%NAMESPACED_ORG%%%GGW_Section__c')){ // Create new selected item junction for section
            res = true;
        }
        return res;
    }
    // Delete Grant selected section items that are not on the list to reorder function
    private static void cleanSelectedSections(List<String> sectionList, String appId){
        List<GGW_Selected_Item__c> appItems = GGW_SectionSelector.querySelectedItemsByGrant(appId);
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

    // Always return valid string, default block name if given name is null
    private static String getValidBlockName(String name){
        String blockName = '[CHANGE] New Text Block';
        if(GGW_Util.isValidString(name)){
            blockName = name;
        }
        return blockName;
    }
    // Return all available section in library
    private static List<GGW_SectionWrapper> getLeftoverSections(List<GGW_Selected_Item__c> appItems){
        List<GGW_SectionWrapper> swList = new List<GGW_SectionWrapper>();
        Set<String> setExcludeSections = getExcludeSectionSet(appItems);
        Set<String> setOfSectionsWithBlock = getBlocksForSection();
        List<GGW_Section__c> sectionList = GGW_SectionSelector.querySections();

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
    private static Set<String> getBlocksForSection(){
        Set<String> s1 = new Set<String>();
        List<GGW_Content_Block__c> cbList = GGW_ContentBlockSelector.queryContentBlocks();
        for(GGW_Content_Block__c c : cbList){
            s1.add(c.Id);
        }   

        return s1;
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

    private static GGW_Grant_Application__c insertGrantRecord(String name){

        GGW_Grant_Application__c gapp = new GGW_Grant_Application__c();
        if (GGW_Util.isValidString(name)){
            gapp.Name = name;
            gapp.Status__c = 'In Progress';
            gapp.Language__c = GGW_Util.getGrantLanguage();
        
            insert as User gapp;            

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
        
            insert as User selectedItems;

    }
    // Get application language from existing Grant record
    private static String getApplicationLanguage(String appId){
        String lang = 'en_US'; // Default to US English code
        GGW_Grant_Application__c app = GGW_ApplicationSelector.queryGrantApp(appId);
        if(GGW_Util.isValidString(app.Language__c)){
            lang = app.Language__c;
        }
        return lang;
    }

    ///--- BASIC SELECTOR METHODS

    // Return list of TopicAssignments for ContentBlocks
    private static List<TopicAssignment> queryTopicAssignments(){
        List<TopicAssignment> lst = [SELECT EntityType, EntityId, Topic.Name 
                                    FROM TopicAssignment 
                                    WHERE EntityType = 'GGW_Content_Block' WITH SECURITY_ENFORCED];
        return lst;
    }


}
