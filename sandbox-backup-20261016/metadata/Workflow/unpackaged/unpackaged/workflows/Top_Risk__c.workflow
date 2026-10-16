<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Top_Risk_notify_on_draft</fullName>
        <description>Top Risk: notify on draft</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Top_Risk_notify_end_user</template>
    </alerts>
    <alerts>
        <fullName>Top_Risk_notify_on_submission</fullName>
        <description>Top Risk: notify on submission</description>
        <protected>false</protected>
        <recipients>
            <recipient>strauss@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>thompson@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <field>Lead_analyst_POC__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Top_Risk_notify_Top_Risk_admins</template>
    </alerts>
</Workflow>
