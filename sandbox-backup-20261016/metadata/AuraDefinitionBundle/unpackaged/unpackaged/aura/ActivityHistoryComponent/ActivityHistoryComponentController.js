({
    doInit : function(component,event,helper){
        // Setting column information.To make a column sortable,set sortable as true on component load
        component.set("v.columns",[
            {
                label : 'Subject',
                fieldName : 'subjectLink',
                type : 'url',
                sortable : true,
                sortBy : 'subject',
                typeAttributes: {label: { fieldName: 'subject' }, target: '_self'}
            },
            {
                label : 'Name',
                fieldName : 'whonameLink',
                type : 'url',
                sortable : true,
                sortBy : 'whoname',
                typeAttributes: {label: { fieldName: 'whoname' }, target: '_self'}
            },
            {
                label : 'Date',
                fieldName : 'activityDate',
                type : 'date',
                sortable : true,
                sortBy : 'activityDate'
            },
            {
                label : 'Assigned To',
                fieldName : 'ownernameLink',
                type : 'url',
                sortable : true,
                sortBy : 'ownername',
                typeAttributes: {label: { fieldName: 'ownername' }, target: '_self'}
            }
        ]);
        // call helper function to fetch account data from apex
        helper.getData(component);
    },
    
    //Method gets called by onsort action,
    handleSort : function(component,event,helper){
        //Returns the field which has to be sorted
        console.log(event);
        var sortBy = event.getParam("fieldName");
        //returns the direction of sorting like asc or desc
        var sortDirection = event.getParam("sortDirection");
        //Set the sortBy and SortDirection attributes
        component.set("v.sortBy",sortBy);
        component.set("v.sortDirection",sortDirection);
        // call sortData helper function
        sortBy = sortBy.replace("Link", "");
        console.log(sortBy);
        helper.sortData(component,sortBy,sortDirection);
    }
})