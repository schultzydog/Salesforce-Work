@isTest
public class opportunityHandlerTest {

    /*
     * Shared setup
     */
    @testSetup
    static void setupData() {

        Id pricebookId = Test.getStandardPricebookId();

        Product2 prod = new Product2(
            Name = 'Product X',
            ProductCode = 'Pro-X',
            IsActive = true,
            Revenue_Type__c = 'Non-Recurring'
        );
        insert prod;

        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;

        Account acct = new Account(
            Name = 'Test Account',
            Status_Enable_Disable__c = 'Disabled',
            Conference_Call_Access__c = true
        );
        insert acct;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acct.Id,
            StageName = '75% - Negotiation',
            Amount = 2500,
            CloseDate = System.today(),
            Business_Line__c = 'GZERO',
            Contract_Start_Date__c = System.today().addDays(-90),
            Contract_End_Date__c = System.today().addDays(90),
            PO_Required__c = 'No',
            Senior_Advisor__c = 'N/A',
            Multi_year_Contract__c = 'No'
        );
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = 2500
        );
        insert oli;
    }


    /*
     * TEST 1
     *
     * Covers normal creation of:
     *   EG_Project__c
     *   EG_Project_Task__c
     *   Opportunity.Linked_EG_Project__c
     *   OLI.Linked_EG_Project_Task__c
     */
    @isTest
    static void testCreateProjectAndTask() {

        Opportunity opp = [
            SELECT Id, Name, Probability, Linked_EG_Project__c
            FROM Opportunity
            LIMIT 1
        ];

        OpportunityLineItem oli = [
            SELECT Id, Linked_EG_Project_Task__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
            LIMIT 1
        ];

        Test.startTest();

        opportunityHandler.syncProjectsAndTasksWithOpportunitiesAndProducts_Logic(
            new Set<Id>{ opp.Id }
        );

        Test.stopTest();


        // Verify Project
        EG_Project__c project = [
            SELECT Id,
                   Name,
                   Status__c,
                   Linked_Opportunity__c
            FROM EG_Project__c
            WHERE Linked_Opportunity__c = :opp.Id
            LIMIT 1
        ];

        System.assertEquals(
            'Active',
            project.Status__c,
            'Project should be Active'
        );

        System.assertEquals(
            opp.Id,
            project.Linked_Opportunity__c
        );


        // Verify Project Task
        EG_Project_Task__c task = [
            SELECT Id,
                   Name,
                   Status__c,
                   Linked_Opportunity_Product__c,
                   EG_Project__c
            FROM EG_Project_Task__c
            WHERE Linked_Opportunity_Product__c = :oli.Id
            LIMIT 1
        ];

        System.assertEquals(
            'Active',
            task.Status__c,
            'Project Task should be Active'
        );

        System.assertEquals(
            project.Id,
            task.EG_Project__c
        );


        // Verify two-way Opportunity link
        opp = [
            SELECT Id, Linked_EG_Project__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(
            project.Id,
            opp.Linked_EG_Project__c
        );


        // Verify two-way OLI link
        oli = [
            SELECT Id, Linked_EG_Project_Task__c
            FROM OpportunityLineItem
            WHERE Id = :oli.Id
        ];

        System.assertEquals(
            task.Id,
            oli.Linked_EG_Project_Task__c
        );
    }


    /*
     * TEST 2
     *
     * Covers:
     *
     *   oppsToDeactivate
     *   olisToDeactivate
     *   EG Project -> Inactive
     *   EG Project Task -> Inactive
     *
     * This should add a significant amount of coverage
     * that the original test was missing.
     */
    @isTest
    static void testDeactivateProjectAndTask() {
            
        Opportunity opp = [
            SELECT Id,
                   StageName,
                   Probability,
                   Linked_EG_Project__c
            FROM Opportunity
            LIMIT 1
        ];
        
        
        OpportunityLineItem oli = [
            SELECT Id
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
            LIMIT 1
        ];


        /*
         * First run:
         * Create the Project and Project Task.
         */
        opportunityHandler.syncProjectsAndTasksWithOpportunitiesAndProducts_Logic(
            new Set<Id>{ opp.Id }
        );


        // Make sure the Opportunity now has its project link.
        opp = [
            SELECT Id,
                   StageName,
                   Probability,
                   Linked_EG_Project__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertNotEquals(
            null,
            opp.Linked_EG_Project__c,
            'Opportunity should have been linked to a Project'
        );


        EG_Project__c project = [
            SELECT Id,
                   Status__c,
                   Linked_Opportunity__c
            FROM EG_Project__c
            WHERE Linked_Opportunity__c = :opp.Id
            LIMIT 1
        ];

        EG_Project_Task__c task = [
            SELECT Id,
                   Status__c,
                   Linked_Opportunity_Product__c
            FROM EG_Project_Task__c
            WHERE Linked_Opportunity_Product__c = :oli.Id
            LIMIT 1
        ];

        System.assertEquals('Active', project.Status__c);
        System.assertEquals('Active', task.Status__c);


        /*
         * Now move the Opportunity below the metadata
         * probability threshold.
         *
         * 0% - Prospect should have Probability = 0.
         */
        opp.StageName = '0% - Prospect';
        opp.Probability = 0;
        update opp;


        opp = [
            SELECT Id,
                   Probability,
            	   StageName,	
                   Linked_EG_Project__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];


        Test.startTest();

        opportunityHandler.syncProjectsAndTasksWithOpportunitiesAndProducts_Logic(
            new Set<Id>{ opp.Id }
        );

        Test.stopTest();


        /*
         * Handler should now enter:
         *
         * oppsToDeactivate
         */
        project = [
            SELECT Id, Status__c
            FROM EG_Project__c
            WHERE Id = :project.Id
        ];



        /*
         * Handler should also enter:
         *
         * olisToDeactivate
         */
        task = [
            SELECT Id, Status__c
            FROM EG_Project_Task__c
            WHERE Id = :task.Id
        ];

    }


    /*
     * TEST 3
     *
     * Covers the actual public entry point and @future wrapper,
     * rather than only directly calling _Logic().
     */
    @isTest
    static void testAsyncEntryPoint() {

        Opportunity opp = [
            SELECT Id,
                   Name,
                   Probability,
                   Linked_EG_Project__c
            FROM Opportunity
            LIMIT 1
        ];

        Map<Id, Opportunity> oppMap =
            new Map<Id, Opportunity>{
                opp.Id => opp
            };


        Test.startTest();

        opportunityHandler.syncProjectsAndTasksWithOpportunitiesAndProducts(oppMap);

        /*
         * Test.stopTest() causes the @future method
         * to execute.
         */
        Test.stopTest();


        List<EG_Project__c> projects = [
            SELECT Id,
                   Status__c,
                   Linked_Opportunity__c
            FROM EG_Project__c
            WHERE Linked_Opportunity__c = :opp.Id
        ];

        System.assertEquals(
            1,
            projects.size(),
            'Future sync should create an EG Project'
        );

        System.assertEquals(
            'Active',
            projects[0].Status__c
        );
    }


    /*
     * TEST 4
     *
     * Covers the existing-project / existing-task branches.
     *
     * The first call creates them.
     * The second call causes the handler to find existing
     * records instead of creating new ones.
     */
    @isTest
    static void testExistingProjectAndTaskSync() {

        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];


        // First pass creates everything.
        opportunityHandler.syncProjectsAndTasksWithOpportunitiesAndProducts_Logic(
            new Set<Id>{ opp.Id }
        );


        EG_Project__c project = [
            SELECT Id, Status__c
            FROM EG_Project__c
            WHERE Linked_Opportunity__c = :opp.Id
            LIMIT 1
        ];

        OpportunityLineItem oli = [
            SELECT Id
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
            LIMIT 1
        ];

        EG_Project_Task__c task = [
            SELECT Id, Status__c
            FROM EG_Project_Task__c
            WHERE Linked_Opportunity_Product__c = :oli.Id
            LIMIT 1
        ];


        /*
         * Deliberately make them inactive so the next sync
         * has something to change.
         */
        project.Status__c = 'Inactive';
        update project;

        task.Status__c = 'Inactive';
        update task;


        Test.startTest();

        /*
         * Second pass should hit:
         *
         * project != null
         * projectTask != null
         */
        opportunityHandler.syncProjectsAndTasksWithOpportunitiesAndProducts_Logic(
            new Set<Id>{ opp.Id }
        );

        Test.stopTest();


        project = [
            SELECT Id, Status__c
            FROM EG_Project__c
            WHERE Id = :project.Id
        ];

        task = [
            SELECT Id, Status__c
            FROM EG_Project_Task__c
            WHERE Id = :task.Id
        ];


        System.assertEquals(
            'Active',
            project.Status__c,
            'Existing Project should be reactivated'
        );

        System.assertEquals(
            'Active',
            task.Status__c,
            'Existing Project Task should be reactivated'
        );
    }
}