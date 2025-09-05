/**
 * @description Opportunity Audit Trigger handler
 * @author Victor Pineda
 * @since 2025
 * 
 * !notes:
 * ? Consider the audit object on record types for Lead and Opportunity.
 * ? Consider managing Record Types for Audit__c, dividing by related object (Lead, Opportunity, etc.) for layout and process flexibility.
 * ? Use schedule and batch to manage the alerts.
 * ? Consider managing Record Types for AuditParticipant__c (to support multiple participant profiles, e.g. Internal Auditor, External Client, Manager, etc.).
 * 
 * TODO
 * - Add unit tests for service and handlers to ensure reliability as requirements evolve.
 * - Document trigger logic and service methods for future maintainers.
 * - Apply record type logic for AuditParticipant__c, assigning appropriate type based on context or participant role.
 * - If expanding to more objects, keep the service generic and leverage polymorphism or interfaces if needed.
 * - Build scheduled/batch jobs for overdue audits and notifications.
 */

public with sharing class AuditService {
    /**
     * Returns a map of Audit__c record type developer names to their Ids.
     */
    private Map<String, Id> getAuditRecordTypeIds() {
        Map<String, Id> auditRecordTypeIds = new Map<String, Id>();
        if (!Schema.sObjectType.RecordType.isAccessible()) {
            System.debug(LoggingLevel.ERROR, 'User does not have access to RecordType.');
            return auditRecordTypeIds;
        }
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Audit__c' AND DeveloperName IN ('Lead_Audit', 'Opportunity_Audit')]) {
            auditRecordTypeIds.put(rt.DeveloperName, rt.Id);
        }
        return auditRecordTypeIds;
    }
    /**
     * Recupera el registro de configuración desde metadata.
     * @param objectType 'Opportunity' o 'Lead'
     * @param stageOrStatus Valor del StageName (Opportunity) o Status (Lead)
     */
    private AuditConfig__mdt getAuditConfig(String objectType, String stageOrStatus) {
        List<AuditConfig__mdt> configs = new List<AuditConfig__mdt>();
        if (!Schema.sObjectType.AuditConfig__mdt.isAccessible()) {
            System.debug(LoggingLevel.ERROR, 'User does not have read access to AuditConfig__mdt.');
            return null;
        }
        if (objectType == 'Opportunity') {
            configs = [SELECT Id, AuditType__c, ExpectedAuditDays__c 
                        FROM AuditConfig__mdt 
                        WHERE ObjectType__c = :objectType AND Stage__c = :stageOrStatus AND IsActive__c = true
                        LIMIT 1];
        } else if (objectType == 'Lead') {
            configs = [SELECT Id, AuditType__c, ExpectedAuditDays__c 
                        FROM AuditConfig__mdt 
                        WHERE ObjectType__c = :objectType AND Status__c = :stageOrStatus AND IsActive__c = true
                        LIMIT 1];
        }
        return configs.isEmpty() ? null : configs[0];
    }

    private void insertAudits(List<Audit__c> auditsToInsert) {
        if (!Schema.sObjectType.Audit__c.isCreateable()) {
            System.debug(LoggingLevel.ERROR, 'User does not have create access to Audit__c.');
            return;
        }
        try {
            insert auditsToInsert;
            // System.debug(LoggingLevel.INFO, 'Audits created: ' + JSON.serializePretty(auditsToInsert));
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'auditsToInsert: ' + JSON.serializePretty(auditsToInsert));
            System.debug(LoggingLevel.ERROR, 'Error inserting audits: ' + e.getMessage());
        }
    }

    public void detectFieldChangeAndAudit(Map<Id, SObject> newRecordsMap, Map<Id, SObject> oldRecordsMap, String fieldName, String objectType) {
        List<Audit__c> auditsToInsert = new List<Audit__c>();
        Map<String, Id> auditRecordTypeIds = getAuditRecordTypeIds();
        Id opportunityAuditRtId = auditRecordTypeIds.get('Opportunity_Audit');
        Id leadAuditRtId = auditRecordTypeIds.get('Lead_Audit');

        for (SObject newRecord : newRecordsMap.values()) {
            SObject oldRecord = oldRecordsMap != null ? oldRecordsMap.get((Id)newRecord.get('Id')) : null;
            if (oldRecord != null) {
                Object newValue = newRecord.get(fieldName);
                Object oldValue = oldRecord.get(fieldName);

                // Consulta la configuración desde metadata
                AuditConfig__mdt config = getAuditConfig(objectType, String.valueOf(newValue));
                if (config != null && newValue != oldValue) {
                    Audit__c audit = new Audit__c();
                    audit.Parent_Type__c = objectType;
                    audit.Audit_Status__c = 'Draft';
                    audit.Expected_Audit_Date__c = Date.today().addDays((Integer)config.ExpectedAuditDays__c);
                    audit.Comments__c = objectType + ' ' + fieldName +
                        ' changed from "' + oldValue + '" to "' + newValue + '"';
                    audit.Audity_Type__c = config.AuditType__c;
                    if (objectType == 'Opportunity') {
                        audit.Parent_Opportunity__c = (Id)newRecord.get('Id');
                        audit.Opportunity_Stage__c = String.valueOf(newValue);
                        audit.RecordTypeId = opportunityAuditRtId;
                    } else if (objectType == 'Lead') {
                        audit.Parent_Lead__c = (Id)newRecord.get('Id');
                        audit.Lead_Status__c = String.valueOf(newValue);
                        audit.RecordTypeId = leadAuditRtId;
                    }
                    auditsToInsert.add(audit);
                }
            }
        }
        insertAudits(auditsToInsert);
    }

    public void createAuditForOpportunity(Map<Id, Opportunity> newRecordsMap, Map<Id, Opportunity> oldRecordsMap, String context) {
        Map<String, Id> auditRecordTypeIds = getAuditRecordTypeIds();
        Id opportunityAuditRtId = auditRecordTypeIds.get('Opportunity_Audit');
        switch on context {
            when 'AFTER_INSERT' {
                System.debug(LoggingLevel.INFO, 'AuditService - Creating audit for Opportunity insert context: ' + context);
                List<Audit__c> auditsToInsert = new List<Audit__c>();
                for (Opportunity opp : newRecordsMap.values()) {
                    AuditConfig__mdt config = getAuditConfig('Opportunity', opp.StageName);
                    if (config != null) {
                        Audit__c audit = new Audit__c();
                        audit.Parent_Opportunity__c = opp.Id;
                        audit.Parent_Type__c = 'Opportunity';
                        audit.Opportunity_Stage__c = opp.StageName;
                        audit.Audity_Type__c = config.AuditType__c;
                        audit.Expected_Audit_Date__c = Date.today().addDays((Integer)config.ExpectedAuditDays__c);
                        audit.Audit_Status__c = 'Draft';
                        audit.RecordTypeId = opportunityAuditRtId;
                        auditsToInsert.add(audit);
                    }
                }
                insertAudits(auditsToInsert);
            }
            when 'AFTER_UPDATE' {
                System.debug(LoggingLevel.INFO, 'AuditService - Creating audit for Opportunity updates context: ' + context);
                detectFieldChangeAndAudit(newRecordsMap, oldRecordsMap, 'StageName', 'Opportunity');
            }
        }
    }

    public void createAuditForLead(Map<Id, Lead> newRecordsMap, Map<Id, Lead> oldRecordsMap, String context) {
        Map<String, Id> auditRecordTypeIds = getAuditRecordTypeIds();
        Id leadAuditRtId = auditRecordTypeIds.get('Lead_Audit');
        switch on context {
            when 'AFTER_INSERT' {
                System.debug(LoggingLevel.INFO, 'AuditService - Creating audit for Lead insert context: ' + context);
                List<Audit__c> auditsToInsert = new List<Audit__c>();
                for (Lead lead : newRecordsMap.values()) {
                    AuditConfig__mdt config = getAuditConfig('Lead', lead.Status);
                    if (config != null) {
                        Audit__c audit = new Audit__c();
                        audit.Parent_Lead__c = lead.Id;
                        audit.Parent_Type__c = 'Lead';
                        audit.Lead_Status__c = lead.Status;
                        audit.Audity_Type__c = config.AuditType__c;
                        audit.Expected_Audit_Date__c = Date.today().addDays((Integer)config.ExpectedAuditDays__c);
                        audit.Audit_Status__c = 'Draft';
                        audit.RecordTypeId = leadAuditRtId;
                        auditsToInsert.add(audit);
                    }
                }
                insertAudits(auditsToInsert);
            }
            when 'AFTER_UPDATE' {
                System.debug(LoggingLevel.INFO, 'AuditService - Creating audit for Lead updates context: ' + context);
                detectFieldChangeAndAudit(newRecordsMap, oldRecordsMap, 'Status', 'Lead');
            }
        }
    }

}

