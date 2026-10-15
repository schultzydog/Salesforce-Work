public class blogic_Event {

    public static void createEGTimeEntry(Map<Id, Event> eventMap) {

        // ---------------------------------------------------------
        // 1. IDENTIFY EVENTS TO PROCESS
        // ---------------------------------------------------------

        if (eventMap == null || eventMap.isEmpty()) {
            return;
        }

        Map<Id, Event> eventById = new Map<Id, Event>();
        Set<Id> projectIds = new Set<Id>();

        Date minEventDate;
        Date maxEventDate;

        for (Event e : eventMap.values()) {

            if (
                e.Id == null ||
                e.WhatId == null ||
                e.WhatId.getSObjectType() !=
                    Schema.EG_Project__c.getSObjectType() ||
                e.IsRecurrence2 == true ||
                e.IsChild == true
            ) {
                continue;
            }

            eventById.put(e.Id, e);
            projectIds.add(e.WhatId);

            Date eventDate = e.StartDateTime.date();

            if (
                minEventDate == null ||
                eventDate < minEventDate
            ) {
                minEventDate = eventDate;
            }

            if (
                maxEventDate == null ||
                eventDate > maxEventDate
            ) {
                maxEventDate = eventDate;
            }
        }

        if (eventById.isEmpty()) {
            return;
        }

        Set<Id> eventIds = eventById.keySet();


        // ---------------------------------------------------------
        // 2. GET EVENT RELATIONS
        // ---------------------------------------------------------

        /*
         * Retrieve all EventRelations for the parent Events.
         *
         * Intentionally no IsInvitee filter.
         */
        List<EventRelation> relations = [
            SELECT Id,
                   EventId,
                   RelationId
            FROM EventRelation
            WHERE EventId IN :eventIds
        ];


        // ---------------------------------------------------------
        // 3. DETERMINE PROJECT TASK
        // ---------------------------------------------------------

        /*
         * If a Project has exactly one Project Task,
         * automatically assign that Task.
         *
         * LIMIT 2 is sufficient because we only need to know
         * whether there are zero, one, or multiple Tasks.
         */
        Map<Id, Id> projectTaskByProject =
            new Map<Id, Id>();

        for (EG_Project__c project : [
            SELECT Id,
                   (
                       SELECT Id
                       FROM EG_Project_Tasks__r
                       LIMIT 2
                   )
            FROM EG_Project__c
            WHERE Id IN :projectIds
        ]) {

            if (project.EG_Project_Tasks__r.size() == 1) {

                projectTaskByProject.put(
                    project.Id,
                    project.EG_Project_Tasks__r[0].Id
                );
            }
        }


        // ---------------------------------------------------------
        // 4. COLLECT USERS AND CONTACTS
        // ---------------------------------------------------------

        /*
         * Time Cards are owned by Salesforce Users.
         *
         * User EventRelations map directly to Users.
         * Contact EventRelations must be resolved to Users.
         * Leads and other relation types are ignored.
         */
        Set<Id> contactIds = new Set<Id>();
        Set<Id> resolvedUserIds = new Set<Id>();


        // Event owners
        for (Event e : eventById.values()) {

            if (
                e.OwnerId != null &&
                e.OwnerId.getSObjectType() ==
                    Schema.User.getSObjectType()
            ) {
                resolvedUserIds.add(e.OwnerId);
            }
        }


        // Event relations
        for (EventRelation er : relations) {

            if (er.RelationId == null) {
                continue;
            }

            Schema.SObjectType relationType =
                er.RelationId.getSObjectType();

            if (
                relationType ==
                    Schema.User.getSObjectType()
            ) {

                resolvedUserIds.add(er.RelationId);

            } else if (
                relationType ==
                    Schema.Contact.getSObjectType()
            ) {

                contactIds.add(er.RelationId);
            }
        }


        // ---------------------------------------------------------
        // 5. LOAD CONTACT EMAIL ADDRESSES
        // ---------------------------------------------------------

        Map<Id, String> contactEmailById =
            new Map<Id, String>();

        Set<String> contactEmails =
            new Set<String>();

        if (!contactIds.isEmpty()) {

            for (Contact c : [
                SELECT Id,
                       Email
                FROM Contact
                WHERE Id IN :contactIds
                AND Email != NULL
            ]) {

                String email =
                    normalizeIdentity(c.Email);

                if (email != null) {

                    contactEmailById.put(
                        c.Id,
                        email
                    );

                    contactEmails.add(email);
                }
            }
        }


        // ---------------------------------------------------------
        // 6. RESOLVE CONTACTS TO USERS
        //
        // Priority:
        //
        // 1. Contact.Email = User.Username
        // 2. Contact.Email = User.Email
        // ---------------------------------------------------------

        Map<Id, Id> contactToUser =
            new Map<Id, Id>();

        if (!contactEmails.isEmpty()) {

            // -----------------------------------------------------
            // 6A. FIRST CHOICE: USERNAME
            // -----------------------------------------------------

            Map<String, Id> userIdByUsername =
                new Map<String, Id>();

            for (User u : [
                SELECT Id,
                       Username
                FROM User
                WHERE Username IN :contactEmails
            ]) {

                String username =
                    normalizeIdentity(u.Username);

                if (username != null) {

                    userIdByUsername.put(
                        username,
                        u.Id
                    );
                }
            }


            // -----------------------------------------------------
            // 6B. DETERMINE WHICH EMAILS NEED FALLBACK
            // -----------------------------------------------------

            Set<String> emailsNeedingFallback =
                new Set<String>();

            for (String email : contactEmails) {

                if (
                    !userIdByUsername.containsKey(email)
                ) {
                    emailsNeedingFallback.add(email);
                }
            }


            // -----------------------------------------------------
            // 6C. SECOND CHOICE: EMAIL
            // -----------------------------------------------------

            /*
             * User.Email is not necessarily unique.
             *
             * Only use an email match when exactly one
             * User has that email address.
             */
            Map<String, Set<Id>> userIdsByEmail =
                new Map<String, Set<Id>>();

            if (!emailsNeedingFallback.isEmpty()) {

                for (User u : [
                    SELECT Id,
                           Email
                    FROM User
                    WHERE Email IN :emailsNeedingFallback
                ]) {

                    String email =
                        normalizeIdentity(u.Email);

                    if (email == null) {
                        continue;
                    }

                    if (
                        !userIdsByEmail.containsKey(email)
                    ) {
                        userIdsByEmail.put(
                            email,
                            new Set<Id>()
                        );
                    }

                    userIdsByEmail
                        .get(email)
                        .add(u.Id);
                }
            }


            // -----------------------------------------------------
            // 6D. BUILD CONTACT -> USER MAP
            // -----------------------------------------------------

            for (Id contactId :
                 contactEmailById.keySet()) {

                String email =
                    contactEmailById.get(contactId);

                Id userId;


                // First choice: Username
                if (
                    userIdByUsername.containsKey(email)
                ) {

                    userId =
                        userIdByUsername.get(email);

                } else {

                    // Second choice: Email
                    Set<Id> matchingUsers =
                        userIdsByEmail.get(email);

                    if (
                        matchingUsers != null &&
                        matchingUsers.size() == 1
                    ) {

                        userId =
                            matchingUsers.iterator().next();
                    }
                }


                if (userId != null) {

                    contactToUser.put(
                        contactId,
                        userId
                    );

                    resolvedUserIds.add(userId);
                }
            }
        }


        if (resolvedUserIds.isEmpty()) {
            return;
        }


        // ---------------------------------------------------------
        // 7. BULK LOAD RELEVANT TIME CARDS
        // ---------------------------------------------------------

        Map<Id, List<EG_Time_Card__c>> timeCardsByUser =
            new Map<Id, List<EG_Time_Card__c>>();

        for (EG_Time_Card__c timeCard : [
            SELECT Id,
                   OwnerId,
                   Start_Date__c,
                   End_Date__c
            FROM EG_Time_Card__c
            WHERE OwnerId IN :resolvedUserIds
            AND Start_Date__c <= :maxEventDate
            AND End_Date__c >= :minEventDate
            ORDER BY Start_Date__c DESC
        ]) {

            if (
                !timeCardsByUser.containsKey(
                    timeCard.OwnerId
                )
            ) {

                timeCardsByUser.put(
                    timeCard.OwnerId,
                    new List<EG_Time_Card__c>()
                );
            }

            timeCardsByUser
                .get(timeCard.OwnerId)
                .add(timeCard);
        }


        // ---------------------------------------------------------
        // 8. BUILD CANDIDATE TIME ENTRIES
        // ---------------------------------------------------------

        List<EG_Time_Entry__c> candidateEntries =
            new List<EG_Time_Entry__c>();


        // ---------------------------------------------------------
        // 8A. EVENT RELATIONS
        // ---------------------------------------------------------

        for (EventRelation er : relations) {

            Id userId =
                resolveUserId(
                    er.RelationId,
                    contactToUser
                );

            if (userId == null) {
                continue;
            }


            Event e =
                eventById.get(er.EventId);

            if (e == null) {
                continue;
            }


            Id timeCardId =
                findMatchingTimeCard(
                    e.StartDateTime.date(),
                    userId,
                    timeCardsByUser
                );

            if (timeCardId == null) {
                continue;
            }


            candidateEntries.add(
                buildTimeEntry(
                    e,
                    timeCardId,
                    projectTaskByProject
                )
            );
        }


        // ---------------------------------------------------------
        // 8B. EVENT OWNERS
        // ---------------------------------------------------------

        /*
         * Event owner is also eligible for a Time Entry.
         */
        for (Event e : eventById.values()) {

            if (
                e.OwnerId == null ||
                e.OwnerId.getSObjectType() !=
                    Schema.User.getSObjectType()
            ) {
                continue;
            }


            Id timeCardId =
                findMatchingTimeCard(
                    e.StartDateTime.date(),
                    e.OwnerId,
                    timeCardsByUser
                );

            if (timeCardId == null) {
                continue;
            }


            candidateEntries.add(
                buildTimeEntry(
                    e,
                    timeCardId,
                    projectTaskByProject
                )
            );
        }


        if (candidateEntries.isEmpty()) {
            return;
        }


        // ---------------------------------------------------------
        // 9. COLLECT DUPLICATE-CHECK KEYS
        // ---------------------------------------------------------

        Set<String> candidateExternalIds =
            new Set<String>();

        Set<String> candidateSourceEventIds =
            new Set<String>();

        for (EG_Time_Entry__c te :
             candidateEntries) {

            candidateExternalIds.add(
                te.ExternalID__c
            );

            candidateSourceEventIds.add(
                te.Source_Event_ID__c
            );
        }


        // ---------------------------------------------------------
        // 10. FIND EXISTING TIME ENTRIES
        // ---------------------------------------------------------

        Set<String> existingExternalIds =
            new Set<String>();

        Set<String> existingSourceKeys =
            new Set<String>();


        /*
         * DUPLICATE CHECK #1
         *
         * Same:
         *
         * Time Card + Project + Project Task + Date
         */
        for (EG_Time_Entry__c existingEntry : [
            SELECT ExternalID__c
            FROM EG_Time_Entry__c
            WHERE ExternalID__c IN :candidateExternalIds
        ]) {

            if (
                String.isNotBlank(
                    existingEntry.ExternalID__c
                )
            ) {

                existingExternalIds.add(
                    existingEntry.ExternalID__c
                );
            }
        }


        /*
         * DUPLICATE CHECK #2
         *
         * Same source Event + same person's Time Card.
         *
         * This replaces the Event-level processing history
         * previously stored in AttendeeIDs__c.
         */
        for (EG_Time_Entry__c existingEntry : [
            SELECT Source_Event_ID__c,
                   EG_Time_Card__c
            FROM EG_Time_Entry__c
            WHERE Source_Event_ID__c
                IN :candidateSourceEventIds
        ]) {

            if (
                String.isNotBlank(
                    existingEntry.Source_Event_ID__c
                ) &&
                existingEntry.EG_Time_Card__c != null
            ) {

                existingSourceKeys.add(
                    buildSourceKey(
                        existingEntry.Source_Event_ID__c,
                        existingEntry.EG_Time_Card__c
                    )
                );
            }
        }


        // ---------------------------------------------------------
        // 11. REMOVE DUPLICATES
        // ---------------------------------------------------------

        List<EG_Time_Entry__c> entriesToInsert =
            new List<EG_Time_Entry__c>();

        for (EG_Time_Entry__c te :
             candidateEntries) {

            String sourceKey =
                buildSourceKey(
                    te.Source_Event_ID__c,
                    te.EG_Time_Card__c
                );


            // Same Event + same person already processed.
            if (
                existingSourceKeys.contains(
                    sourceKey
                )
            ) {
                continue;
            }


            /*
             * Same person + Project + Task + Date
             * already has a Time Entry.
             *
             * This also prevents duplicate Events from
             * generating duplicate Time Entries.
             */
            if (
                existingExternalIds.contains(
                    te.ExternalID__c
                )
            ) {
                continue;
            }


            entriesToInsert.add(te);


            /*
             * Immediately record both keys so duplicates
             * generated within this transaction are also blocked.
             */
            existingSourceKeys.add(
                sourceKey
            );

            existingExternalIds.add(
                te.ExternalID__c
            );
        }


        // ---------------------------------------------------------
        // 12. INSERT
        // ---------------------------------------------------------

        if (!entriesToInsert.isEmpty()) {
            insert entriesToInsert;
        }
    }


    // =============================================================
    // BUILD TIME ENTRY
    // =============================================================

    private static EG_Time_Entry__c buildTimeEntry(
        Event e,
        Id timeCardId,
        Map<Id, Id> projectTaskByProject
    ) {

        EG_Time_Entry__c te =
            new EG_Time_Entry__c();

        te.Date__c =
            e.StartDateTime.date();

        te.Hours_Worked__c =
            Decimal.valueOf(
                e.DurationInMinutes
            ) / 60;

        te.EG_Time_Card__c =
            timeCardId;

        te.Created_with_Automation__c =
            true;

        te.Time_Entry_Source__c =
            'Automation';

        te.EG_Project__c =
            e.WhatId;

        /*
         * Parent Event that generated this Time Entry.
         */
        te.Source_Event_ID__c =
            String.valueOf(e.Id);


        /*
         * If the Project has exactly one Task,
         * automatically assign it.
         */
        if (
            projectTaskByProject.containsKey(
                e.WhatId
            )
        ) {

            te.EG_Project_Task__c =
                projectTaskByProject.get(
                    e.WhatId
                );
        }


        te.ExternalID__c =
            buildExternalId(te);


        return te;
    }


    // =============================================================
    // BUILD EXTERNAL ID
    // =============================================================

    /*
     * Business uniqueness rule:
     *
     * Time Card + Project + Project Task + Date
     */
    private static String buildExternalId(
        EG_Time_Entry__c te
    ) {

        return
            te.EG_Time_Card__c + ':' +
            te.EG_Project__c + ':' +
            te.EG_Project_Task__c + ':' +
            te.Date__c;
    }


    // =============================================================
    // BUILD SOURCE EVENT KEY
    // =============================================================

    /*
     * Identifies one person's Time Entry
     * for one source Event.
     */
    private static String buildSourceKey(
        String sourceEventId,
        Id timeCardId
    ) {

        return
            sourceEventId + ':' +
            timeCardId;
    }


    // =============================================================
    // FIND MATCHING TIME CARD
    // =============================================================

    /*
     * No SOQL occurs here.
     * Relevant Time Cards have already been loaded in bulk.
     */
    private static Id findMatchingTimeCard(
        Date eventDate,
        Id userId,
        Map<Id, List<EG_Time_Card__c>>
            timeCardsByUser
    ) {

        List<EG_Time_Card__c> timeCards =
            timeCardsByUser.get(userId);


        if (timeCards == null) {
            return null;
        }


        for (EG_Time_Card__c timeCard :
             timeCards) {

            if (
                timeCard.Start_Date__c <= eventDate &&
                timeCard.End_Date__c >= eventDate
            ) {

                return timeCard.Id;
            }
        }


        return null;
    }


    // =============================================================
    // RESOLVE EVENT RELATION TO USER
    // =============================================================

    private static Id resolveUserId(
        Id relationId,
        Map<Id, Id> contactToUser
    ) {

        if (relationId == null) {
            return null;
        }


        Schema.SObjectType relationType =
            relationId.getSObjectType();


        if (
            relationType ==
                Schema.User.getSObjectType()
        ) {
            return relationId;
        }


        if (
            relationType ==
                Schema.Contact.getSObjectType()
        ) {

            return contactToUser.get(
                relationId
            );
        }


        // Leads and other relation types are ignored.
        return null;
    }


    // =============================================================
    // NORMALIZE USERNAME / EMAIL
    // =============================================================

    private static String normalizeIdentity(
        String value
    ) {

        if (String.isBlank(value)) {
            return null;
        }


        return value
            .trim()
            .toLowerCase();
    }
}