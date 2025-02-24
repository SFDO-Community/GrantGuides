/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_PermissionValidator class used to support checking object and field level access while using the Grant Content Kit.
 * 
 */
public with sharing class GGW_PermissionValidator {
    @TestVisible
    private static GGW_PermissionValidator instance;

    public static GGW_PermissionValidator getInstance() {
        if (instance == null) {
            instance = new GGW_PermissionValidator();
        }
        return instance;
    }

    private static final String NAMESPACE = '%%%NAMESPACED_ORG%%%';

    public enum CRUDAccessType {
        CREATEABLE,
        READABLE,
        UPDATEABLE,
        DELETEABLE
    }

    public Boolean hasFLSAccessForFields(
        String objectName,
        List<String> fields,
        String operation
    ) {
        return hasFLSAccessForFields(objectName, fields, operation, true);
    }

    public Boolean hasFLSAccessForFields(
        String objectName,
        List<String> fields,
        String operation,
        Boolean strictMode
    ) {
        try {
            String nameSpacedObjectName = NAMESPACE + objectName;
            Schema.DescribeSobjectResult[] results = Schema.describeSObjects(
                
                new List<String>{ nameSpacedObjectName }
            );
            Map<String, Schema.SObjectField> fieldsMap = results[0].fields.getMap();

            for (String fieldName : fields) {
                //Prepend the Namespace if it exists in the Environment
                String nameSpacedFN = NAMESPACE + fieldname;

                if (strictMode && !fieldsMap.containsKey(nameSpacedFN)) {
                    return false;
                } else if (!strictMode && !fieldsMap.containsKey(nameSpacedFN)) {
                    return true;
                } else if (
                    operation == 'insert' &&
                    !fieldsMap.get(nameSpacedFN).getDescribe().isCreateable()
                ) {
                    return false;
                } else if (
                    operation == 'upsert' &&
                    (!fieldsMap.get(nameSpacedFN).getDescribe().isCreateable() ||
                    !fieldsMap.get(nameSpacedFN).getDescribe().isUpdateable())
                ) {
                    return false;
                } else if (
                    operation == 'read' &&
                    !hasFieldReadAccess(fieldsMap.get(nameSpacedFN).getDescribe())
                ) {
                    return false;
                }
            }
            return true;
        } catch (Exception e) {
            return false;
        }
    }
//FLS Check for Standard Objects without Namespace

    public Boolean hasStandFLSAccessForFields(
        String objectName,
        List<String> fields,
        String operation
    ) {
        return hasStandFLSAccessForFields(objectName, fields, operation, true);
    }

    public Boolean hasStandFLSAccessForFields(
        String objectName,
        List<String> fields,
        String operation,
        Boolean strictMode
    ) {
        try {

            Schema.DescribeSobjectResult[] results = Schema.describeSObjects(
                
                new List<String>{ ObjectName }
            );
            Map<String, Schema.SObjectField> fieldsMap = results[0].fields.getMap();

            for (String fieldName : fields) {

                if (strictMode && !fieldsMap.containsKey(fieldname)) {
                    return false;
                } else if (!strictMode && !fieldsMap.containsKey(fieldname)) {
                    return true;
                } else if (
                    operation == 'insert' &&
                    !fieldsMap.get(fieldname).getDescribe().isCreateable()
                ) {
                    return false;
                } else if (
                    operation == 'upsert' &&
                    (!fieldsMap.get(fieldname).getDescribe().isCreateable() ||
                    !fieldsMap.get(fieldname).getDescribe().isUpdateable())
                ) {
                    return false;
                } else if (
                    operation == 'read' &&
                    !hasFieldReadAccess(fieldsMap.get(fieldname).getDescribe())
                ) {
                    return false;
                }
            }
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public Boolean hasFieldReadAccess(DescribeFieldResult field) {
        return field.isAccessible();
    }

    public Boolean hasObjectAccess(SObjectType sObjectType, CRUDAccessType accessType) {
        if (sObjectType == null) {
            return false;
        }

        switch on accessType {
            when CREATEABLE {
                return sObjectType.getDescribe().isCreateable();
            }
            when READABLE {
                return sObjectType.getDescribe().isAccessible();
            }
            when UPDATEABLE {
                return sObjectType.getDescribe().isUpdateable();
            }
            when DELETEABLE {
                return sObjectType.getDescribe().isDeletable();
            }
            when else {
                return false;
            }
        }
    }
}