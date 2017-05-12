/**
 * AngularJS promises - Remote Action controller
 */
global with sharing class NgContactsRemoteCtrl {
    global PageReference goToContacts {get; private set;}
    global PageReference goToAccounts {get; private set;}
    global PageReference goToHomepage {get; private set;}

    static global String[] fieldsContact = new String[] {
        'Id', 
        'Name', 
        'Department', 
        'Email', 
        'Phone', 
        'AccountId', 
        'Account.Name'
    };

    global NgContactsRemoteCtrl() {

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
    global static String getContactListJSON() {

        System.debug('get Contacts list as JSON...');
        List <InstanceWrapper> instance = new List <InstanceWrapper>();
        for (Contact c : contacts()) {
            instance.add(new InstanceWrapper( c.Id, c.Name, c.Department, c.Email, c.Phone, c.Account.Name ));
        }
        return JSON.serializePretty(instance);

    }

    @RemoteAction
    global static String findAll() {

        return JSON.serializePretty(contacts());

    }

    @RemoteAction
    global static List<Contact> getAllByFilter(String searchText) {

        Try {

            String pattern = '%' + searchText + '%';
            return (List<Contact>) CrudOps.findObjectFiltered(new Contact(), pattern);

        } Catch(Exception e) {

            System.debug(LoggingLevel.ERROR, 'An error has occured during Fetch: ' + e.getMessage() + ' caused by ' + e.getCause() + ' on line ' + e.getLineNumber());
            return null;

        }

    }    

    @RemoteAction
    global static String saveAndGetAll(Contact contact) {
        Try {

            if ( CrudOps.saveObject(contact) )
                return findAll();
            else
                return 'An error has occurred, Contact not successfully persisted.';

        } Catch(Exception e) {

            System.debug(LoggingLevel.ERROR, 'An error has occured during Saving: ' + e.getMessage() + ' caused by ' + e.getCause() + ' on line ' + e.getLineNumber());
            return null;

        }
    }

    @RemoteAction
    global static String deleteById(String ID) {
        Try {
                
            Contact contact = Database.Query('SELECT ' + CrudOps.getObjectFields('Contact') + ' FROM Contact WHERE ID = \'' + ID + '\' LIMIT 1');
            if ( CrudOps.deleteObjectById(contact, ID) ) 
                return findAll();
            else 
                return 'An error has occurred, Contact not successfully deleted.';    
            
        } Catch(Exception e) {

            System.debug(LoggingLevel.ERROR, 'An error has occured during Deletion: ' + e.getMessage() + ' caused by ' + e.getCause() + ' on line ' + e.getLineNumber());
            return null;

        }
    }

    @RemoteAction
    global static List<Contact> updateContact(String contactJSON) {
        Try {
          
            Contact contactMerge = (Contact) JSON.deserialize(contactJSON, Contact.class);
            if ( CrudOps.updateObject(contactMerge) )
                return contacts();
            else
                return null;
            
        } Catch(Exception e) {

            System.debug(LoggingLevel.ERROR, 'An error has occured during Merging: ' + e.getMessage() + ' caused by ' + e.getCause() + ' on line ' + e.getLineNumber());
            return null;

        }
    }


    /*----- UTILS -----*/

    global class InstanceWrapper {
        String Id;
        String Name;
        String Department;
        String Email;
        String Phone;
        String AccountId;
        String AccountName;

        global InstanceWrapper() {
            Name = Department = Email = Phone = AccountID = AccountName = '';
        }

        global InstanceWrapper(String Id, 
            String Name, 
            String Department, 
            String Email, 
            String Phone, 
            String AccountName) {
            
            this.Id             = Id;
            this.Name           = Name;
            this.Department     = Department;
            this.Email          = Email;
            this.Phone          = Phone;
            this.AccountName    = AccountName;
            String pattern = '%' + AccountName + '%';

            if (AccountName != null) {
                this.AccountId = [SELECT ID
                                  FROM Account
                                  WHERE Name LIKE :pattern
                                  LIMIT 1].ID;
            }
        }

    }

    private static List<Contact> contacts() {
        return [SELECT Id,
                       Name,
                       Email,
                       Phone,
                       Department,
                       AccountId,
                       Account.Name
                FROM Contact
                ORDER BY Name DESC
                LIMIT 200];
    }

    private static Integer count() {
        return [SELECT COUNT() FROM Contact];
    }


}