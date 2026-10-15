User u = [SELECT Id, IsActive FROM User WHERE Id = '005WL00000kLRE2YAO'];
u.IsActive = true;
update u;
System.setPassword('005WL00000kLRE2YAO', 'OutlookPanel2026!x');
System.debug('Reactivated and password set');