# Scalable Audit Trail for Sales Process in Salesforce

## Overview

Design and implement a scalable solution to record audit events for any sales-related object (e.g., Lead, Opportunity, Quote, Order) in Salesforce.  
The system supports automation, alerting, and future expansion to new sales objects with custom metadata for admin flexibility and minimal code changes.

---

## Objects & Fields

### **Audit__c (Custom Object)**

| Field Name                  | Data Type                   | Description |
|-----------------------------|-----------------------------|-------------|
| Parent_Type__c              | Picklist                    | Parent object type (Lead, Opportunity, etc.) |
| Parent_Lead__c              | Lookup (Lead)               | Reference to Lead |
| Parent_Opportunity__c       | Lookup (Opportunity)        | Reference to Opportunity |
| Opportunity_Stage__c        | Text                        | Opportunity Stage value at time of audit |
| Lead_Status__c              | Text                        | Lead Status value at time of audit |
| Audit_Status__c             | Picklist                    | Audit status (Draft, In Progress, Completed, Overdue, Cancelled) |
| Audit_Type__c               | Picklist                    | Audit type (Pre-Sale, During-Sale, Post-Sale, etc.) |
| Expected_Audit_Date__c      | Date                        | Planned date for the audit |
| Actual_Audit_Date__c        | Date                        | Date the audit was performed |
| Comments__c                 | Long Text                   | Notes and observations |
| Overdue__c                  | Formula/Checkbox            | Indicates if the audit is overdue |
| Original_Owner__c           | Lookup (User)               | Original owner of the parent record |

---

### **AuditParticipant__c (Junction Object)**

| Field Name           | Data Type                 | Description                                             |
|----------------------|--------------------------|---------------------------------------------------------|
| Audit__c             | Lookup (Audit__c)        | Reference to the Audit record                           |
| Contact__c           | Lookup (Contact)         | Reference to the Contact (external participant)         |
| User__c              | Lookup (User)            | Reference to the User (internal participant)            |
| Role__c              | Picklist                 | Role in the audit (Auditor, Stakeholder, Client, etc.)  |
| Comments__c          | Long Text                | Optional notes                                          |

**Validation Rule:**  
Require that either `User__c` or `Contact__c` is populated, but not both.

---

## Automation Logic

### **Apex Trigger + Handler Framework**

- Apex triggers and handler classes for Opportunity and Lead.
- All business logic centralized in the `AuditService` class.
- Context managed via enum or string for clarity and maintainability.
- Bulk-safe DML and error handling implemented.
- Field comparison logic for updates (e.g., only create audit if StageName or Status changes).

**Sample Logic:**
- When an Opportunity or Lead is created or updated, check if the Stage/Status matches an active configuration in `AuditConfig__mdt`.
- If so, create an `Audit__c` record with all relevant info, including the Stage/Status value at the time of audit.

---

## AuditConfig__mdt: Custom Metadata Configuration

Manages audit rules for Opportunities and Leads via admin configuration—no code changes required.

### **Fields**

| Field API Name           | Type      | Picklist Options / Description                                                 |
|------------------------- |---------- |-------------------------------------------------------------------------------|
| **ObjectType__c**        | Picklist  | Opportunity, Lead                                                             |
| **OpportunityStage__c**  | Picklist  | Qualification, Proposal/Price Quote, Negotiation/Review, Closed Won, Closed Lost |
| **LeadStatus__c**        | Picklist  | Working - Contacted, Closed - Not Converted                                   |
| **AuditType__c**         | Picklist  | Pre-Sale, During-Sale, Post-Sale                                              |
| **RecordTypeApiName__c** | Picklist  | Opportunity_Audit, Lead_Audit                                                 |
| **ExpectedAuditDays__c** | Number    | Number of days for expected audit (e.g., 5, 7, 10)                            |
| **IsActive__c**          | Checkbox  | true, false                                                                   |
| **Comments__c**          | TextArea  | Admin notes, description, etc.                                                |

### **Preconfigured Records**

| ObjectType__c | OpportunityStage__c      | LeadStatus__c          | AuditType__c | RecordTypeApiName__c | ExpectedAuditDays__c | IsActive__c | Comments__c                      |
|---------------|-------------------------|------------------------|--------------|----------------------|---------------------|-------------|----------------------------------|
| Opportunity   | Qualification           | *(blank)*              | During-Sale  | Opportunity_Audit    | 7                   | true        | Audit for Qualification stage    |
| Opportunity   | Proposal/Price Quote    | *(blank)*              | During-Sale  | Opportunity_Audit    | 7                   | true        | Audit for Proposal/Price Quote   |
| Opportunity   | Negotiation/Review      | *(blank)*              | During-Sale  | Opportunity_Audit    | 7                   | true        | Audit for Negotiation/Review     |
| Opportunity   | Closed Won              | *(blank)*              | Post-Sale    | Opportunity_Audit    | 5                   | true        | Audit for Closed Won             |
| Opportunity   | Closed Lost             | *(blank)*              | Post-Sale    | Opportunity_Audit    | 5                   | true        | Audit for Closed Lost            |
| Lead          | *(blank)*               | Working - Contacted    | Pre-Sale     | Lead_Audit           | 10                  | true        | Audit for Working - Contacted    |
| Lead          | *(blank)*               | Closed - Not Converted | Pre-Sale     | Lead_Audit           | 10                  | true        | Audit for Closed - Not Converted |

**Notes:**
- For Opportunity records, **OpportunityStage__c** is filled and **LeadStatus__c** is left blank.
- For Lead records, **LeadStatus__c** is filled and **OpportunityStage__c** is left blank.
- Expand by adding more records as your business process grows.

**Permissions:**  
Any user with the Customize Application permission can edit the values of these metadata records.  
Changes made in your org will not be overwritten by managed package upgrades.

---

## Example AuditService Implementation

```apex
public with sharing class AuditService {
    // Retrieve AuditConfig__mdt for given object type and stage/status
    private AuditConfig__mdt getAuditConfig(String objectType, String stageOrStatus) {
        List<AuditConfig__mdt> configs;
        if (objectType == 'Opportunity') {
            configs = [SELECT Id, AuditType__c, ExpectedAuditDays__c 
                        FROM AuditConfig__mdt 
                        WHERE ObjectType__c = :objectType AND OpportunityStage__c = :stageOrStatus AND IsActive__c = true
                        LIMIT 1];
        } else if (objectType == 'Lead') {
            configs = [SELECT Id, AuditType__c, ExpectedAuditDays__c 
                        FROM AuditConfig__mdt 
                        WHERE ObjectType__c = :objectType AND LeadStatus__c = :stageOrStatus AND IsActive__c = true
                        LIMIT 1];
        }
        return configs.isEmpty() ? null : configs[0];
    }

    // Insert audits in bulk
    private void insertAudits(List<Audit__c> auditsToInsert) {
        if (!Schema.sObjectType.Audit__c.isCreateable()) return;
        try { insert auditsToInsert; } catch (Exception e) { System.debug('Error inserting audits: ' + e.getMessage()); }
    }

    // Detect field changes and create audits accordingly
    public void detectFieldChangeAndAudit(Map<Id, SObject> newRecordsMap, Map<Id, SObject> oldRecordsMap, String fieldName, String objectType) {
        List<Audit__c> auditsToInsert = new List<Audit__c>();
        for (SObject newRecord : newRecordsMap.values()) {
            SObject oldRecord = oldRecordsMap != null ? oldRecordsMap.get((Id)newRecord.get('Id')) : null;
            if (oldRecord != null) {
                Object newValue = newRecord.get(fieldName);
                Object oldValue = oldRecord.get(fieldName);
                AuditConfig__mdt config = getAuditConfig(objectType, String.valueOf(newValue));
                if (config != null && newValue != oldValue) {
                    Audit__c audit = new Audit__c();
                    audit.Parent_Type__c = objectType;
                    audit.Audit_Status__c = 'Draft';
                    audit.Expected_Audit_Date__c = Date.today().addDays((Integer)config.ExpectedAuditDays__c);
                    audit.Comments__c = objectType + ' ' + fieldName +
                        ' changed from "' + oldValue + '" to "' + newValue + '"';
                    audit.Audit_Type__c = config.AuditType__c;
                    if (objectType == 'Opportunity') {
                        audit.Parent_Opportunity__c = (Id)newRecord.get('Id');
                        audit.Opportunity_Stage__c = String.valueOf(newValue);
                    } else if (objectType == 'Lead') {
                        audit.Parent_Lead__c = (Id)newRecord.get('Id');
                        audit.Lead_Status__c = String.valueOf(newValue);
                    }
                    auditsToInsert.add(audit);
                }
            }
        }
        insertAudits(auditsToInsert);
    }
}
```

---

## Test Scenarios

**Audits Created:**
- Opportunity changes StageName to "Qualification" → Audit created (config exists & active).
- Opportunity changes StageName to "Closed Won" → Audit created.
- Lead changes Status to "Working - Contacted" → Audit created.
- Lead changes Status to "Closed - Not Converted" → Audit created.

**Audits NOT Created:**
- Opportunity changes StageName to "Prospecting" (not in metadata).
- Opportunity changes StageName to "Qualification" but config inactive.
- Lead changes Status to "Qualified" (not in metadata).
- Update with no actual change (StageName or Status stays the same).

---

## Alerts & Notification System (future scope)

- Overdue__c field highlights records needing attention.
- Notifications for overdue/pending audits.
- Automated emails to owners, auditors, or managers.
- Dashboards for all audit types across all parent objects.

---

## Scalability & Future-Proofing

- Extendable to new Salesforce objects by adding Parent_Type values and metadata records.
- Centralized reporting and logic ensure long-term maintainability.
- Easily configurable by admin—no code changes needed for new audit rules.

---