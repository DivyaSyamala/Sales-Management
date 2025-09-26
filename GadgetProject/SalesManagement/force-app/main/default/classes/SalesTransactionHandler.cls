public with sharing class SalesTransactionHandler {

    // 1️⃣ Update Status based on Payment Type
    public static void updateStatus(List<Sales_Transaction__c> transactions) {
        for(Sales_Transaction__c st : transactions) {
            if(st.Payment_Type__c == 'Cash') {
                st.Status__c = 'Completed';
            } else if(st.Payment_Type__c == 'UPI' && st.UPI_ID__c != null) {
                st.Status__c = 'Completed';
            } else if(st.Payment_Type__c == 'Card' && st.Card_Number__c != null) {
                st.Status__c = 'Completed';
            } else if(st.Payment_Type__c == 'Cheque' && st.Cheque_Number__c != null) {
                st.Status__c = 'Pending';
            } else {
                st.Status__c = 'Initiated';
            }
        }
    }

    // 2️⃣ Send Payment Email to Buyer
    public static void sendPaymentEmails(List<Sales_Transaction__c> newList, Map<Id, Sales_Transaction__c> oldMap) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        for(Sales_Transaction__c st : newList) {
            Sales_Transaction__c oldSt = oldMap != null ? oldMap.get(st.Id) : null;
            Boolean isCompleted = st.Status__c == 'Completed';
            Boolean justCompleted = oldSt == null ? isCompleted : (isCompleted && oldSt.Status__c != 'Completed');
            
            if(justCompleted && st.Buyer_Contact__c != null) {
                Contact buyer = [SELECT Email, FirstName FROM Contact WHERE Id = :st.Buyer_Contact__c LIMIT 1];
                
                if(buyer.Email != null) {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[] {buyer.Email});
                    mail.setSubject('Payment Confirmation for Order: ' + st.Name);
                    mail.setPlainTextBody(
                        'Hello ' + buyer.FirstName + ',\n\n' +
                        'Your payment for the order ' + st.Name + ' has been successfully completed.\n\n' +
                        'Order Details:\n' +
                        '- Gadget: ' + (st.Gadget__r != null ? st.Gadget__r.Name : '') + '\n' +
                        '- Quantity: ' + st.Quantity__c + '\n' +
                        '- Total Amount: ' + st.Total_Amount__c + '\n\n' +
                        'Thank you for your purchase!\nSales Team'
                    );
                    emailsToSend.add(mail);
                }
            }
        }
        
        if(!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }

    // 3️⃣ Low Stock Alert for Manager
    public static void handleLowStockAlert(List<Sales_Transaction__c> newTransactions) {
        Set<Id> gadgetIds = new Set<Id>();

        for(Sales_Transaction__c st : newTransactions) {
            if(st.Gadget__c != null) {
                gadgetIds.add(st.Gadget__c);
            }
        }

        if(gadgetIds.isEmpty()) return;

        List<Gadget__c> gadgets = [
            SELECT Id, Name, Stock_Quantity__c
            FROM Gadget__c
            WHERE Id IN :gadgetIds
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for(Gadget__c g : gadgets) {
            if(g.Stock_Quantity__c < 5) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { 'salesmanager@company.com' }); // Replace with actual manager email
                mail.setSubject('Low Stock Alert: ' + g.Name);
                mail.setPlainTextBody(
                    'Stock for gadget "' + g.Name + '" is low. Only ' + g.Stock_Quantity__c + ' left in inventory.'
                );
                emails.add(mail);
            }
        }

        if(!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}
