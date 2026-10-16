global class egTimeCardGenerationSched implements Schedulable {
	global void execute(SchedulableContext sc) {
		egTimeCardGenerationBatch b = new egTimeCardGenerationBatch();
		database.executebatch(b);
	}
}