/**
 * AngularJS promises - Remote Action controller
 */
global with sharing class NgAccountsRemoteCtrl {
    global PageReference goToContacts {get; private set;}
    global PageReference goToAccounts {get; private set;}
    global PageReference goToHomepage {get; private set;}

    static global String[] fieldsAccount = new String[] {
        'Id', 
        'Name', 
        'BillingStreet', 
        'NumberOfEmployees', 
        'AnnualRevenue', 
        'Industry' 
    };

    global NgAccountsRemoteCtrl() {
        System.debug('init: start');
        /*--- CONTACTS PAGE ---*/
        goToContacts = Page.NgContactsRemote;
        goToContacts.setRedirect(true);
        /*--- ACCOUNT PAGE ---*/
        goToAccounts = Page.NgAccountsRemote;
        goToAccounts.setRedirect(true);
        /*--- HOMEPAGE ---*/
        goToHomepage = new PageReference('https://eu11.salesforce.com/setup/forcecomHomepage.apexp?setupid=ForceCom');
        goToHomepage.setRedirect(true);
        System.debug('init: done');
    }
   
    //No Remote
    global static String getAccountListJSON() {
        List<InstanceWrapper> instance = new List<InstanceWrapper>();
        for (Account a : accounts()) {

            instance.add(new InstanceWrapper(a.Id, a.Name, a.BillingStreet, a.NumberOfEmployees, a.AnnualRevenue, a.Industry));

        }

        return JSON.serializePretty(instance);
    }
    
    @RemoteAction
    global static String findAll() {
        return JSON.serializePretty(accounts());
    }

    @RemoteAction
    global static String deleteById(String ID) {
        try {
            
            Account acc = Database.Query('SELECT ' + getObjectFields('Contact') + ' FROM Contact WHERE ID = \'' + ID + '\' LIMIT 1');
            System.debug('Deleting... ' + acc);
            delete acc;
            return findAll();

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occured during Deleting.');
            return null;
        }
    }

    @RemoteAction
    global static List<Account> updateAccount(String accountJSON) {
        try {
          
            Account acc = (Account) JSON.deserialize(accountJSON, Account.class);
            System.debug('Updating... ' + acc);
            update acc;
            return accounts();
          
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occured during Merge.');
            return null;
        }
    }

    @RemoteAction
    global static List<Account> getAllByFilter(String searchText) {
        String searchString = '%' + searchText + '%';
        try {
            return [SELECT Id,
                           Name,
                           BillingStreet,
                           NumberOfEmployees,
                           AnnualRevenue,
                           Industry
                    FROM Account
                    WHERE Name LIKE :searchString];

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occured during Fetch.');
            return null;
        }
    }

    //Utility class
    global class InstanceWrapper {

        String Id;
        String Name;
        String BillingStreet;
        Integer NumberOfEmployees;
        Decimal AnnualRevenue;
        String Industry;

        global InstanceWrapper() {
            Id = Name = BillingStreet = Industry = null;
            NumberOfEmployees = null;
            AnnualRevenue = null;
        }

        global InstanceWrapper(String Id, String Name, String BillingStreet, Integer NumberOfEmployees, Decimal AnnualRevenue, String Industry) {
            this.Id = Id;
            this.Name = Name;
            this.BillingStreet = BillingStreet;
            this.NumberOfEmployees = NumberOfEmployees;
            this.AnnualRevenue = AnnualRevenue;
            this.Industry = Industry;
        }

    }

    private static String getObjectFields(String objName) {

        String fieldnames = '';

        Map <String, Schema.SObjectType> m = Schema.getGlobalDescribe();
        Schema.SObjectType s = m.get(objName);
        Schema.DescribeSObjectResult r = s.getDescribe();

        //get fields
        Map <String, Schema.SObjectField> fields = r.fields.getMap();
        for (string field : fields.keySet()) {
            if (fieldnames == '') {
                fieldnames = field;
            } else {
                fieldnames += ',' + field;
            }
        }

        return fieldnames;

    }

    private static List<Account> accounts() {
        return [SELECT Id, 
                       Name,
                       BillingStreet,
                       NumberOfEmployees,
                       AnnualRevenue,
                       Industry
                FROM Account
                ORDER BY NumberOfEmployees 
                LIMIT 200];
    }
    
    private static Integer count() {
        return [SELECT COUNT() FROM Account];
    }

    static private Boolean isAccessible() {
        Map <String, Schema.SObjectField> fieldsToken = getMap();
        for (String field : fieldsAccount) {
            if (!fieldsToken.get(field).getDescribe().isAccessible()) {
                throw new System.NoAccessException();
                return false;
            }
        }
        return true;
    }

    static private Boolean isUpdateable() {
        Map <String, Schema.SObjectField> fieldsToken = getMap();
        for (String field : fieldsAccount) {
            if (!fieldsToken.get(field).getDescribe().isUpdateable()) {
                throw new System.NoAccessException();
                return false;
            }
        }
        return true;
    }

    private static Map <String, Schema.SObjectField> getMap() {
        Map <String, Schema.SObjectField> fieldsToken = Schema.SObjectType.Account.fields.getMap();
        return fieldsToken;
    }

    
}