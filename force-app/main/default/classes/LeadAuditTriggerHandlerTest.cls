@isTest
public with sharing class LeadAuditTriggerHandlerTest {
    @testSetup
    static void setupUsers() {
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Long uniqueSuffix = System.currentTimeMillis();
        User stdUser = new User(
            Username = 'stduser_' + uniqueSuffix + '@example.com',
            LastName = 'StdUser',
            Email = 'stduser_' + uniqueSuffix + '@example.com',
            Alias = 'stdusr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = stdProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        User adminUser = new User(
            Username = 'adminuser_' + uniqueSuffix + '@example.com',
            LastName = 'AdminUser',
            Email = 'adminuser_' + uniqueSuffix + '@example.com',
            Alias = 'admusr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = adminProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert new List<User>{stdUser, adminUser};
    }

    /**
     * Test: Lead insert and update scenarios for audit creation
     */
    @isTest
    static void testLeadInsertAndUpdate() {
        // Get test users
        List<User> users = [SELECT Id FROM User WHERE Alias IN ('stdusr', 'admusr')];
        System.assertEquals(2, users.size(), 'Should have 2 test users');
        User stdUser = users[0];
        User adminUser = users[1];

        Test.startTest();
        // Insert Lead in valid status (should create Audit)
        Lead lead1 = new Lead(LastName='Lead type1', Company='Empresa', Status='Working - Contacted', OwnerId=stdUser.Id);
        insert lead1;

        // Insert Lead in invalid status (should NOT create Audit)
        Lead lead2 = new Lead(LastName='Lead type2', Company='Empresa', Status='Qualified', OwnerId=adminUser.Id);
        insert lead2;

        // Update lead1 to another valid status (should create Audit)
        lead1.Status = 'Closed - Not Converted';
        update lead1;

        // Update lead2 to valid status (should create Audit if config active)
        lead2.Status = 'Working - Contacted';
        update lead2;
        Test.stopTest();

        // Query audits
        List<Audit__c> audits = [SELECT Id, Parent_Type__c, Audity_Type__c, Comments__c, Expected_Audit_Date__c FROM Audit__c WHERE Parent_Type__c = 'Lead' ORDER BY CreatedDate DESC];
        System.assert(audits.size() > 0, 'Audits should be created for valid status changes');

        // Best practice: check audit parent references and types
        for (Audit__c audit : audits) {
            System.assertEquals('Lead', audit.Parent_Type__c, 'Audit should reference Lead');
            System.assertNotEquals(null, audit.Expected_Audit_Date__c, 'Audit should have expected date');
        }
    }
}