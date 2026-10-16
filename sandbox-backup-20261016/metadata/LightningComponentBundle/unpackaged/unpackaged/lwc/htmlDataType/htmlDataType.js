import { LightningElement,api } from 'lwc';

export default class HtmlDataType extends LightningElement {
    @api value;
    renderedCallback() {
        let _htmlValue  = '-';
        if(this.value){
            _htmlValue  = this.value;
        }
        this.template.querySelector('div').innerHTML = _htmlValue;
    }
}