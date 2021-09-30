public without sharing class RewardsExpirationScheduler implements Schedulable {

    public static String schedule = '0 8 12 ? * *'; // Every day at 12:08pm

    public static String run() {
        RewardsExpirationScheduler res = new RewardsExpirationScheduler(); 
        return System.schedule('Rewards Expiration Batch Updater', schedule, res);
    }

    public void execute(SchedulableContext context) {
        RewardsExpirationBatchUpdater rebu = new RewardsExpirationBatchUpdater();
        Id batchProcessId = Database.executeBatch(rebu, 50);
    }

}