<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>GLOMA_weekend_email</fullName>
        <description>GLOMA weekend email</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderAddress>gmateam@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/GLOMA_weekend_email</template>
    </alerts>
    <alerts>
        <fullName>Notify_Account_Owner_of_Contact_Email_Disablement</fullName>
        <description>Email Hard Bounce - Notify Account Owner of Contact Email Disablement</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderAddress>salesops@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Notify_of_Contact_Email_Access_Disablement</template>
    </alerts>
    <alerts>
        <fullName>Notify_Account_Owner_of_Contact_Email_Opt_Out</fullName>
        <description>Notify Account Owner of Contact Email Opt Out</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderAddress>salesops@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Worldflow_Email_Opt_Out</template>
    </alerts>
    <alerts>
        <fullName>Notify_Account_Owner_of_New_Contact</fullName>
        <description>Notify Account Owner of New Contact</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/New_Contact_from_Lead_conversion</template>
    </alerts>
    <alerts>
        <fullName>Notify_Contacts_for_EG_In_Media</fullName>
        <description>Notify Contacts for EG In Media</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/EG_in_the_Media</template>
    </alerts>
    <alerts>
        <fullName>Notify_on_Aggregator_Subscriber_Disablement</fullName>
        <description>Notify on Aggregator Subscriber Disablement</description>
        <protected>false</protected>
        <recipients>
            <recipient>albuquerque@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>detmer@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>talmeida@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>unfiled$public/Aggregator_Subscriber_Disabled</template>
    </alerts>
    <alerts>
        <fullName>Notify_on_EG_employee_insert</fullName>
        <description>Notify on EG employee insert</description>
        <protected>false</protected>
        <recipients>
            <recipient>wehrmann@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>salesops@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Notify_On_EG_ee_insert</template>
    </alerts>
    <alerts>
        <fullName>Notify_on_New_Contact_created_by_Rippling_integration</fullName>
        <description>Notify on New Contact created by Rippling integration</description>
        <protected>false</protected>
        <recipients>
            <recipient>schultz@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/New_Contact_created_by_Rippling_integration</template>
    </alerts>
    <alerts>
        <fullName>Risk_Dashboard_note_to_Two_Sigma</fullName>
        <description>Risk Dashboard - note to Two Sigma</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderAddress>consonery@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/RIsk_Dashboard_Two_Sigma</template>
    </alerts>
    <alerts>
        <fullName>Risk_Dashboard_note_to_not_Two_Sigma</fullName>
        <ccEmails>tavares@eurasiagroup.net</ccEmails>
        <ccEmails>trigo@eurasiagroup.net</ccEmails>
        <description>Risk Dashboard - note to not Two Sigma</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderAddress>nickolova@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Risk_Dashboard_NOT_Two_Sigma</template>
    </alerts>
</Workflow>
