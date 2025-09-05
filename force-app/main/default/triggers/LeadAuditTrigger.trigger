trigger LeadAuditTrigger on Lead (after insert, after update) {
    // new LeadAuditTriggerHandler('LeadAuditTriggerHandler').setMaxLoopCount(10).run();
    new LeadAuditTriggerHandler('LeadAuditTriggerHandler').run();
}