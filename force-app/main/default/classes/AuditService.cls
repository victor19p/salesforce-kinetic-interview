/**
 * @description Opportunity Audit Trigger handler
 * @author Victor Pineda
 * @since 2025
 * 
 * !notes:
 * ? Consider the audit object on record types for Lead and Opportunity.
 * ? Consider managing Record Types for Audit__c, dividing by related object (Lead, Opportunity, etc.) for layout and process flexibility.
 * ? Consider use metadata to manage the expected audit days based on criteria.
 * ? Use schedule and batch to manage the alerts.
 * ? Consider managing Record Types for AuditParticipant__c (to support multiple participant profiles, e.g. Internal Auditor, External Client, Manager, etc.).
 * 
 * TODO
 * - Move audit config (stages, statuses, expected days) to Custom Metadata for admin flexibility.
 * - Add unit tests for service and handlers to ensure reliability as requirements evolve.
 * - Document trigger logic and service methods for future maintainers.
 * - Apply record type logic for AuditParticipant__c, assigning appropriate type based on context or participant role.
 * - If expanding to more objects, keep the service generic and leverage polymorphism or interfaces if needed.
 * - Build scheduled/batch jobs for overdue audits and notifications.
 */

public with sharing class AuditService {
    //! Consider move this to metadata, for fast updates without code changes
    Set<String> oppAuditStages = new Set<String>{
        'Qualification',
        'Proposal/Price Quote',
        'Negotiation/Review',
        'Closed Won',
        'Closed Lost'
    };
    Set<String> oppClosedStages = new Set<String>{
        'Closed Won',
        'Closed Lost'
    };
    Set<String> leadAuditStatuses = new Set<String>{
        'Working - Contacted',
        'Closed - Not Converted'
    };

    private void insertAudits(List<Audit__c> auditsToInsert) {
        if (!Schema.sObjectType.Audit__c.isCreateable()) {
            System.debug(LoggingLevel.ERROR, 'User does not have create access to Audit__c.');
            return;
        }
        try {
            insert auditsToInsert;
            System.debug(LoggingLevel.INFO, 'Audits created: ' + JSON.serializePretty(auditsToInsert));
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error inserting audits: ' + e.getMessage());
        }
    }

    public void detectFieldChangeAndAudit(Map<Id, SObject> newRecordsMap, Map<Id, SObject> oldRecordsMap, String fieldName, String objectType) {
        List<Audit__c> auditsToInsert = new List<Audit__c>();
        for (SObject newRecord : newRecordsMap.values()) {
            SObject oldRecord = oldRecordsMap != null ? oldRecordsMap.get((Id)newRecord.get('Id')) : null;
            if (oldRecord != null) {
                Object newValue = newRecord.get(fieldName);
                Object oldValue = oldRecord.get(fieldName);

                Boolean shouldAudit = false;
                String auditType;

                if (objectType == 'Opportunity' && oppAuditStages.contains(String.valueOf(newValue))) {
                    shouldAudit = true;
                    auditType = oppClosedStages.contains(String.valueOf(newValue)) ? 'Post-Sale' : 'During-Sale';
                } else if (objectType == 'Lead' && leadAuditStatuses.contains(String.valueOf(newValue))) {
                    shouldAudit = true;
                    auditType = 'Pre-Sale';
                }

                if (shouldAudit && newValue != oldValue) {
                    Audit__c audit = new Audit__c();
                    audit.Parent_Type__c = objectType;
                    audit.Audit_Status__c = 'Draft';
                    audit.Expected_Audit_Date__c = Date.today().addDays(7); // consider metadata for config
                    audit.Comments__c = objectType + ' ' + fieldName +
                        ' changed from "' + oldValue + '" to "' + newValue + '"';
                    audit.Audity_Type__c = auditType;
                    if (objectType == 'Opportunity') {
                        audit.Parent_Opportunity__c = (Id)newRecord.get('Id');
                    } else if (objectType == 'Lead') {
                        audit.Parent_Lead__c = (Id)newRecord.get('Id');
                    }
                    auditsToInsert.add(audit);
                }
            }
        }
        insertAudits(auditsToInsert);
    }

    public void createAuditForOpportunity(Map<Id, Opportunity> newRecordsMap, Map<Id, Opportunity> oldRecordsMap, String context) {
        switch on context {
            when 'AFTER_INSERT' {
                System.debug(LoggingLevel.INFO, 'AuditService - Creating audit for Opportunity insert context: ' + context);
                List<Audit__c> auditsToInsert = new List<Audit__c>();
                for (Opportunity opp : newRecordsMap.values()) {
                    Audit__c audit = new Audit__c();
                    audit.Parent_Opportunity__c = opp.Id;
                    audit.Parent_Type__c = 'Opportunity';
                    audit.Audity_Type__c = 'During-Sale'; //conditional of the op StageName
                    audit.Expected_Audit_Date__c = Date.today().addDays(7); //example logic
                    audit.Audit_Status__c = 'Draft';
                    auditsToInsert.add(audit);
                }
                insertAudits(auditsToInsert);
            }
            when 'AFTER_UPDATE' {
                System.debug(LoggingLevel.INFO, 'AuditService - Creating audit for Opportunity updates context: ' + context);
                //TODO manage prior values vs new values if needed
                // detectOpportunityStageChange(newRecordsMap, oldRecordsMap);
                detectFieldChangeAndAudit(newRecordsMap, oldRecordsMap, 'StageName', 'Opportunity');
            }
        }
    }


    public void createAuditForLead(Map<Id, Lead> newRecordsMap, Map<Id, Lead> oldRecordsMap, String context) {
        switch on context {
            when 'AFTER_INSERT' {
                System.debug(LoggingLevel.INFO, 'AuditService - Creating audit for Lead insert context: ' + context);
                List<Audit__c> auditsToInsert = new List<Audit__c>();
                for (Lead lead : newRecordsMap.values()) {
                    Audit__c audit = new Audit__c();
                    audit.Parent_Lead__c = lead.Id;
                    audit.Parent_Type__c = 'Lead';
                    audit.Audity_Type__c = 'Pre-Sale'; //conditional of the lead Status
                    audit.Expected_Audit_Date__c = Date.today().addDays(7); //example logic
                    audit.Audit_Status__c = 'Draft';
                    auditsToInsert.add(audit);
                }
                insertAudits(auditsToInsert);
            }
            when 'AFTER_UPDATE' {
                System.debug(LoggingLevel.INFO, 'AuditService - Creating audit for Lead updates context: ' + context);
                //TODO manage prior values vs new values if needed
                // detectLeadStageChange(newRecordsMap, oldRecordsMap);
                detectFieldChangeAndAudit(newRecordsMap, oldRecordsMap, 'Status', 'Lead');
            }
        }
    }

}

