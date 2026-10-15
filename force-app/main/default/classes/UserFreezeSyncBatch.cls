/**
 * Keeps User.Is_Frozen__c in step with UserLogin.IsFrozen in both directions:
 * freezing sets the flag, unfreezing clears it.
 *
 * UserLogin does not support triggers or record-triggered flows, so freeze state is
 * polled on a schedule instead of reacted to in real time.
 */
public with sharing class UserFreezeSyncBatch implements Database.Batchable<SObject>, Database.Stateful {

    /**
     * Users whose freeze status changed during this run, mapped to the status they
     * moved to. True means they became frozen, false means they became unfrozen.
     */
    private Map<Id, Boolean> freezeStatusChanges = new Map<Id, Boolean>();

    private final Set<Id> scopedUserIds;

    public UserFreezeSyncBatch() {
        this(null);
    }

    /** Restricts the run to specific users. Used by tests and ad-hoc re-syncs. */
    public UserFreezeSyncBatch(Set<Id> scopedUserIds) {
        this.scopedUserIds = scopedUserIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (scopedUserIds != null) {
            Set<Id> targetUserIds = scopedUserIds;
            return Database.getQueryLocator([
                SELECT Id, UserId, IsFrozen
                FROM UserLogin
                WHERE UserId IN :targetUserIds
            ]);
        }
        return Database.getQueryLocator([
            SELECT Id, UserId, IsFrozen
            FROM UserLogin
            WHERE UserId IN (
                SELECT Id FROM User WHERE IsActive = true OR Is_Frozen__c = true
            )
        ]);
    }

    public void execute(Database.BatchableContext bc, List<UserLogin> scope) {
        Map<Id, Boolean> loginFrozenByUserId = new Map<Id, Boolean>();
        for (UserLogin login : scope) {
            if (login.UserId != null) {
                loginFrozenByUserId.put(login.UserId, login.IsFrozen);
            }
        }
        if (loginFrozenByUserId.isEmpty()) {
            return;
        }

        List<User> usersWithChangedStatus = new List<User>();
        for (User u : [
            SELECT Id, Is_Frozen__c
            FROM User
            WHERE Id IN :loginFrozenByUserId.keySet()
        ]) {
            Boolean isFrozenOnLogin = loginFrozenByUserId.get(u.Id) == true;
            Boolean isFrozenOnUser = u.Is_Frozen__c == true;

            if (isFrozenOnLogin == isFrozenOnUser) {
                continue;
            }

            freezeStatusChanges.put(u.Id, isFrozenOnLogin);
            usersWithChangedStatus.add(new User(Id = u.Id, Is_Frozen__c = isFrozenOnLogin));
        }

        if (!usersWithChangedStatus.isEmpty()) {
            update usersWithChangedStatus;
        }
    }

    public void finish(Database.BatchableContext bc) {
        Set<Id> becameFrozen = new Set<Id>();
        Set<Id> becameUnfrozen = new Set<Id>();

        for (Id userId : freezeStatusChanges.keySet()) {
            if (freezeStatusChanges.get(userId)) {
                becameFrozen.add(userId);
            } else {
                becameUnfrozen.add(userId);
            }
        }

        // Alerting hooks off these sets once notification requirements are settled.
        System.debug('Became frozen: ' + becameFrozen);
        System.debug('Became unfrozen: ' + becameUnfrozen);
    }
}
