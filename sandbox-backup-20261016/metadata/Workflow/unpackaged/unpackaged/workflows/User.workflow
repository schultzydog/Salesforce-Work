<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Portal_Data_Dashboard_alert</fullName>
        <description>Portal Data Dashboard alert</description>
        <protected>false</protected>
        <recipients>
            <recipient>schultz@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>trigo@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Portal_Data</template>
    </alerts>
    <alerts>
        <fullName>User_has_been_frozen</fullName>
        <description>User has been frozen</description>
        <protected>false</protected>
        <recipients>
            <recipient>ausschultz04@gmail.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>schultz@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/User_is_Frozen</template>
    </alerts>
</Workflow>
