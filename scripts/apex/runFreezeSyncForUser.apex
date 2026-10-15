// Ad-hoc sync for a single user, so a manual freeze/unfreeze can be verified
// without touching every user in the org.
//
// Set targetUsername, then run:
//   sf apex run --file scripts/apex/runFreezeSyncForUser.apex --target-org EG-Sandbox

String targetUsername = 'freeze.synccheck.1790013696926@eurasiagroup.net.bolterra';

User target = [SELECT Id, Name, Is_Frozen__c FROM User WHERE Username = :targetUsername LIMIT 1];
UserLogin login = [SELECT IsFrozen FROM UserLogin WHERE UserId = :target.Id LIMIT 1];

System.debug('BEFORE  user=' + target.Name
    + ' | UserLogin.IsFrozen=' + login.IsFrozen
    + ' | User.Is_Frozen__c=' + target.Is_Frozen__c);

Database.executeBatch(new UserFreezeSyncBatch(new Set<Id>{ target.Id }), 200);
