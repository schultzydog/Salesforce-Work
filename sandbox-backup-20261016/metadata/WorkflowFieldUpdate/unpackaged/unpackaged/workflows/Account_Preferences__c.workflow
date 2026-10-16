<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Name_Update</fullName>
        <field>Name</field>
        <formula>IF(OR(ISNULL(Library__r.Distribution_List_SubCategory__r.Name),ISBLANK(Library__r.Distribution_List_SubCategory__r.Name)),
LEFT( Library__r.Name,80),
LEFT( Library__r.Distribution_List_SubCategory__r.Name  &amp; &quot; - &quot; &amp;  Library__r.Name,80) )</formula>
        <name>Name Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Populate_Account_Library_concat</fullName>
        <field>Account_Library_Concat__c</field>
        <formula>CASESAFEID(Account__c)  +  CASESAFEID(Library__c)</formula>
        <name>Populate Account Library concat</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
