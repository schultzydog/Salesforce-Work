// Schedules the daily UserLogin.IsFrozen -> User.Is_Frozen__c sync at 6:00 AM org time.
// Safe to re-run: aborts any existing job with the same name first.

String jobName = 'User Freeze Sync Daily';

for (CronTrigger ct : [
    SELECT Id
    FROM CronTrigger
    WHERE CronJobDetail.Name = :jobName
]) {
    System.abortJob(ct.Id);
}

String jobId = System.schedule(jobName, '0 0 6 * * ?', new UserFreezeSyncSchedulable());
System.debug('Scheduled ' + jobName + ' as ' + jobId);
