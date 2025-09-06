// Test script to verify participant creation for both Opportunity and Lead audits

// Test 1: Create an Opportunity with Account and Contacts
Account testAccount = new Account(Name = 'Test Account for Participants');
insert testAccount;

Contact testContact1 = new Contact(
    FirstName = 'John',
    LastName = 'Doe',
    Email = 'john.doe@test.com',
    AccountId = testAccount.Id
);
Contact testContact2 = new Contact(
    FirstName = 'Jane',
    LastName = 'Smith', 
    Email = 'jane.smith@test.com',
    AccountId = testAccount.Id
);
insert new List<Contact>{testContact1, testContact2};

Opportunity testOpp = new Opportunity(
    Name = 'Test Opportunity for Participants',
    AccountId = testAccount.Id,
    StageName = 'Prospecting',
    CloseDate = Date.today().addDays(30)
);
insert testOpp;

// Test 2: Create a Lead
Lead testLead = new Lead(
    FirstName = 'Lead',
    LastName = 'Test',
    Email = 'lead.test@test.com',
    Company = 'Test Lead Company',
    Status = 'Open - Not Contacted'
);
insert testLead;

// Wait a moment for triggers to fire and check participants
System.debug('=== CHECKING AUDIT PARTICIPANTS ===');

// Query Audits created
List<Audit__c> oppAudits = [SELECT Id, Parent_Type__c, Parent_Opportunity__c 
                            FROM Audit__c 
                            WHERE Parent_Opportunity__c = :testOpp.Id];
System.debug('Opportunity Audits created: ' + oppAudits.size());

List<Audit__c> leadAudits = [SELECT Id, Parent_Type__c, Parent_Lead__c 
                             FROM Audit__c 
                             WHERE Parent_Lead__c = :testLead.Id];
System.debug('Lead Audits created: ' + leadAudits.size());

// Query Participants created for Opportunity Audits
if (!oppAudits.isEmpty()) {
    List<Audit_Participant__c> oppParticipants = [
        SELECT Id, Audit__c, User__c, Contact__c, Role__c, Comments__c
        FROM Audit_Participant__c 
        WHERE Audit__c IN :oppAudits
    ];
    System.debug('Opportunity Audit Participants: ' + oppParticipants.size());
    for (Audit_Participant__c participant : oppParticipants) {
        System.debug('- Role: ' + participant.Role__c + ', Comments: ' + participant.Comments__c);
    }
}

// Query Participants created for Lead Audits
if (!leadAudits.isEmpty()) {
    List<Audit_Participant__c> leadParticipants = [
        SELECT Id, Audit__c, User__c, Contact__c, Role__c, Comments__c
        FROM Audit_Participant__c 
        WHERE Audit__c IN :leadAudits
    ];
    System.debug('Lead Audit Participants: ' + leadParticipants.size());
    for (Audit_Participant__c participant : leadParticipants) {
        System.debug('- Role: ' + participant.Role__c + ', Comments: ' + participant.Comments__c);
    }
}

System.debug('=== TEST COMPLETE ===');
