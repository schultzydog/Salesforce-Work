({
    getData : function(component){
        //Load the data from apex
        var action = component.get("c.getActivityHistoryApex");
        var toastReference = $A.get("e.force:showToast");
        action.setParams({ recordId : component.get("v.recordId") });
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                var data = response.getReturnValue();
                data.forEach(function(record){
                    record.subjectLink = '/'+record.id;
                    record.whonameLink = '/'+record.whoid;
                    record.ownernameLink = '/'+record.ownerid;
                });
                component.set("v.data", data);                
                /*
                if(accountWrapper.success){
                    //Setting data to be displayed in table
                    component.set("v.accountData",accountWrapper.accountsList);
                    toastReference.setParams({
                        "type" : "Success",
                        "title" : "Success",
                        "message" : accountWrapper.message,
                        "mode" : "dismissible"
                    });
                } // handel server side erroes, display error msg from response 
                else{
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "Error",
                        "message" : accountWrapper.message,
                        "mode" : "sticky"
                    }); 
                }
                */
            } // handel callback error 
            else{
                toastReference.setParams({
                    "type" : "Error",
                    "title" : "Error",
                    "message" : 'An error occurred during initialization '+state,
                    "mode" : "sticky"
                });
	            toastReference.fire();
            }
            
        });
        $A.enqueueAction(action);
    },
    
    sortData : function(component,fieldName,sortDirection){
        var data = component.get("v.data");
        //function to return the value stored in the field
        var key = function(a) { return a[fieldName]; }
        var reverse = sortDirection == 'asc' ? 1: -1;
        
        // to handel number/currency type fields 
        if(fieldName == 'date'){ 
            data.sort(function(a,b){
                var a = key(a) ? key(a) : '';
                var b = key(b) ? key(b) : '';
                return reverse * ((a>b) - (b>a));
            }); 
        }
        else{// to handel text type fields 
            data.sort(function(a,b){ 
                var a = key(a) ? key(a).toLowerCase() : '';//To handle null values , uppercase records during sorting
                var b = key(b) ? key(b).toLowerCase() : '';
                return reverse * ((a>b) - (b>a));
            });    
        }
        //set sorted data to accountData attribute
        component.set("v.data",data);
    }
})