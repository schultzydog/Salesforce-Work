/*
* Test class for PostSandboxRefreshScript
*/
@istest
private class PostSandboxRefreshScriptTest {
    @isTest
    static void testMySandboxPrep() {
        // Insert logic here to create records of the objects that the class you’re testing
        // manipulates.
        Test.startTest();
        //Execute test script with RunAsAutoProcUser set to true
        Test.testSandboxPostCopyScript(
            new PostSandboxRefreshScript(), UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), UserInfo.getOrganizationName(), true);
        Test.stopTest();
        // Insert assert statements here to check that the records you created above have
        // the values you expect.
    }
}