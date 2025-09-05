/**
 * @description Opportunity Audit Trigger handler
 * @author Victor Pineda
 * @since 2025
 * 
 * !notes:
 * ? consider the audit object separate on record types for Lead and Opportunity
 * ? consider use metadata to manage the expected audit days based on criteria
 * ? use schedule and batch to manage the alerts
 */

public with sharing class AuditService {
    public enum AuditContext {
        AFTER_INSERT,
        AFTER_UPDATE
    }

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

    public void createAuditForOpportunity(Map<Id, Opportunity> newRecordsMap, Map<Id, Opportunity> oldRecordsMap, AuditContext context) {
        switch on context {
            when AFTER_INSERT {
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
            when AFTER_UPDATE {
                System.debug(LoggingLevel.INFO, 'AuditService - Creating audit for Opportunity updates context: ' + context);
                //TODO manage prior values vs new values if needed
                // Example: Only create audit if StageName changed
                // for (Opportunity opp : newRecordsMap.values()) {
                //     Opportunity oldOpp = oldRecordsMap != null ? oldRecordsMap.get(opp.Id) : null;
                //     if (oldOpp != null && opp.StageName != oldOpp.StageName) {
                //         auditsToInsert.add(createAuditRecordForOpportunity(opp));
                //     }
                // }
            }
        }
    }


    public void createAuditForLead(Map<Id, Lead> newRecordsMap, Map<Id, Lead> oldRecordsMap, AuditContext context) {
        switch on context {
            when AFTER_INSERT {
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
            when AFTER_UPDATE {
                System.debug(LoggingLevel.INFO, 'AuditService - Creating audit for Lead updates context: ' + context);
                //TODO manage prior values vs new values if needed
                // Example: Only create audit if Status changed
                // for (Lead lead : newRecordsMap.values()) {
                //     Lead oldLead = oldRecordsMap != null ? oldRecordsMap.get(lead.Id) : null;
                //     if (oldLead != null && lead.Status != oldLead.Status) {
                //         auditsToInsert.add(createAuditRecordForLead(lead));
                //     }
                // }
            }
        }
    }

}