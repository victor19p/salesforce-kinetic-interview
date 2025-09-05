/**
 * @description Opportunity Audit Trigger handler
 * @author Victor Pineda
 * @since 2025
 * 
 */

public with sharing class AuditService {
    public void createAuditForOpportunity(Map<Id, Opportunity> newRecordsMap, Map<Id, Opportunity> oldRecordsMap, String context) {
        // Logic to create Audit__c records for Opportunity changes
        System.debug(LoggingLevel.INFO, 'AuditService - Creating audit for Opportunity changes');
    }

    public void createAuditForLead(Map<Id, Lead> newRecordsMap, Map<Id, Lead> oldRecordsMap, String context) {
        // Logic to create Audit__c records for Lead changes
        System.debug(LoggingLevel.INFO, 'AuditService - Creating audit for Lead changes');
    }
}