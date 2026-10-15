/**
 * Daily entry point for KnowBe4SyncQueueable.
 *
 * Schedule with:
 *   System.schedule('KnowBe4 Sync Daily', '0 0 7 * * ?', new KnowBe4SyncSchedulable());
 */
public with sharing class KnowBe4SyncSchedulable implements Schedulable {

    public void execute(SchedulableContext sc) {
        System.enqueueJob(new KnowBe4SyncQueueable());
    }
}
