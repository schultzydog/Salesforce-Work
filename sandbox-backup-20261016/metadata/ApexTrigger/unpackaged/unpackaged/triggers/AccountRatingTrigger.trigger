trigger AccountRatingTrigger on Account (before insert, before update) {
    for (Account a: Trigger.new){
        if(a.AnnualRevenue >= 1000000){
			a.Rating = 'hot';
        }else if(a.AnnualRevenue >= 500000){
            a.Rating = 'warm';
        }else if(a.AnnualRevenue < 500000){
            a.Rating = 'cool';
        }else{
            a.Rating = 'cool';
        }
    }
}