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
            
            Account account = Database.Query('SELECT ' + CrudOps.getObjectFields('Account') + ' FROM Account WHERE ID = \'' + ID + '\' LIMIT 1');
            if ( CrudOps.deleteObjectById(account, ID) )
                return findAll();
            else
                return 'An error has occurred, Account not successfully deleted.'; 

        } Catch(Exception e) {

            System.debug(LoggingLevel.ERROR, 'An error has occured during Deletion: ' + e.getMessage() + ' caused by ' + e.getCause() + ' on line ' + e.getLineNumber());
            return null;

        }
    }

    @RemoteAction
    global static List<Account> updateAccount(String accountJSON) {
        Try {
          
            Account accountMerge = (Account) JSON.deserialize(accountJSON, Account.class);
            if ( CrudOps.updateObject(accountMerge) )
                return accounts();
            else
                return null;
          
        } Catch(Exception e) {

            System.debug(LoggingLevel.ERROR, 'An error has occured during Merge: ' + e.getMessage() + ' caused by ' + e.getCause() + ' on line ' + e.getLineNumber());
            return null;

        }
    }

    @RemoteAction
    global static List<Account> getAllByFilter(String searchText) {
        Try {

            String pattern = '%' + searchText + '%';
            return (List<Account>) CrudOps.findObjectFiltered(new Account(), pattern);

        } Catch(Exception e) {

            System.debug(LoggingLevel.ERROR, 'An error has occured during Fetch: ' + e.getMessage() + ' caused by ' + e.getCause() + ' on line ' + e.getLineNumber());
            return null;

        }
    }


    /*------ UTILS -----*/

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

    private static List<Account> accounts() {
        return [SELECT Id, 
                       Name,
                       BillingStreet,
                       NumberOfEmployees,
                       AnnualRevenue,
                       Industry
                FROM Account
                ORDER BY NumberOfEmployees DESC
                LIMIT 200];
    }
    
    private static Integer count() {
        return [SELECT COUNT() FROM Account];
    }


}