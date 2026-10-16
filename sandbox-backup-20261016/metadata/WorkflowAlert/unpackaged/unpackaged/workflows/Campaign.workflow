<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Alert_to_Admins_dep</fullName>
        <description>Alert to Admins dep</description>
        <protected>false</protected>
        <recipients>
            <recipient>adam@bolterra.com.eurasia</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>eurasia@jpwconsulting.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>wainschel@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/ALERT_New_SF_Library_Created</template>
    </alerts>
</Workflow>
