// Schedules the daily KnowBe4 campaign sync at 7:00 AM org time.
// Safe to re-run: aborts any existing job with the same name first.

String jobName = 'KnowBe4 Sync Daily';

for (CronTrigger ct : [
    SELECT Id
    FROM CronTrigger
    WHERE CronJobDetail.Name = :jobName
]) {
    System.abortJob(ct.Id);
}

String jobId = System.schedule(jobName, '0 0 7 * * ?', new KnowBe4SyncSchedulable());
System.debug('Scheduled ' + jobName + ' as ' + jobId);
