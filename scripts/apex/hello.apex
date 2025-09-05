// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

// Crear una nueva oportunidad
Opportunity opp = new Opportunity(
    Name = 'Test Audit Opportunity',
    StageName = 'Prospecting',
    CloseDate = Date.today().addDays(30)
);
insert opp;
System.debug('Oportunidad creada: ' + opp.Id);

// Actualizar la oportunidad (por ejemplo, cambiar StageName)
opp.StageName = 'Closed Won';
update opp;
System.debug('Oportunidad actualizada: ' + opp.Id);