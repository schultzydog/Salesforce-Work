Id ownerId = UserInfo.getUserId();

List<Event> events = new List<Event>{
    new Event(
        Subject = 'Test: Client check-in',
        Type = 'Meeting',
        StartDateTime = Datetime.now().addHours(2),
        EndDateTime = Datetime.now().addHours(3),
        OwnerId = ownerId
    ),
    new Event(
        Subject = 'Test: Project sync',
        Type = 'Meeting',
        StartDateTime = Datetime.now().addDays(-1),
        EndDateTime = Datetime.now().addDays(-1).addMinutes(45),
        OwnerId = ownerId
    ),
    new Event(
        Subject = 'Test: Internal planning',
        StartDateTime = Datetime.now().addDays(3),
        EndDateTime = Datetime.now().addDays(3).addHours(1),
        OwnerId = ownerId
    )
};
insert events;

List<Task> emails = new List<Task>{
    new Task(
        Subject = 'Test: Follow-up email',
        Type = 'Email',
        TaskSubtype = 'Email',
        Status = 'Completed',
        ActivityDate = Date.today(),
        OwnerId = ownerId
    ),
    new Task(
        Subject = 'Test: Intro email',
        Type = 'Email',
        TaskSubtype = 'Email',
        Status = 'Completed',
        ActivityDate = Date.today().addDays(-2),
        OwnerId = ownerId
    )
};
insert emails;

System.debug('Created events: ' + events);
System.debug('Created emails: ' + emails);
