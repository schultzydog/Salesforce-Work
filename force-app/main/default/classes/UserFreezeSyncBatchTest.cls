@IsTest
private class UserFreezeSyncBatchTest {

    private static User buildTestUser(String aliasSuffix) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String unique = String.valueOf(Crypto.getRandomLong()).replace('-', '');
        return new User(
            FirstName = 'Freeze',
            LastName = 'SyncTest',
            Alias = 'frz' + aliasSuffix,
            Email = 'freeze.synctest@example.com',
            Username = 'freeze.synctest.' + unique + '@example.com.invalid',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
    }

    private static User insertTestUser(String aliasSuffix, Boolean preSetFlag) {
        User target = buildTestUser(aliasSuffix);
        target.Is_Frozen__c = preSetFlag;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert target;
        }
        return target;
    }

    @IsTest
    static void mirrorsFrozenStateOntoUser() {
        User target = insertTestUser('a', false);

        UserLogin login = [SELECT Id FROM UserLogin WHERE UserId = :target.Id LIMIT 1];
        System.runAs(new User(Id = UserInfo.getUserId())) {
            update new UserLogin(Id = login.Id, IsFrozen = true);
        }

        Test.startTest();
        Database.executeBatch(new UserFreezeSyncBatch(new Set<Id>{ target.Id }), 200);
        Test.stopTest();

        User synced = [SELECT Is_Frozen__c FROM User WHERE Id = :target.Id];
        System.assertEquals(true, synced.Is_Frozen__c, 'Frozen login should set the User flag');
    }

    @IsTest
    static void clearsFlagWhenUnfrozen() {
        User target = insertTestUser('b', true);

        Test.startTest();
        Database.executeBatch(new UserFreezeSyncBatch(new Set<Id>{ target.Id }), 200);
        Test.stopTest();

        User synced = [SELECT Is_Frozen__c FROM User WHERE Id = :target.Id];
        System.assertEquals(false, synced.Is_Frozen__c, 'Unfrozen login should clear the User flag');
    }

    @IsTest
    static void schedulableRunsTheBatch() {
        User target = insertTestUser('c', true);

        Test.startTest();
        new UserFreezeSyncSchedulable(new Set<Id>{ target.Id }).execute(null);
        Test.stopTest();

        User synced = [SELECT Is_Frozen__c FROM User WHERE Id = :target.Id];
        System.assertEquals(false, synced.Is_Frozen__c, 'Scheduled run should sync the User flag');
    }

    @IsTest
    static void scheduleRegistersCronJob() {
        Test.startTest();
        String jobId = System.schedule(
            'User Freeze Sync Test',
            '0 0 6 3 9 ? 2050',
            new UserFreezeSyncSchedulable(new Set<Id>())
        );
        Test.stopTest();

        CronTrigger ct = [SELECT CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('0 0 6 3 9 ? 2050', ct.CronExpression, 'Job should register with the given cron');
    }

    @IsTest
    static void defaultConstructorTargetsAllLogins() {
        System.assertNotEquals(null, new UserFreezeSyncBatch(), 'No-arg constructor should build an unfiltered batch');
        System.assertNotEquals(null, new UserFreezeSyncSchedulable(), 'No-arg schedulable should build');
    }
}
