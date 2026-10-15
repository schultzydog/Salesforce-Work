/**
 * Daily entry point for UserFreezeSyncBatch.
 *
 * Schedule with:
 *   System.schedule('User Freeze Sync Daily', '0 0 6 * * ?', new UserFreezeSyncSchedulable());
 */
public with sharing class UserFreezeSyncSchedulable implements Schedulable {

    private final Set<Id> userIdFilter;

    public UserFreezeSyncSchedulable() {
        this(null);
    }

    /** Restricts the run to specific users. Used by tests and ad-hoc re-syncs. */
    public UserFreezeSyncSchedulable(Set<Id> userIdFilter) {
        this.userIdFilter = userIdFilter;
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new UserFreezeSyncBatch(userIdFilter), 200);
    }
}
