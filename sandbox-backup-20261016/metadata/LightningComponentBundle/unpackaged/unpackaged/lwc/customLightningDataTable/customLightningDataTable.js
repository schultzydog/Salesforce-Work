import LightningDatatable from 'lightning/datatable';
import htmlDataType from './htmlDataType';
import textDataType from './textDataType';
import dateDataType from './dateDataType';
export default class CustomLightningDataTable extends LightningDatatable {
    static customTypes = {
        htmlDataType: {
            template: htmlDataType
        }
        ,textDataType:{
            template : textDataType
        }
        ,dateDataType:{
            template : dateDataType
        }
    }
}