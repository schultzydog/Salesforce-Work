<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Notify_of_Account_Disablement</fullName>
        <description>Notify of Account Disablement</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Account_has_been_disabled</template>
    </alerts>
    <alerts>
        <fullName>Notify_on_Account_Owner_Change</fullName>
        <ccEmails>accountsreceivable@eurasiagroup.net</ccEmails>
        <description>Notify on Account Owner Change</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>unfiled$public/Notify_on_Account_Owner_Change</template>
    </alerts>
    <alerts>
        <fullName>OOM_Alert_Clients_300k</fullName>
        <description>OOM Alert: Clients &gt; 300k</description>
        <protected>false</protected>
        <recipients>
            <recipient>borne@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>kar.ne@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>nelson.ne@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>oliveira@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>tavares@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>salesops@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/OOM_Alert_Clients_300k</template>
    </alerts>
</Workflow>
