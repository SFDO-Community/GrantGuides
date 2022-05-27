/**
 * GGW_ExportCtrl controller class for VFP Export and render.
 * 
 * 
 * @author Igor Androsov
 * @version 1.0
 */
public without sharing class GGW_ExportCtrl {
    public String recordId {get; set;}
    public String appName {get;set;}
    public List<GGW_Selected_Item__c> items {get; set;}
    private final GGW_Grant_Application__c app;

    public GGW_ExportCtrl(ApexPages.StandardController stdController) {
        this.app = (GGW_Grant_Application__c)stdController.getRecord();
        // set from URL Parm record ID
        this.recordId = this.app.Id; //'a001D0000058zp2QAA';//ApexPages.currentPage().getParameters().get('id');
        this.items = [SELECT Id, Name, Application_Name__c, Grant_Application__c, Selected_Block__c, 
                        GGW_Section__c, Section_Name__c, Text_Block__c,  Sort_Order__c
                        FROM GGW_Selected_Item__c WHERE Grant_Application__c =: this.recordId ORDER BY Sort_Order__c];
        if(items != null && items.size()>0){
            this.appName = items[0].Application_Name__c;
        }
    }
}
