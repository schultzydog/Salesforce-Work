import { LightningElement,api, wire,track } from 'lwc';
import getSearchParams from '@salesforce/apex/WorldFlow_SearchController.getSearchParams';
import search from '@salesforce/apex/WorldFlow_SearchController.search';
import getResearchFile from '@salesforce/apex/WorldFlow_SearchController.getResearchFile';
import { NavigationMixin,CurrentPageReference } from 'lightning/navigation';

//Remove ClientPortal, FontAwesomePro, loadStyle in the final version - only testing with internal user
import ClientPortal from '@salesforce/resourceUrl/ClientPortal';
import FontAwesomePro from '@salesforce/resourceUrl/FontAwesomePro';
import { loadStyle } from 'lightning/platformResourceLoader';


export default class WorldFlow_Search extends NavigationMixin(LightningElement) {

    searchParams;
    //authors = [];
    showWait = true;

    @track
    searchResults;
    selectedParams;
    regionParams;
    currentPage = 0;

    /* For Search Parameteres */
    expandRegion = false;
    expandTopic = false;
    expandAuthor = false;
    isMoreSearchWorking = false;


    hasRendered = false;
    //Rendered Callback
    renderedCallback() {
        if (!this.hasRendered) {
            this.hasRendered = true;
            loadStyle(this, FontAwesomePro + '/css/all.css')
        }
    } //end renderedCallback


    get regionBtnClass(){
        return 'fad fa-lite fa-' + (this.expandRegion ? 'minus' : 'plus');
    }

    get topicBtnClass(){
        return 'fad fa-lite fa-' + (this.expandTopic ? 'minus' : 'plus');
    }

    get authorBtnClass(){
        return 'fad fa-lite fa-' + (this.expandAuthor ? 'minus' : 'plus');
    }

    get authorMenuCls(){
        return 'filter-box' + (this.expandAuthor ? ' open' : '');
    }

    get authorMenuIconCls(){
        return 'fad' + (this.expandAuthor ? '  fa-minus' : ' fa-plus');
    }

    get authorSubMenuCls(){
        return 'filter-box-sub-menu' + (this.expandAuthor ? ' open' : '');
    }
    get topicMenuCls(){
        return 'filter-box' + (this.expandTopic ? ' open' : '');
    }

    get topicSubMenuCls(){
        return 'filter-box-sub-menu' + (this.expandTopic ? ' open' : '');
    }

    get topicMenuIconCls(){
        return 'fad' + (this.expandTopic ? '  fa-minus' : ' fa-plus');
    }

    get regionMenuCls(){
        return 'filter-box' + (this.expandRegion ? ' open' : '');
    }

    get regionSubMenuCls(){
        return 'region filter-box-sub-menu' + (this.expandRegion ? ' open' : '');
    }

    get regionMenuIconCls(){
        return 'fad' + (this.expandRegion ? '  fa-minus' : ' fa-plus');
    }



    @wire(CurrentPageReference)
    pageRef;
    

    handleExpand(event){
        //console.dir(event.target.dataset.name);
        switch(event.target.dataset.name){
            case 'region':
                this.expandRegion = !this.expandRegion;
                break;
            case 'topic':
                this.expandTopic = !this.expandTopic;
                break;
            case 'author':
                this.expandAuthor = !this.expandAuthor;
                break;

        }
    }




    @wire(getSearchParams)
    wiredSearchParam({ error, data }) {
        if (data) {
            this.searchParams = data;
           // console.dir(JSON.stringify(data));
            this.parseSearchParam();
            this.doSearch(true);
            //this.showWait = false;
        } else if (error) {
            
            console.dir(JSON.stringify(error));
            this.showWait = false;
        }
    }
/*
    //Remove Rendered Call back and initComponent in the final version - only testing with internal user
    hasRendered = false;
    renderedCallback() {
        if (!this.hasRendered) {
            this.hasRendered = true;
            this.initComponent();
        }
    } //end renderedCallback

    //Initialize Component
    initComponent = async () => {

        loadStyle(this, FontAwesomePro + '/css/all.css')
    }

    */

    //Parse Search Parameters
    parseSearchParam(){
        if(this.searchParams){
            /*this.searchParams.researchDocumentSearchParameters.analysts.forEach(element => {
                this.authors.push({
                    'name': element.firstName + ' ' + element.lastName
                    , 'code': element.code
                });
            });*/

            //Handle Collapse/Expand for Regions
            let _regions =[];
            this.searchParams.researchDocumentSearchParameters.regions.forEach(region => {
                let _hasActiveCountry = false;
                if(region.countries){
                    region.countries.forEach( country =>{
                        if(country.inactive){
                            _hasActiveCountry = true;
                        }
                    });
                }
                if(_hasActiveCountry){
                    _regions.push({
                            countries:region.countries
                            , description : region.description
                            , code : region.code
                            , expand :true
                            , regionCls :'subfilter-box-sub-menu open'
                    });
                }
            });
            this.regionParams = {regions:_regions, isChange:false};
        }
    }

    handleRegionToggle(event){
        const _code = event.target.dataset.code;
       /* this.regionParams.regions.forEach(region => {
            if(region.code == _code){
                region.expand = !region.expand;
                region.regionCls = 'subfilter-box-sub-menu' + (region.expand ? ' open': '');
            }
        });*/
        //this.regionParams.isChange = !this.regionParams.isChange ;
        /*let _region = this.regionParams;
        this.regionParams = [];
        this.regionParams = this.regionParams.concat(_region);*/
        const _class = this.template.querySelector("div.region div[name='" + _code + "']").getAttribute('class');
        this.template.querySelector("div.region div[name='" + _code + "']").setAttribute('class', (_class == 'subfilter-box-sub-menu' ? 'subfilter-box-sub-menu open' : 'subfilter-box-sub-menu'));
    }



    //Handle Search 
    handleSearch(event){
        this.doSearch(true);
    }

    handleInputKey(event){
        if(event.key == "Enter"){
            this.doSearch(true);
        }
    }


    //Download PDF file
    downloadResearch(event){
        //console.dir(JSON.stringify(event.target.dataset));
        let _documentCode = event.target.dataset.code;
        let _fileName = event.target.dataset.file;
        this.showWait = true;
        event.stopPropagation();
        getResearchFile({
            documentCode: _documentCode
        })
        .then((result)=>{
           // console.dir(JSON.stringify(result));
            this.showWait = false;
            var strFile = "data:application/pdf;base64,"+result;
            window.open(strFile, _fileName, "application/pdf");
        })
        .catch((error)=>{
            console.dir(JSON.stringify(error));
            this.showWait = false;
        })
    }

    //Handle Load More 
    handleScroll(event) {
        if(!this.isMoreSearchWorking){
            let area = this.template.querySelector('.scrollArea');
            let threshold = 2 * event.target.clientHeight;
            let areaHeight = area.clientHeight;
            let scrollTop = event.target.scrollTop;
            if(areaHeight - threshold < scrollTop) {
                if(this.searchResults && this.searchParams && this.searchResults.taggedSearchDTO.documentSize > this.currentPage ){
                    this.isMoreSearchWorking = true;
                    this.doSearch(false);
                }
            }
        }
    }


    //Search Results
    doSearch(refreshParam){
        //selectedParams
        //If this is a new search
        if(refreshParam){
            let _keyword;
            let _tags = [];
            let _authors=[];
            let _regions=[];
            let _countries=[];
            this.template
            .querySelectorAll('lightning-input')
            .forEach((element) =>{
                let _dataType = element.getAttribute('data-type');
                let _dataCode= element.getAttribute('data-code');
                if(_dataType == 'search'){
                    _keyword = element.value;
                }else if(element.checked){
                    if(_dataType == 'region'){
                        _regions.push(_dataCode);
                    }else if(_dataType == 'country'){
                        _countries.push(_dataCode);
                    }else if(_dataType == 'author'){
                        _authors.push(_dataCode);
                    }else if(_dataType == 'tag'){
                        _tags.push(_dataCode);
                    }
                }
            });
            this.searchResults = {
                taggedSearchDTO: { documents : []}
            };

            this.selectedParams = {
                'keywords' : _keyword
                , 'tags' :_tags
                ,'authors' : _authors
                , 'region' : _regions
                , 'country' : _countries
            };
            this.currentPage = 0;
        }
        this.showWait = true;
        search({
            searchTxt: this.selectedParams.keywords,
            regionCode: this.selectedParams._regions,
            countryCode : this.selectedParams.country,
            tagCode: this.selectedParams.tags,
            analystCode : this.selectedParams.authors,
            batchSize : 25,
            index : this.currentPage,
            dateRange : 'AllDates'
        })
        .then((result)=>{

            if(refreshParam){
                this.searchResults = result;
                this.currentPage = this.searchResults.taggedSearchDTO.documents.length;
            }else{
              
                let _result = this.searchResults.taggedSearchDTO.documents;//result.taggedSearchDTO.documents;
                _result = _result.concat(result.taggedSearchDTO.documents);
                this.searchResults.taggedSearchDTO.documents = _result;//this.searchResults.taggedSearchDTO.documents.concat(result.taggedSearchDTO.documents);
                this.currentPage += 50;
            }
            this.parseSearchResult();

            this.isMoreSearchWorking = false;
            
            console.dir(JSON.stringify(result));
            this.showWait = false;
        })
        .catch((error)=>{
            console.dir(JSON.stringify(error));
            this.showWait = false;
        })
    }  
    
    
    parseSearchResult(){
        this.searchResults.taggedSearchDTO.documents.forEach((doc)=>{
            //doc.docUrl = 'worldflowsearch/worldflowarticle?code=' +  doc.code;
            doc.docUrl = '/apex/worldflow_Research?type=html&code=' +  doc.code;
            if(doc.filename.includes(".html") == false){
                doc.docUrl = '/apex/worldflow_Research?type=download&code=' +  doc.code;
            }
            doc.pdfUrl = '/apex/worldflow_Research?type=download&code=' +  doc.code;
        });
    }
    

    
    

    handleReset(event){
       /* this[NavigationMixin.GenerateUrl](this.pageRef)
        .then((url) => {
            window.href = url;
        });*/

        window.location.reload();
            
            /*{
            type: 'standard__component',
            attributes: {
                componentName: 'worldFlow_Search'
            },
        });*/
    }

}