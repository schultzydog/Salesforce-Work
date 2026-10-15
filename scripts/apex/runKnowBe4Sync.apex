// Enqueues a live KnowBe4 sync. First job loads in-scope campaigns, then
// chains remaining chunks. Check Apex Jobs for progress.
//
//   sf apex run --file scripts/apex/runKnowBe4Sync.apex --target-org EG-Sandbox

Id jobId = System.enqueueJob(new KnowBe4SyncQueueable());
System.debug('Enqueued KnowBe4SyncQueueable as ' + jobId);
