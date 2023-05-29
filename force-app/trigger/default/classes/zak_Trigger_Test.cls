@isTest
private without sharing class zak_Trigger_Test {

    private static List<String> actions;

    @isTest
    private static void testAll() {
        zak_Settings.set( 'trigger_log_debug', 'true' );
        zak_Settings.set( 'trigger_log_errors', 'true' );
        zak_Settings.set( 'trigger_log_perf', 'true' );
        List<Account> accounts = new List<Account>{ new Account( Name = 'first' ), new Account( Name = 'second' ) };
        Test.startTest();

        zak_TriggerHandler__mdt ma = new zak_TriggerHandler__mdt( SObject__c = 'Account', HandlerClass__c = 'zak_Trigger_Test.AccountTriggerHandler' );
        zak_TriggerHandler__mdt me = new zak_TriggerHandler__mdt( SObject__c = 'Account', HandlerClass__c = 'zak_Trigger_Test.EmptyTriggerHandler' );
        zak_Trigger.handlers.put( Account.sObjectType, new List<zak_Trigger.HandlerDef>{
            new zak_Trigger.HandlerDef( Account.sObjectType, ma )
          , new zak_Trigger.HandlerDef( Account.sObjectType, me )
        } );
        zak_TriggerHandler__mdt mc = new zak_TriggerHandler__mdt( SObject__c = 'Contact', HandlerClass__c = 'zak_Trigger_Test.EmptyTriggerHandler' );
        zak_Trigger.handlers.put( Contact.sObjectType, new List<zak_Trigger.HandlerDef>{ new zak_Trigger.HandlerDef( Contact.sObjectType, mc ) } );

        // before insert
        actions = new List<String>();
        zak_Trigger.run( null, zak_Trigger.BeforeInsert.class, accounts, null );
        System.assertEquals( 3, actions.size() );
        System.assertEquals( 'account.before.insert', actions[0] );
        System.assertEquals( 'contact.before.insert', actions[1] );
        System.assertEquals( 'contact.after.insert', actions[2] );
        // after insert
        actions = new List<String>();
        zak_Trigger.run( null, zak_Trigger.AfterInsert.class, accounts, null );
        System.assertEquals( 1, actions.size() );
        System.assertEquals( 'account.after.insert', actions[0] );
        // before update
        actions = new List<String>();
        zak_Trigger.run( null, zak_Trigger.BeforeUpdate.class, accounts, null );
        System.assertEquals( 3, actions.size() );
        System.assertEquals( 'account.before.update', actions[0] );
        System.assertEquals( 'injected.before.update', actions[1] );
        System.assertEquals( 'injected.after.update', actions[2] );
        // after update
        actions = new List<String>();
        zak_Trigger.run( null, zak_Trigger.AfterUpdate.class, accounts, null );
        System.assertEquals( 1, actions.size() );
        System.assertEquals( 'account.after.update', actions[0] );
        // before delete
        actions = new List<String>();
        zak_Trigger.run( null, zak_Trigger.BeforeDelete.class, accounts, null );
        System.assertEquals( 1, actions.size() );
        System.assertEquals( 'account.before.delete', actions[0] );
        // after delete
        actions = new List<String>();
        zak_Trigger.run( null, zak_Trigger.AfterDelete.class, accounts, null );
        System.assertEquals( 1, actions.size() );
        System.assertEquals( 'account.after.delete', actions[0] );
        // after undelete
        actions = new List<String>();
        zak_Trigger.run( null, zak_Trigger.AfterUndelete.class, accounts, null );
        System.assertEquals( 6, actions.size() );
        System.assertEquals( 'account.after.undelete', actions[0] );
        System.assertEquals( 'recursive.after.undelete', actions[1] );
        System.assertEquals( 'first.sobject.Account', actions[2] );
        System.assertEquals( 'last.sobject.Contact', actions[3] );
        System.assertEquals( 'is.first.false', actions[4] );
        System.assertEquals( 'recursive.after.undelete', actions[5] );

        //  bypass sobject type
        actions = new List<String>();
        zak_Trigger.bypass( Schema.Contact.sObjectType );
        zak_Trigger.run( null, zak_Trigger.BeforeInsert.class, accounts, null );
        zak_Trigger.removeBypass( Schema.Contact.sObjectType );
        System.assertEquals( 1, actions.size() );
        System.assertEquals( 'account.before.insert', actions[0] );
        // bypass handler
        actions = new List<String>();
        zak_Trigger.bypass( ContactTriggerHandler.class );
        zak_Trigger.run( null, zak_Trigger.BeforeInsert.class, accounts, null );
        zak_Trigger.removeBypass( ContactTriggerHandler.class );
        System.assertEquals( 1, actions.size() );
        System.assertEquals( 'account.before.insert', actions[0] );
        // bypass using zak_Bypass
        actions = new List<String>();
        zak_Bypass.add( 'triggers' );
        zak_Trigger.run( null, zak_Trigger.BeforeInsert.class, accounts, null );
        zak_Bypass.remove( 'triggers' );
        System.assertEquals( 0, actions.size() );


        // bypass all - very last as it can not be reset
        actions = new List<String>();
        zak_Trigger.bypass();
        zak_Trigger.run( null, zak_Trigger.BeforeInsert.class, accounts, null );
        System.assertEquals( 0, actions.size() );
        Test.stopTest();
    }

    public class AccountTriggerHandler extends zak_Trigger.Handler {
        public override void beforeInsert( List<SObject> scope ) {
            actions.add( 'account.before.insert' );
            LocalService ls = zak_Trigger.get( LocalService.class );
            System.assertEquals( 'local', ls.name );
            ls.init( 'account' );
            System.assertEquals( 'account', ls.name );
            GlobalService gs = zak_Trigger.get( GlobalService.class );
            System.assertEquals( 'global', gs.name );
            gs.init( 'account' );
            System.assertEquals( 'account', gs.name );
            List<Contact> contacts = new List<Contact>{ new Contact( LastName = 'first' ), new Contact( LastName = 'second' ) };
            zak_Trigger.run( ContactTriggerHandler.class, zak_Trigger.BeforeInsert.class, contacts, null );
            zak_Trigger.run( ContactTriggerHandler.class, zak_Trigger.AfterInsert.class, contacts, null );
        }
        public override void afterInsert( List<SObject> scope ) {
            actions.add( 'account.after.insert' );
            LocalService ls = zak_Trigger.get( LocalService.class );
            System.assertEquals( 'local', ls.name );
            ls.init( 'account' );
            System.assertEquals( 'account', ls.name );
            GlobalService gs = zak_Trigger.get( GlobalService.class );
            System.assertEquals( 'global', gs.name );
            gs.init( 'account' );
            System.assertEquals( 'account', gs.name );
        }
        public override void beforeUpdate( List<SObject> scope, List<SObject> olds ) {
            actions.add( 'account.before.update' );
            zak_Trigger.inject( Schema.Contact.sObjectType, new InjectedTriggerHandler() );
            List<Contact> contacts = new List<Contact>{ new Contact( LastName = 'first' ), new Contact( LastName = 'second' ) };
            zak_Trigger.run( ContactTriggerHandler.class, zak_Trigger.BeforeUpdate.class, contacts, null );
            zak_Trigger.run( ContactTriggerHandler.class, zak_Trigger.AfterUpdate.class, contacts, null );
        }
        public override void afterUpdate( List<SObject> scope, List<SObject> olds ) {
            actions.add( 'account.after.update' );
        }
        public override void beforeDelete( List<SObject> scope ) {
            actions.add( 'account.before.delete' );
        }
        public override void afterDelete( List<SObject> scope ) {
            actions.add( 'account.after.delete' );
        }
        public override void afterUndelete( List<SObject> scope ) {
            actions.add( 'account.after.undelete' );
            List<Contact> contacts = new List<Contact>{ new Contact( LastName = 'first' ), new Contact( LastName = 'second' ) };
            zak_Trigger.run( RecursiveTriggerHandler.class, zak_Trigger.AfterUndelete.class, contacts, null );
        }
    }

    public class ContactTriggerHandler extends zak_Trigger.Handler {
        public override void beforeInsert( List<SObject> scope ) {
            actions.add( 'contact.before.insert' );
            LocalService ls = zak_Trigger.get( LocalService.class );
            System.assertEquals( 'local', ls.name );
            ls.init( 'contact' );
            System.assertEquals( 'contact', ls.name );
            GlobalService gs = zak_Trigger.get( GlobalService.class );
            System.assertEquals( 'account', gs.name );
        }
        public override void afterInsert( List<SObject> scope ) {
            actions.add( 'contact.after.insert' );
        }
    }

    public class InjectedTriggerHandler implements zak_Trigger.BeforeUpdate, zak_Trigger.AfterUpdate {
        public void beforeUpdate( List<Contact> scope, List<Contact> olds ) {
            actions.add( 'injected.before.update' );
        }
        public void afterUpdate( List<Contact> scope, List<Contact> olds ) {
            actions.add( 'injected.after.update' );
        }
    }

    public class RecursiveTriggerHandler implements zak_Trigger.AfterUndelete, zak_Trigger.Recursive {
        public void afterUndelete( List<Contact> scope ) {
system.debug( 'in recursive: ' + actions.contains( 'recursive.after.undelete' ) );
            actions.add( 'recursive.after.undelete' );
            zak_Trigger.run( RunRecursiveTriggerHander.class, zak_Trigger.AfterUndelete.class, scope, null );
        }
    }

    public class RunRecursiveTriggerHander implements zak_Trigger.AfterUndelete {
        public void afterUndelete( List<Contact> scope ) {
system.debug( 'in run recursive' );
            actions.add( 'first.sobject.' + zak_Trigger.firstSObject() );
            actions.add( 'last.sobject.' + zak_Trigger.lastSObject() );
            actions.add( 'is.first.' + zak_Trigger.isFirstTrigger() );
            zak_Trigger.run( RecursiveTriggerHandler.class, zak_Trigger.AfterUndelete.class, scope, null );
        }
    }

    public class LocalService implements zak_Trigger.LocalService {
        public String name;
        public LocalService() {
            name = 'local';
        }
        public LocalService init( String name ) {
            this.name = name;
            return this;
        }
        public void finish() {
            name = null;
        }
    }

    public class GlobalService implements zak_Trigger.GlobalService {
        public String name;
        public GlobalService() {
            name = 'global';
        }
        public GlobalService init( String name ) {
            this.name = name;
            return this;
        }
        public void finish() {
            name = null;
        }
    }

    public class EmptyTriggerHandler extends zak_Trigger.Handler {}

}
