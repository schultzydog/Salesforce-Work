<BDSFEntityMapping>
<entityMap source="ContactWithFocusData" target="Contact">
<fieldMap source="FirstName" target="FirstName"/>
<fieldMap source="LastName" target="LastName"/>
<fieldMap source="Fax" target="Fax"/>
<fieldMap source="RoleName" target="Title"/>
<fieldMap source="Phone" target="Phone"/>
<fieldMap source="Biography" target="Description"/>
<fieldMap source="AddressZip" target="MailingPostalCode"/>
<fieldMap source="AddressCountry" target="MailingCountry"/>
<fieldMap source="AddressState" target="MailingState"/>
<fieldMap source="AddressCity" target="MailingCity"/>
<fieldMap mappingType="expression" source="{0} {1}" target="MailingStreet">
<expressionParameter source="AddressLine1"/>
<expressionParameter source="AddressLine2"/>
</fieldMap>
</entityMap>
<entityMap source="Contact411Data" target="Contact">
<fieldMap source="FirstName" target="FirstName"/>
<fieldMap source="LastName" target="LastName"/>
<fieldMap source="Fax" target="Fax"/>
<fieldMap source="RoleName" target="Title"/>
<fieldMap source="Phone" target="Phone"/>
<fieldMap source="AddressZip" target="MailingPostalCode"/>
<fieldMap source="AddressCountry" target="MailingCountry"/>
<fieldMap source="AddressState" target="MailingState"/>
<fieldMap source="AddressCity" target="MailingCity"/>
<fieldMap mappingType="expression" source="{0} {1}" target="MailingStreet">
<expressionParameter source="AddressLine1"/>
<expressionParameter source="AddressLine2"/>
</fieldMap>
</entityMap>
<entityMap source="ContactWithFocusData" target="Lead">
<fieldMap source="FirstName" target="FirstName"/>
<fieldMap source="LastName" target="LastName"/>
<fieldMap source="Company.Name" target="Company"/>
<fieldMap source="Company.Website" target="Website"/>
<fieldMap source="Fax" target="Fax"/>
<fieldMap source="RoleName" target="Title"/>
<fieldMap source="Phone" target="Phone"/>
<fieldMap source="Biography" target="Description"/>
<fieldMap source="AddressZip" target="PostalCode"/>
<fieldMap source="AddressCountry" target="Country"/>
<fieldMap source="AddressState" target="State"/>
<fieldMap source="AddressCity" target="City"/>
<fieldMap mappingType="expression" source="{0} {1}" target="Street">
<expressionParameter source="AddressLine1"/>
<expressionParameter source="AddressLine2"/>
</fieldMap>
</entityMap>
<entityMap source="CompanyWithFocusData" target="Account">
<fieldMap source="Name" target="Name"/>
<fieldMap source="Fax" target="Fax"/>
<fieldMap source="Phone" target="Phone"/>
<fieldMap source="Website" target="Website"/>
<fieldMap source="Overview" target="Description"/>
<fieldMap source="AddressCity" target="ShippingCity"/>
<fieldMap source="AddressCountry" target="ShippingCountry"/>
<fieldMap source="AddressState" target="ShippingState"/>
<fieldMap source="AddressZip" target="ShippingPostalCode"/>
<fieldMap mappingType="expression" source="{0} {1}" target="ShippingStreet">
<expressionParameter source="AddressLine1"/>
<expressionParameter source="AddressLine2"/>
</fieldMap>
</entityMap>
<entityMap source="Company411Data" target="Account">
<fieldMap source="Name" target="Name"/>
<fieldMap source="Fax" target="Fax"/>
<fieldMap source="Phone" target="Phone"/>
<fieldMap source="Website" target="Website"/>
<fieldMap source="AddressCity" target="ShippingCity"/>
<fieldMap source="AddressCountry" target="ShippingCountry"/>
<fieldMap source="AddressState" target="ShippingState"/>
<fieldMap source="AddressZip" target="ShippingPostalCode"/>
<fieldMap mappingType="expression" source="{0} {1}" target="ShippingStreet">
<expressionParameter source="AddressLine1"/>
<expressionParameter source="AddressLine2"/>
</fieldMap>
</entityMap>
<entityMap source="CompanyWithFocusData" target="Lead">
<fieldMap source="Name" target="LastName"/>
<fieldMap source="Name" target="Company"/>
<fieldMap source="Fax" target="Fax"/>
<fieldMap source="Phone" target="Phone"/>
<fieldMap source="Website" target="Website"/>
<fieldMap source="Overview" target="Description"/>
<fieldMap source="AddressCity" target="City"/>
<fieldMap source="AddressCountry" target="Country"/>
<fieldMap source="AddressState" target="State"/>
<fieldMap source="AddressZip" target="PostalCode"/>
<fieldMap mappingType="expression" source="{0} {1}" target="Street">
<expressionParameter source="AddressLine1"/>
<expressionParameter source="AddressLine2"/>
</fieldMap>
</entityMap>
</BDSFEntityMapping>