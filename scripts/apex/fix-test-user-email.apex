User u = [SELECT Id, Email, Username, IsActive FROM User WHERE Id = '005WL00000kLRE2YAO'];
System.debug('Before Email=' + u.Email + ' Username=' + u.Username);
u.IsActive = true;
u.Username = 'outlook.panel.test.retired.' + String.valueOf(Datetime.now().getTime()) + '@eurasiagroup.net.bolterra';
u.Email = 'outlook.panel.test.retired@example.invalid';
Database.SaveResult sr = Database.update(u, false);
System.debug('success=' + sr.isSuccess());
if (!sr.isSuccess()) {
  for (Database.Error e : sr.getErrors()) {
    System.debug('ERR: ' + e.getStatusCode() + ' ' + e.getMessage() + ' fields=' + e.getFields());
  }
}
u = [SELECT Id, Email, Username, IsActive FROM User WHERE Id = '005WL00000kLRE2YAO'];
System.debug('After Email=' + u.Email + ' Username=' + u.Username + ' Active=' + u.IsActive);
u.IsActive = false;
update u;