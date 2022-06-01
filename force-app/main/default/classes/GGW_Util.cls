
/**
 * GGW_Util class for support utility methods on Grant application.
 * Used by standard and Custom controller
 * 
 * @author Igor Androsov
 * @version 1.0
 */
public class GGW_Util {
    // Pass Grant application ID record
    // return a list of selected Items (sections+blocks)
    public static List<GGW_Selected_Item__c> getSelectedItems(String appId) {
        system.debug('### Grant ID:'+appId);
        List<GGW_Selected_Item__c> items = new List<GGW_Selected_Item__c>();
        items = [SELECT Id, Name, Application_Name__c, Grant_Application__c, Selected_Block__c, 
                        GGW_Section__c, Section_Name__c, Text_Block__c,  Sort_Order__c
                        FROM GGW_Selected_Item__c WHERE Grant_Application__c =: appId ORDER BY Sort_Order__c];
        return items;
    }
}
