import { LightningElement } from 'lwc';

export default class DataTablePractice extends LightningElement {
    columns = [
        { label: 'Name', fieldName: 'name' },
        { label: 'Email', fieldName: 'email' },
        { label: 'Phone', fieldName: 'phone' },
        { label: 'Company', fieldName: 'company' },
    ];
    data = [
        { name: 'John Doe', email: 'john.doe@example.com', phone: '1234567890', company: 'ABC Inc' },
        { name: 'Jane Smith', email: 'jane.smith@example.com', phone: '0987654321', company: 'XYZ Corp' },
    ];
}