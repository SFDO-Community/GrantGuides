/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 * 
 * GGW_SampleDataTest unt test for APEX  
 * class support GGW_SampleData.
 * Used to test sample data import
 */
@IsTest
public class GGW_SampleDataTest {

    @isTest
    static void testInsertSampleSections(){
        
        String str = GGW_SampleData.insertSampleSections();
    }
}
