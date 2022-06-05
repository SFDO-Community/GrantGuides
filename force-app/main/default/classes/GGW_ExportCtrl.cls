/**
 * GGW_ExportCtrl controller class for VFP Export and render.
 * Standard controller extension used for Standard record page action
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
        if(this.app != null && this.app.Id != null){
            this.recordId = this.app.Id;
        }else{
            this.recordId = ApexPages.currentPage().getParameters().get('c__recordId');
        }
        // Get from saved state
        if(this.recordId == null || this.recordId.length() == 0){
            GGW_Grant_State__c st = GGW_Util.getGrantState();
            if(st != null && st.Grant_Application__c != null){
                this.recordId = st.Grant_Application__c;
            }
        }
        // set from URL Parm record ID
        //this.recordId = this.app.Id; //'a001D0000058zp2QAA';//ApexPages.currentPage().getParameters().get('id');
        system.debug('### PDF VIew ID:'+this.recordId);
        this.items = GGW_Util.getSelectedItems(this.recordId);
        if(items != null && items.size()>0){
            this.appName = items[0].Application_Name__c;
        }else{
            this.appName = 'This view requires a Grant record, missing.';
        }

    }
}
