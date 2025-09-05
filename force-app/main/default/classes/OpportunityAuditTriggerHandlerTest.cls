@isTest
public with sharing class OpportunityAuditTriggerHandlerTest {
    /**
     * Test setup: Create two accounts with different owners
     */
    @testSetup
    static void setupAccounts() {
        // Create two users to act as account owners
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Long uniqueSuffix = System.currentTimeMillis();
        User u1 = new User(
            Username = 'testuser1_' + uniqueSuffix + '@example.com',
            LastName = 'User1',
            Email = 'testuser1_' + uniqueSuffix + '@example.com',
            Alias = 'tuser1',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        User u2 = new User(
            Username = 'testuser2_' + uniqueSuffix + '@example.com',
            LastName = 'User2',
            Email = 'testuser2_' + uniqueSuffix + '@example.com',
            Alias = 'tuser2',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        User u3 = new User(
            Username = 'adminuser3_' + uniqueSuffix + '@example.com',
            LastName = 'Admin3',
            Email = 'adminuser3_' + uniqueSuffix + '@example.com',
            Alias = 'admin3',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = adminProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert new List<User>{u1, u2, u3};

        // Create two accounts with different owners
        Account acc1 = new Account(Name = 'Account One', OwnerId = u1.Id);
        Account acc2 = new Account(Name = 'Account Two', OwnerId = u2.Id);
        insert new List<Account>{acc1, acc2};

        // Create contacts for each account
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'ContactA1', LastName = 'One', AccountId = acc1.Id, Email = 'contacta1@example.com'),
            new Contact(FirstName = 'ContactA2', LastName = 'One', AccountId = acc1.Id, Email = 'contacta2@example.com'),
            new Contact(FirstName = 'ContactB1', LastName = 'Two', AccountId = acc2.Id, Email = 'contactb1@example.com'),
            new Contact(FirstName = 'ContactB2', LastName = 'Two', AccountId = acc2.Id, Email = 'contactb2@example.com')
        };
        insert contacts;

        // Create Account 3 with standard owner, contacts owned by admin
        Account acc3 = new Account(Name = 'Account Three', OwnerId = u1.Id);
        insert acc3;
        List<Contact> adminContacts = new List<Contact>{
            new Contact(FirstName = 'AdminContact1', LastName = 'Three', AccountId = acc3.Id, Email = 'admincontact1@example.com', OwnerId = u3.Id),
            new Contact(FirstName = 'AdminContact2', LastName = 'Three', AccountId = acc3.Id, Email = 'admincontact2@example.com', OwnerId = u3.Id)
        };
        insert adminContacts;
    }

    /**
     * Test: Insert Opportunities in valid and invalid stages, then update stages
     */
    /**
     * Test: Opportunity insert and update scenarios for audit creation
     */
    @isTest
    static void testOpportunityInsertAndUpdate() {
        // Get test accounts and users
        List<Account> accounts = [SELECT Id, Name, OwnerId FROM Account WHERE Name IN ('Account One', 'Account Two', 'Account Three')];
        System.assertEquals(3, accounts.size(), 'Should have 3 test accounts');
        Map<String, Account> accMap = new Map<String, Account>();
        for (Account a : accounts) {
            accMap.put(a.Name, a);
        }

        Test.startTest();
        // Insert Opportunity in valid stage (should create Audit)
        Opportunity opp1 = new Opportunity(
            Name = 'Opp type1 ' + accMap.get('Account One').Name,
            StageName = 'Qualification',
            CloseDate = Date.today(),
            AccountId = accMap.get('Account One').Id,
            OwnerId = accMap.get('Account One').OwnerId
        );
        insert opp1;

        // Insert Opportunity in invalid stage (should NOT create Audit)
        Opportunity opp2 = new Opportunity(
            Name = 'Opp type2 ' + accMap.get('Account Two').Name,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = accMap.get('Account Two').Id,
            OwnerId = accMap.get('Account Two').OwnerId
        );
        insert opp2;

        // Update opp1 to another valid stage (should create Audit)
        opp1.StageName = 'Closed Won';
        update opp1;

        // Update opp2 to valid stage (should create Audit)
        opp2.StageName = 'Closed Lost';
        update opp2;

        // Update opp1 to same stage (should NOT create Audit)
        opp1.StageName = 'Closed Won';
        update opp1;
        Test.stopTest();

        // Query audits
        List<Audit__c> audits = [SELECT Id, Parent_Type__c, Audity_Type__c, Comments__c, Expected_Audit_Date__c FROM Audit__c WHERE Parent_Type__c = 'Opportunity' ORDER BY CreatedDate DESC];
        System.assert(audits.size() > 0, 'Audits should be created for valid stage changes');

        // Best practice: check audit parent references and expected dates
        for (Audit__c audit : audits) {
            System.assertEquals('Opportunity', audit.Parent_Type__c, 'Audit should reference Opportunity');
            System.assertNotEquals(null, audit.Expected_Audit_Date__c, 'Audit should have expected date');
        }
    }
}