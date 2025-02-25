/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_PermissionValidator class support the Security checks for Grant Content Kit Users.
 * 
 */
@IsTest
private class GGW_PermissionValidatorTest {
    @IsTest
    private static void testHasFLSAccessInsertGoodField(){
        Boolean canAccessContactName = GGW_PermissionValidator.getInstance()
            .hasFLSAccessForFields('Contact', new List<String>{'FirstName'}, 'Insert');
        System.Assert(canAccessContactName,'Has insert permission on Contact.FirstName field');
    }

    @IsTest
    private static void testHasFLSAccessInsertBadObjectName() {
        Boolean badObjectName = GGW_PermissionValidator.getInstance()
            .hasFLSAccessForFields('TestObject', new List<String>{ 'Test' }, 'insert');
        System.assert(!badObjectName, 'Bad object name, expect false');
    }

    @IsTest
    private static void testHasFLSAccessInsertBadFieldNameStrictModeDisabled() {
        Boolean badFieldName = GGW_PermissionValidator.getInstance()
            .hasFLSAccessForFields(
                'Contact',
                new List<String>{ 'BadFieldName__123' },
                'insert',
                false
            );
        System.assert(badFieldName, 'Returns true when a field does not exist.');
    }

    @IsTest
    private static void testHasFLSAccessInsertBadFieldName() {
        Boolean badFieldName = GGW_PermissionValidator.getInstance()
            .hasFLSAccessForFields(
                'Contact',
                new List<String>{ 'BadFieldName__123' },
                'insert'
            );
        System.assert(!badFieldName, 'Bad field name, expect false');
    }

    @IsTest
    private static void testHasFLSAccessInsertNonCreatableField() {
        Boolean nonCreatableField = GGW_PermissionValidator.getInstance()
            .hasFLSAccessForFields(
                'Contact',
                new List<String>{ 'LastModifiedById' },
                'insert'
            );
        System.assert(!nonCreatableField, 'Can not modify system field, expect false');
    }

    @IsTest
    private static void testHasFLSAccessUpsertBadFieldName() {
        Boolean nonExistentField = GGW_PermissionValidator.getInstance()
            .hasFLSAccessForFields(
                'Contact',
                new List<String>{ 'BadObjectName__123' },
                'upsert'
            );
        System.assert(!nonExistentField, 'Bad field name, expect false');
    }

    @IsTest
    private static void testHasFLSAccessUpsertNonReparentable() {
        Boolean nonUpdateableField = GGW_PermissionValidator.getInstance()
            .hasFLSAccessForFields(
                Schema.SObjectType.GGW_Grant_Application__c.getName(),
                new List<String>{
                    Schema.SObjectType.GGW_Grant_Application__c.fields.LastModifiedById.getName()
                },
                'upsert'
            );
        System.assert(!nonUpdateableField, 'Non updateable system field, expect false');
    }

    @IsTest
    private static void testHasFLSAccessUpsertGoodField() {
        Boolean editableField = GGW_PermissionValidator.getInstance()
            .hasFLSAccessForFields('Contact', new List<String>{ 'FirstName' }, 'upsert');
        System.assert(editableField, 'Editable field, expect true');
    }

    @IsTest
    private static void testHasFLSAccessReadGoodField() {
        Boolean readableField = GGW_PermissionValidator.getInstance()
            .hasFLSAccessForFields('Contact', new List<String>{ 'FirstName' }, 'read');
        System.assert(readableField, 'Readable field, expect true');
    }

    @IsTest
    private static void testHasFLSAccessNoFLSField() {
        Boolean noFLSField;
        System.runAs(GGW_TestDataFactory.getTestUser()) {
            // test user has no custom object permissions
            noFLSField = GGW_PermissionValidator.getInstance()
                .hasFLSAccessForFields(
                    'Contact',
                    new List<String>{ 'DoNotCall' },
                    'read'
                );
        }
        System.assert(!noFLSField, 'Custom field name, expect false');
    }

    @IsTest
    private static void testHasObjectAccessWithStandardObjectsAsAdmin() {
        Boolean canCreateContact = GGW_PermissionValidator.getInstance()
            .hasObjectAccess(
                Contact.SObjectType,
                GGW_PermissionValidator.CRUDAccessType.CREATEABLE
            );
        System.assert(canCreateContact, 'Has Create perms on Contact, expect true');

        Boolean canReadContact = GGW_PermissionValidator.getInstance()
            .hasObjectAccess(
                Contact.SObjectType,
                GGW_PermissionValidator.CRUDAccessType.READABLE
            );
        System.assert(canReadContact, 'Has Read perms on Contact, expect true');

        Boolean canUpdateContact = GGW_PermissionValidator.getInstance()
            .hasObjectAccess(
                Contact.SObjectType,
                GGW_PermissionValidator.CRUDAccessType.UPDATEABLE
            );
        System.assert(canUpdateContact, 'Has Update perms on Contact, expect true');

        Boolean canDeleteContact = GGW_PermissionValidator.getInstance()
            .hasObjectAccess(
                Contact.SObjectType,
                GGW_PermissionValidator.CRUDAccessType.DELETEABLE
            );
        System.assert(canDeleteContact, 'Has Delete perms on Contact, expect true');
    }

    @IsTest
    private static void testHasObjectAccessWithCustomObjectsAsReadOnlyUser() {
        System.runAs(GGW_TestDataFactory.getTestUser()) {
            Boolean canCreateGrantApplication = GGW_PermissionValidator.getInstance()
                .hasObjectAccess(
                     GGW_Grant_Application__c.SObjectType,
                    GGW_PermissionValidator.CRUDAccessType.CREATEABLE
                );
            System.assert(
                !canCreateGrantApplication,
                'Has no Create perms on GrantApplication, expect false'
            );

            Boolean canReadGrantApplication = GGW_PermissionValidator.getInstance()
                .hasObjectAccess(
                     GGW_Grant_Application__c.SObjectType,
                    GGW_PermissionValidator.CRUDAccessType.READABLE
                );
            System.assert(!canReadGrantApplication, 'Has no Read perms on GrantApplication, expect false');

            Boolean canUpdateGrantApplication = GGW_PermissionValidator.getInstance()
                .hasObjectAccess(
                     GGW_Grant_Application__c.SObjectType,
                    GGW_PermissionValidator.CRUDAccessType.UPDATEABLE
                );
            System.assert(
                !canUpdateGrantApplication,
                'Has no Update perms on GrantApplication, expect false'
            );

            Boolean canDeleteGrantApplication = GGW_PermissionValidator.getInstance()
                .hasObjectAccess(
                     GGW_Grant_Application__c.SObjectType,
                    GGW_PermissionValidator.CRUDAccessType.DELETEABLE
                );
            System.assert(
                !canDeleteGrantApplication,
                'Has no Delete perms on GrantApplication, expect false'
            );
        }
    }

    @IsTest
    private static void testHasObjectAccessWithNullSObjectType() {
        Boolean nullSObjectType = GGW_PermissionValidator.getInstance()
            .hasObjectAccess(null, GGW_PermissionValidator.CRUDAccessType.READABLE);
        System.assert(!nullSObjectType, 'Null SObjectType, expect false');
    }

    @IsTest
    private static void testHasObjectAccessWithNullCRUDAccessType() {
        Boolean nullCRUDAccessType = GGW_PermissionValidator.getInstance()
            .hasObjectAccess(Contact.SObjectType, null);
        System.assert(!nullCRUDAccessType, 'Null CRUDAccessType, expect false');
    }
}
