// Creates a disposable user for verifying the freeze sync end to end, then freezes it.
// Deactivate this user when testing is finished.

// Salesforce licenses are fully consumed in this org, so fall back to a license type
// that still has capacity.
Profile p = [
    SELECT Id, Name
    FROM Profile
    WHERE UserLicense.Name IN ('Chatter Free', 'Identity')
      AND UserType != 'Guest'
    ORDER BY Name
    LIMIT 1
];
System.debug('USING_PROFILE=' + p.Name);

String stamp = String.valueOf(DateTime.now().getTime());

User testUser = new User(
    FirstName = 'Freeze',
    LastName = 'SyncCheck',
    Alias = 'frzchk',
    Email = 'ausschultz04@gmail.com',
    Username = 'freeze.synccheck.' + stamp + '@eurasiagroup.net.bolterra',
    ProfileId = p.Id,
    TimeZoneSidKey = 'America/New_York',
    LocaleSidKey = 'en_US',
    EmailEncodingKey = 'UTF-8',
    LanguageLocaleKey = 'en_US',
    Is_Frozen__c = false
);

insert testUser;

System.debug('CREATED_USER_ID=' + testUser.Id);
System.debug('CREATED_USERNAME=' + testUser.Username);
