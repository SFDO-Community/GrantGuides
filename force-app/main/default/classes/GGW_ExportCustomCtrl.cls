/**
 * GGW_ExportCustomCtrl controller class for VFP Export and render.
 * Custom controller for Tab
 * 
 * @author Igor Androsov
 * @version 1.0
 */
public without sharing class GGW_ExportCustomCtrl {
    public String recordId {get; set;}
    public String appName {get;set;}
    public List<GGW_Selected_Item__c> items {get; set;}
   
    public GGW_ExportCustomCtrl() {
        this.recordId = ApexPages.currentPage().getParameters().get('c__recordId');

        system.debug('### PDF View from URL c__recordId: '+this.recordId);
        this.items = GGW_Util.getSelectedItems(this.recordId);
        if(this.items != null && this.items.size()>0){
            this.appName = this.items[0].Application_Name__c;
        }else{
            this.appName = 'This view requires a Grant record, missing.';
        }
       
    }
}
