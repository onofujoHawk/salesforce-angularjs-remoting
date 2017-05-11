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
   
    //No RemoteAction, use Wrapper instead
    global static String getAccountListJSON() {
        List <InstanceWrapper> instance = new List <InstanceWrapper>();
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
        Try {
            
            Map <String,Account> accountMap = new Map <String,Account>();
            Account account = Database.Query('SELECT ' + getObjectFields('Account') + ' FROM Account WHERE ID = \'' + ID + '\' LIMIT 1');
            System.debug('Deleting Account... ' + account);
            delete account;
            Account[] accounts = accounts();
            for (Account acc : accounts) {
                accountMap.put(acc.Id, acc);
            }
            if (!accountMap.containsKey(Id)) {
                return findAll();
            } else {
                return 'Account not successfully deleted.';
            }

        } Catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occured during Deletion: ' + e.getMessage() + ' caused by ' + e.getCause() + ' on line ' + e.getLineNumber());
            return null;
        }
    }

    @RemoteAction
    global static List<Account> updateAccount(String accountJSON) {
        Try {
          
            Account accountNew = (Account) JSON.deserialize(accountJSON, Account.class);
            System.debug('Account to update... ' + accountNew);
            Account accountOld = Database.Query('SELECT ' + getObjectFields('Account') + ' FROM Account WHERE ID = \'' + accountNew.Id + '\'');
            if (accountNew != accountOld) {
                System.debug('Updating Account... ' + accountNew);
                update accountNew;
                return accounts();    
            } else {
                System.debug('New Account and Old Account are the same, cannot update...');
                return null;
            }
          
        } Catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occured during Merge: ' + e.getMessage() + ' caused by ' + e.getCause() + ' on line ' + e.getLineNumber());
            return null;
        }
    }

    @RemoteAction
    global static List<Account> getAllByFilter(String searchText) {
        String pattern = '%' + searchText + '%';
        Try {

            return [SELECT Id,
                           Name,
                           BillingStreet,
                           NumberOfEmployees,
                           AnnualRevenue,
                           Industry
                    FROM Account
                    WHERE Name LIKE :pattern];

        } Catch (Exception e) {
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

        global InstanceWrapper(String Id, 
            String Name, 
            String BillingStreet, 
            Integer NumberOfEmployees, 
            Decimal AnnualRevenue, 
            String Industry) {
            
            this.Id                 = Id;
            this.Name               = Name;
            this.BillingStreet      = BillingStreet;
            this.NumberOfEmployees  = NumberOfEmployees;
            this.AnnualRevenue      = AnnualRevenue;
            this.Industry           = Industry;
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