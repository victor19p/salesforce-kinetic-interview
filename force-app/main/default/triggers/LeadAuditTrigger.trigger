trigger LeadAuditTrigger on Lead (after insert, after update) {
    new LeadAuditTriggerHandler('LeadAuditTriggerHandler').setMaxLoopCount(3).run();
}