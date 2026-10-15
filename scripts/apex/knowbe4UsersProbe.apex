// Logs one page of /v1/users so the PPP and risk-score field names can be
// mapped against the real payload instead of guessed.
//
//   sf apex run --file scripts/apex/knowbe4UsersProbe.apex --target-org EG-Sandbox

String body = KnowBe4Client.get('/v1/users?page=1&per_page=2');
List<Object> rows = (List<Object>) JSON.deserializeUntyped(body);
System.debug(LoggingLevel.ERROR, 'KB4_USERS_COUNT ' + rows.size());
if (!rows.isEmpty()) {
    Map<String, Object> first = (Map<String, Object>) rows[0];
    List<String> keys = new List<String>(first.keySet());
    keys.sort();
    for (String key : keys) {
        Object value = first.get(key);
        String rendered = value == null ? 'null' : String.valueOf(value);
        System.debug(LoggingLevel.ERROR, 'KB4_USER_FIELD ' + key + ' = ' + rendered.left(120));
    }
}
