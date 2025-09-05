/**
 * @description Opportunity Audit Trigger handler
 * @author Victor Pineda
 * @since 2025
 * 
 */
public with sharing class AuditParticipantService {

    public void createAuditParticipantForOpportunity(Map<Id, Opportunity> newRecordsMap, Map<Id, Opportunity> oldRecordsMap, String context) {
        System.debug(LoggingLevel.INFO, 'AuditParticipantService - Creating audit participant for Opportunity context: ' + context);
    }

    public void createAuditParticipantForLead(Map<Id, Lead> newRecordsMap, Map<Id, Lead> oldRecordsMap, String context) {
        System.debug(LoggingLevel.INFO, 'AuditParticipantService - Creating audit participant for Lead context: ' + context);
    }
}