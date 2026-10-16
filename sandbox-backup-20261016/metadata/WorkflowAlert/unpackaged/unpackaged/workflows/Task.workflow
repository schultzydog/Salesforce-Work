<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Email_User_on_Portal_Task_Creation</fullName>
        <description>Email User on Portal Task Creation</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>Portal_Notifications/New_Task_Alert</template>
    </alerts>
    <alerts>
        <fullName>Notify_Account_Owner_of_Trial_Expiration</fullName>
        <description>Notify Account Owner of Trial Expiration</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>salesops@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Public_Templates/Task_Trial_Task_Assignment</template>
    </alerts>
</Workflow>
