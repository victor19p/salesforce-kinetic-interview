// INSERT Lead
Lead lead = new Lead(
    LastName = 'Audit Test',
    Company = 'Test Company',
    Status = 'Working - Contacted'
);
insert lead;
System.debug('Inserted Lead: ' + lead.Id);

// UPDATE Lead (change Status to trigger audit)
lead.Status = 'Closed - Not Converted';
update lead;
System.debug('Updated Lead Status: ' + lead.Status);