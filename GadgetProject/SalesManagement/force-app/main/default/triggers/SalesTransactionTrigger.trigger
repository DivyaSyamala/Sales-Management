trigger SalesTransactionTrigger on Sales_Transaction__c (before insert, before update, after insert, after update) {

    // BEFORE logic - set Status__c
    if(Trigger.isBefore){
        for(Sales_Transaction__c st : Trigger.new) {
            if(st.Total_Amount__c != null && st.Total_Amount__c > 0) {
                st.Status__c = 'Completed';
            } else {
                st.Status__c = 'Pending';
            }
        }
    }

    // AFTER logic - check stock and send email
    if(Trigger.isAfter){
        if(Trigger.isInsert || Trigger.isUpdate){
            SalesTransactionHandler.handleLowStockAlert(Trigger.new);
        }
    }
}
