# Action Plan: Scalable Audit Trail for Sales Process in Salesforce

## Current Implementation Progress

- Custom objects `Audit__c` and `AuditParticipant__c` created with required fields and validation rule.
- Apex Trigger Framework implemented for Opportunity and Lead using handler classes (`OpportunityAuditTriggerHandler`, `LeadAuditTriggerHandler`).
- Centralized business logic in `AuditService` class, supporting both Opportunity and Lead audits.
- Context managed via enum (`AuditContext`) for clarity and maintainability.
- Bulk-safe DML and error handling implemented in service layer.
- Ready for field comparison logic and further enhancements.

### AuditService - Future Enhancements (*if time allows*)
- *Consider the audit object on record types for Lead and Opportunity.*
- *Consider use of metadata to manage expected audit days based on criteria.*
- *Use schedule and batch to manage alerts.*


## 1. Overview

Design and implement a scalable solution to record audit events for any sales-related object (e.g., Lead, Opportunity, Quote, Order) in Salesforce.  
The system will support automation, alerting, and future expansion to new sales objects.

---

## 2. Object and Fields to Create

### **Generic Custom Object: Audit__c**

| Field Name                  | Data Type                   | Description |
|-----------------------------|-----------------------------|-------------|
| Parent_Type__c              | Picklist                    | Parent object type (Lead, Opportunity, Quote, Order, etc.) |
| Parent_Lead__c              | Lookup (Lead)               | Reference to Lead (if Parent_Type__c = Lead) |
| Parent_Opportunity__c       | Lookup (Opportunity)        | Reference to Opportunity (if Parent_Type__c = Opportunity) |
| Audit_Status__c             | Picklist                    | Audit status (Draft, In Progress, Completed, Overdue, Cancelled) |
| Audit_Type__c               | Picklist                    | Audit type (Pre-Sale, During-Sale, Post-Sale, etc.) |
| Expected_Audit_Date__c      | Date                        | Planned date for the audit |
| Actual_Audit_Date__c        | Date                        | Date the audit was performed |
| Comments__c                 | Long Text                   | Notes and observations |
| Overdue__c                  | Formula/Checkbox            | Indicates if the audit is overdue |
| Original_Owner__c           | Lookup (User)               | Original owner of the parent record |

---

### **Junction Object: AuditParticipant__c**

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

## 3. Automation Proposal

### **A. Record-Triggered Flow (Base Option)**

### **B. Apex Trigger + Handler Framework (Recommended)**
**Implemented:**
- Apex triggers and handler classes for Opportunity and Lead.
- Handler delegates business logic to `AuditService` for maintainability and scalability.
- Enum-based context for clear trigger event management.
- Bulk-safe and error-handled DML operations.

**Next Steps:**
- Implement field comparison logic for updates (e.g., only create audit if StageName or Status changes).
- Extend to other sales objects as needed.

---

## 4. Alerts & Notification System

- **Visual flags:** Overdue__c field highlights records needing attention.
- **Internal Salesforce notifications:** Tasks, Chatter posts, or standard notifications for overdue audits.
- **Email alerts:** Automated emails to owners, auditors, or managers for overdue or pending audits.
- **Reports/Dashboards:** Unified dashboards for all audit types across all parent objects.

---

## 5. Implementation Steps

### Implementation Steps (Progress)
1. **Custom objects and fields created.**
2. **Junction object and validation rule implemented.**
3. **Apex Trigger Framework and handler classes for Opportunity and Lead completed.**
4. **AuditService class centralizes business logic.**
5. **Bulk-safe DML and error handling in place.**
6. **Testing ongoing in dev org.**
7. **Documentation and deployment steps to follow.**

---

## 6. Scalability & Future-Proofing

- Easily extend to new Salesforce objects (Quotes, Orders, Cases, custom sales objects) by adding new Parent_Type values and lookups.
- Centralized reporting and logic ensure long-term maintainability.
- Periodic review and improvement based on business evolution.

---

## 7. Opportunity Stage Audit Analysis

### **Opportunity Stages**
- Prospecting
- Qualification
- Needs Analysis
- Value Proposition
- Id. Decision Makers
- Perception Analysis
- Proposal/Price Quote
- Negotiation/Review
- Closed Won
- Closed Lost

### **Audit-Triggering Stages: Best Practice**

Most companies require audits only at critical milestones:
| Stage                   | Why audit here?                                    |
|-------------------------|----------------------------------------------------|
| Qualification           | Confirm lead quality and fit.                      |
| Proposal/Price Quote    | Ensure pricing, terms, and compliance.             |
| Negotiation/Review      | High risk, contractual obligations, discounts.     |
| Closed Won              | Confirm win, validate compliance and documentation.|
| Closed Lost             | Analyze loss reasons, compliance.                  |

**Sometimes audited:**  
- Needs Analysis (for complex, regulated sales)
- Value Proposition (if highly customized solution)

**Rarely audited:**  
- Prospecting, Perception Analysis, Id. Decision Makers, Value Proposition (unless required by industry regulations).

### **Implementation Recommendation**

- Focus audits on: Qualification, Proposal/Price Quote, Negotiation/Review, Closed Won, Closed Lost.
- Make the audit stages configurable via custom metadata or settings for future flexibility.

---

## 8. AuditConfig__mdt: Custom Metadata Configuration

This section documents the configuration of the `AuditConfig__mdt` Custom Metadata Type, used to manage audit rules for Opportunities and Leads via admin configuration—no code changes required.

---

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

---

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

---

### **Notes**
- For Opportunity records, **OpportunityStage__c** is filled and **LeadStatus__c** is left blank.
- For Lead records, **LeadStatus__c** is filled and **OpportunityStage__c** is left blank.
- Expand by adding more records as your business process grows.

---

### **Permissions**

> **Any user with the Customize Application permission** can edit the values of these metadata records.  
> Changes made in your org will not be overwritten by managed package upgrades.

---