/**
 * @description Opportunity Audit Trigger handler
 * @author Victor Pineda
 * @since 2025
 * 
 */
public with sharing class AuditParticipantService {

    /**
     * Procesa y crea los participantes de auditoría para una lista de registros Audit__c.
     * @param auditsToInsert Lista de registros Audit__c recién creados.
     */
    public void processAuditParticipants(List<Audit__c> auditsToInsert){
        if (!checkObjectAccess()) {
            return;
        }
        Set<Id> oppIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();

        for(Audit__c audit : auditsToInsert){
            if(audit.Parent_Type__c == 'Opportunity' && audit.Parent_Opportunity__c != null){
                oppIds.add(audit.Parent_Opportunity__c);
            } else if(audit.Parent_Type__c == 'Lead' && audit.Parent_Lead__c != null){
                leadIds.add(audit.Parent_Lead__c);
            }
        }

        Map<Id, Opportunity> oppMap = fetchOpportunities(oppIds);
        Map<Id, Lead> leadMap = fetchLeads(leadIds);

        for(Opportunity opp : oppMap.values()){
            if(opp.AccountId != null){
                accountIds.add(opp.AccountId);
            }
            if(opp.OwnerId != null && !ownerIds.contains(opp.OwnerId)){
                ownerIds.add(opp.OwnerId);
            }
        }
        for(Lead lead : leadMap.values()){
            if(lead.OwnerId != null && !ownerIds.contains(lead.OwnerId)){
                ownerIds.add(lead.OwnerId);
            }
        }
        Map<Id, Account> accountMap = fetchAccounts(accountIds, ownerIds);
        Map<Id, User> userMap = fetchUsers(ownerIds);
        Map<Id, Contact> contactMap = fetchContacts(accountIds);

        List<Audit_Participant__c> participantsToInsert = buildAuditParticipants(auditsToInsert, oppMap, leadMap, accountMap, contactMap);
        insertAuditParticipants(participantsToInsert);
    }

    private Boolean checkObjectAccess() {
        if (!Schema.sObjectType.Account.isAccessible()) {
            System.debug(LoggingLevel.ERROR, 'Account is not accessible');
            return false;
        }
        if (!Schema.sObjectType.Contact.isAccessible()) {
            System.debug(LoggingLevel.ERROR, 'Contact is not accessible');
            return false;
        }
        if (!Schema.sObjectType.User.isAccessible()) {
            System.debug(LoggingLevel.ERROR, 'User is not accessible');
            return false;
        }
        if (!Schema.sObjectType.Opportunity.isAccessible()) {
            System.debug(LoggingLevel.ERROR, 'Opportunity is not accessible');
            return false;
        }
        if (!Schema.sObjectType.Lead.isAccessible()) {
            System.debug(LoggingLevel.ERROR, 'Lead is not accessible');
            return false;
        }
        return true;
    }

    private Map<Id, Opportunity> fetchOpportunities(Set<Id> oppIds) {
        if (oppIds.isEmpty()) {
            return new Map<Id, Opportunity>();
        }
        return new Map<Id, Opportunity>(
            [SELECT Id, OwnerId, AccountId FROM Opportunity WHERE Id IN :oppIds]
        );
    }

    private Map<Id, Account> fetchAccounts(Set<Id> accountIds, Set<Id> ownerIds) {
        if (accountIds.isEmpty()) {
            return new Map<Id, Account>();
        }
        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, OwnerId FROM Account WHERE Id IN :accountIds]
        );
        for (Account acc : accountMap.values()) {
            if (acc.OwnerId != null && !ownerIds.contains(acc.OwnerId)) {
                ownerIds.add(acc.OwnerId);
            }
        }
        return accountMap;
    }

    private Map<Id, User> fetchUsers(Set<Id> ownerIds) {
        if (ownerIds.isEmpty()) {
            return new Map<Id, User>();
        }
        return new Map<Id, User>(
            [SELECT Id, Email FROM User WHERE Id IN :ownerIds]
        );
    }

    private Map<Id, Contact> fetchContacts(Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return new Map<Id, Contact>();
        }
        return new Map<Id, Contact>(
            [SELECT Id, Email, AccountId, OwnerId FROM Contact WHERE AccountId IN :accountIds]
        );
    }

    private Map<Id, Lead> fetchLeads(Set<Id> leadIds) {
        if (leadIds.isEmpty()) {
            return new Map<Id, Lead>();
        }
        return new Map<Id, Lead>(
            [SELECT Id, OwnerId FROM Lead WHERE Id IN :leadIds]
        );
    }

    private List<Audit_Participant__c> buildAuditParticipants(
        List<Audit__c> auditsToInsert,
        Map<Id, Opportunity> oppMap,
        Map<Id, Lead> leadMap,
        Map<Id, Account> accountMap,
        Map<Id, Contact> contactMap
    ) {
        List<Audit_Participant__c> participantsToInsert = new List<Audit_Participant__c>();
        for (Audit__c audit : auditsToInsert) {
            if (audit.Parent_Type__c == 'Opportunity' && audit.Parent_Opportunity__c != null) {
                Id oppId = audit.Parent_Opportunity__c;
                Opportunity opp = oppMap.get(oppId);
                if (opp == null) {continue;}
                Account acc = accountMap.get(opp.AccountId);
                if (acc == null) {continue;}

                // Opportunity Owner
                Audit_Participant__c oppOwnerParticipant = new Audit_Participant__c();
                oppOwnerParticipant.Audit__c = audit.Id;
                oppOwnerParticipant.User__c = opp.OwnerId;
                oppOwnerParticipant.Role__c = 'Owner';
                oppOwnerParticipant.OwnerId = opp.OwnerId;
                oppOwnerParticipant.Comments__c = 'Opportunity Owner';
                participantsToInsert.add(oppOwnerParticipant);

                // Account Owner (if different)
                if (acc.OwnerId != null && acc.OwnerId != opp.OwnerId) {
                    Audit_Participant__c accOwnerParticipant = new Audit_Participant__c();
                    accOwnerParticipant.Audit__c = audit.Id;
                    accOwnerParticipant.User__c = acc.OwnerId;
                    accOwnerParticipant.OwnerId = acc.OwnerId;
                    accOwnerParticipant.Role__c = 'Owner';
                    accOwnerParticipant.Comments__c = 'Account Owner';
                    participantsToInsert.add(accOwnerParticipant);
                }

                // Account Contacts
                for (Contact con : contactMap.values()) {
                    if (con.AccountId == acc.Id) {
                        Audit_Participant__c contactParticipant = new Audit_Participant__c();
                        contactParticipant.Audit__c = audit.Id;
                        contactParticipant.Contact__c = con.Id;
                        contactParticipant.Role__c = 'Client';
                        contactParticipant.Comments__c = 'Account Contact';
                        participantsToInsert.add(contactParticipant);
                    }
                }
            } else if (audit.Parent_Type__c == 'Lead' && audit.Parent_Lead__c != null) {
                Id leadId = audit.Parent_Lead__c;
                Lead lead = leadMap.get(leadId);
                if (lead == null) {continue;}
                // Only add Lead Owner as participant
                Audit_Participant__c leadOwnerParticipant = new Audit_Participant__c();
                leadOwnerParticipant.Audit__c = audit.Id;
                leadOwnerParticipant.User__c = lead.OwnerId;
                leadOwnerParticipant.Role__c = 'Owner';
                leadOwnerParticipant.OwnerId = lead.OwnerId;
                leadOwnerParticipant.Comments__c = 'Lead Owner';
                participantsToInsert.add(leadOwnerParticipant);
            }
        }
        return participantsToInsert;
    }

    public void insertAuditParticipants(List<Audit_Participant__c> participantsToInsert) {
        try {
            if (!Schema.sObjectType.Audit_Participant__c.isCreateable()) {
                System.debug(LoggingLevel.ERROR, 'No create access to Audit_Participant__c object.');
                return;
            }
            insert participantsToInsert;
            // System.debug(LoggingLevel.INFO, 'Audit Participants created: ' + JSON.serializePretty(participantsToInsert));
            System.debug(LoggingLevel.INFO, '==================> AUDIT PARTICIPANTS size: ' + participantsToInsert.size());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'participantsToInsert: ' + JSON.serializePretty(participantsToInsert));
            System.debug(LoggingLevel.ERROR, 'Error inserting audit participants: ' + e.getMessage());
        }
    }
}