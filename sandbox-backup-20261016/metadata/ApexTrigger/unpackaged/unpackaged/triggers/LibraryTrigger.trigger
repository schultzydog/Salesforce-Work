trigger LibraryTrigger on Library__c (after insert) {
    EntitlementsHandler.onLibraryInsert(Trigger.new);
}