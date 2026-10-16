<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>GZERO_New_Opportunity_Product</fullName>
        <description>GZERO: New Opportunity Product</description>
        <protected>false</protected>
        <recipients>
            <recipient>kines@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>kosslyn.ne@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>maciulis@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>oliveira@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>rech@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/GZERO_New_Opportunity</template>
    </alerts>
    <fieldUpdates>
        <fullName>Populate_Product_Name</fullName>
        <field>Product_Name__c</field>
        <formula>Product2.Name</formula>
        <name>Populate Product Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Populate Product Name</fullName>
        <actions>
            <name>Populate_Product_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Product2.Name</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
