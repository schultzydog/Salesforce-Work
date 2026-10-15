// Logs the keys on one enrollment row to see whether KnowBe4 exposes a stable
// module/content identifier we could use as the module external id.
//
//   sf apex run --file scripts/apex/knowbe4ModuleIdProbe.apex --target-org EG-Sandbox

String body = KnowBe4Client.fetchEnrollments(1, 2);
List<Object> rows = (List<Object>) JSON.deserializeUntyped(body);
if (!rows.isEmpty()) {
    Map<String, Object> first = (Map<String, Object>) rows[0];
    List<String> keys = new List<String>(first.keySet());
    keys.sort();
    for (String key : keys) {
        Object value = first.get(key);
        System.debug(LoggingLevel.ERROR,
            'KB4_ENROLL ' + key + ' = ' + (value == null ? 'null' : String.valueOf(value).left(150))
        );
    }
}
