/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_ContentSelector Salesforce Content data selector class support GGW.
 * 
 */
public with sharing class GGW_ContentSelector {
    public static ContentDocumentLink getDocLinkByLinkedEntity(String recordId) {
        return [SELECT Id, LinkedEntityId, ContentDocumentId, IsDeleted, Visibility, ShareType 
                    FROM ContentDocumentLink 
                    WHERE LinkedEntityId =: recordId WITH SECURITY_ENFORCED LIMIT 1];
    }
    public static ContentDistribution getContentDistributionByDocId(String docId){
        return [SELECT Id, Name, ContentVersionId, ContentDocumentId, RelatedRecordId, ContentDownloadUrl 
                FROM ContentDistribution 
                WHERE ContentDocumentId =: docId WITH SECURITY_ENFORCED LIMIT 1];
    }

    public static ContentDistribution getContentDistributionById(Id cdid){
        ContentDistribution cdr = [SELECT Id, Name, ContentVersionId, 
                                            ContentDownloadUrl, DistributionPublicUrl 
                                    FROM ContentDistribution 
                                    WHERE Id =: cdid WITH SECURITY_ENFORCED LIMIT 1];
        return cdr;
    }
    // Query ContentVersion by id
    public static ContentVersion getContentFile(String cvid){
        ContentVersion file = [SELECT Id, Title 
                                FROM ContentVersion 
                                WHERE Id =: cvid WITH SECURITY_ENFORCED];
        return file;
    }

}