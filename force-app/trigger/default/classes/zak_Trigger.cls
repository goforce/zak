// trigger handler to be called in triggers. it accepts implementation of the trigger handler.
// bypasses use zak_Bypass by checking "triggers", "triggers.<sobject name>" and "triggers.<sobject name>.<handler name>"
public inherited sharing class zak_Trigger {

    // zak_Settings to enable additional logging in debug log and zak_Log
    public static final Boolean logDebug = zak_Settings.get( 'trigger_log_debug', null ) == 'true' ? true : false;
    public static final Boolean logErrors = zak_Settings.get( 'trigger_log_errors', null ) == 'true' ? true : false;
    public static final Boolean logPerf = zak_Settings.get( 'trigger_log_perf', null ) == 'true' ? true : false;

    // root element of internal trigger bypasses for zak_Bypass
    public static final String BYPASS_TRIGGERS = 'triggers';

    // triggers can be invoked using 2 methods:
    // - zak_Trigger.run() - handlers are defined in custom metadata zak_Trigger__mdt;
    // - zak_Trigger.run( HandlerClass.class ) - run trigger with just one handler.
    // "old" style new HandlerClass().run() is deprecated as class name discovery by
    // deserialising class is not efficient and approach increases complexity without
    // adding much of functionality or convinience.

    private static void run( Type handler, zak_Trigger t ) {
        zak_Trigger.activeTrigger = t;
        if ( logDebug ) {
            zak_Trigger.debug( 'TRIGGER START', ''.leftPad( zak_Trigger.depth(), '>' ) + ' ' + t.sObjectType + ' ' + t.operation );
        }
        zak_PerfLogger pl;
        if ( logPerf ) {
            pl = new zak_PerfLogger( t.logSubject( null ) );
        }
        try {
            if ( ! zak_Bypass.isEnabled( BYPASS_TRIGGERS ) ) {
                List<HandlerInstance> hds = handler == null
                                          ? zak_Trigger.getHandlers( t.sObjectType, t.operation )
                                          : new List<HandlerInstance>{ new HandlerInstance( t.sObjectType, handler ) };
                t.run( hds );
            } else if ( logDebug ) {
                zak_Trigger.debug( 'BYPASS', 'top level bypass enabled for ' + BYPASS_TRIGGERS + ' in zak_Bypass' );
            }
        } catch ( Exception e ) {
            if ( logErrors && t.parent === zak_Trigger.ROOT ) {
                zak_Log.log( 'zak_Trigger.run', e );
            }
            throw e;
        } finally {
            if ( logDebug ) {
                zak_Trigger.debug( 'TRIGGER FINISH', ''.leftPad( zak_Trigger.depth(), '<' ) + ' ' + t.sObjectType + ' ' + t.operation );
            }
            if ( pl <> null ) {
                pl.finish();
            }
            zak_Trigger.activeTrigger = t.parent;
        }
    }

    public static void run() {
        zak_Trigger.run( (Type) null, new zak_Trigger( zak_Trigger.activeTrigger ) );
    }

    public static void run( Type handler ) {
        zak_Trigger.run( handler, new zak_Trigger( zak_Trigger.activeTrigger ) );
    }

    // intended for use from unit tests and batch.
    public static void run( Type handler, Type operation, List<SObject> scope, List<SObject> olds ) {
        zak_Trigger t = new zak_Trigger( zak_Trigger.activeTrigger );
        t.operation = operation;
        t.scope = scope;
        t.olds = olds;
        if ( scope <> null && ! scope.isEmpty() ) {
            t.sObjectType = scope[0].getSObjectType();
        }
    zak_Trigger.run( handler, t );
    }

    public interface BeforeInsert { void beforeInsert( List<SObject> scope ); }
    public interface AfterInsert { void afterInsert( List<SObject> scope ); }
    public interface BeforeUpdate { void beforeUpdate( List<SObject> scope, List<SObject> olds ); }
    public interface AfterUpdate { void afterUpdate( List<SObject> scope, List<SObject> olds ); }
    public interface BeforeDelete { void beforeDelete( List<SObject> scope ); }
    public interface AfterDelete { void afterDelete( List<SObject> scope ); }
    public interface AfterUndelete { void afterUndelete( List<SObject> scope ); }

    // by default handlers are not run on recursive calls. By adding Recursive interface handler will
    // be run on all trigger invocations.
    // recursive call means that DML in trigger for sobject A caused another DML (and trigger invocation)
    // for sobject A either same record or different. simplest example of recursive call is update of the
    // parent field on the record pointing to the different record of the same sobject type.
    // another approach to enable recursive calls is to split handler so that DMLs issuing handler
    // by default will not be recursive but business logic handlers will be kind of recursive as
    // are moved out from active stack.
    public interface Recursive {}

    // abstract class implementing all operations to simplify transition from legacy framework.
    public inherited sharing abstract class Handler
        implements BeforeInsert, AfterInsert
                 , BeforeUpdate, AfterUpdate
                 , BeforeDelete, AfterDelete
                 , AfterUndelete
    {
        public virtual void beforeInsert( List<SObject> scope ) {}
        public virtual void afterInsert( List<SObject> scope ) {}
        public virtual void beforeUpdate( List<SObject> scope, List<SObject> olds ) {}
        public virtual void afterUpdate( List<SObject> scope, List<SObject> olds ) {}
        public virtual void beforeDelete( List<SObject> scope ) {}
        public virtual void afterDelete( List<SObject> scope ) {}
        public virtual void afterUndelete( List<SObject> scope ) {}
    }


    // ------------------------------ bypass and inject methods ------------------------------

    // stack of calls is linked list of zak_Triggers
    private static final zak_Trigger ROOT = new zak_Trigger( null );
    // current trigger invocation
    private static zak_Trigger activeTrigger = ROOT;

    // ------------------------------ bypass and inject methods ------------------------------

    // there are two types of bypasses: sobject based and handler class based.
    // bypass work only within run of the trigger issuing bypass. to set global bypasses use z_Bypass.
    // z_Bypass is checked for triggers[.sobjecttype[.handlerclassname]]

    // bypass without parameters bypass all
    public static void bypass() {
        if ( zak_Trigger.activeTrigger?.activeHandler == null ) {
            throw new TriggerException( 'not allowed' );
        }
        zak_Trigger.activeTrigger.activeHandler.bypass();
    }

    public static void bypass( SObjectType t ) {
        if ( zak_Trigger.activeTrigger?.activeHandler == null ) {
            throw new TriggerException( 'not allowed' );
        }
        zak_Trigger.activeTrigger.activeHandler.bypass( t );
    }

    public static void removeBypass( SObjectType t ) {
        if ( zak_Trigger.activeTrigger?.activeHandler == null ) {
            throw new TriggerException( 'not allowed' );
        }
        zak_Trigger.activeTrigger.activeHandler.removeBypass( t );
    }

    public static void bypass( Type handlerClass ) {
        if ( zak_Trigger.activeTrigger?.activeHandler == null ) {
            throw new TriggerException( 'not allowed' );
        }
        zak_Trigger.activeTrigger.activeHandler.bypass( handlerClass );
    }

    public static void removeBypass( Type handlerClass ) {
        if ( zak_Trigger.activeTrigger?.activeHandler == null ) {
            throw new TriggerException( 'not allowed' );
        }
        zak_Trigger.activeTrigger.activeHandler.removeBypass( handlerClass );
    }

    public static void inject( SObjectType sObjectType, Object handler ) {
        if ( zak_Trigger.activeTrigger?.activeHandler == null ) {
            throw new TriggerException( 'not allowed' );
        }
        zak_Trigger.activeTrigger.activeHandler.inject( sObjectType, handler );
    }

    // ------------------------------ stack related methods ------------------------------

    public static Boolean isFirstTrigger() {
        return zak_Trigger.activeTrigger <> null && zak_Trigger.activeTrigger.parent === ROOT;
    }

    public static Integer depth() {
        Integer i = 0;
        for ( zak_Trigger t = zak_Trigger.activeTrigger.parent; t <> null; t = t.parent ) {
            i++;
        }
        return i;
    }

    public static SObjectType firstSObject() {
        zak_Trigger t = zak_Trigger.activeTrigger;
        while ( t.parent !== ROOT ) t = t.parent;
        return t?.sObjectType;
    }

    public static SObjectType lastSObject() {
        return zak_Trigger.activeTrigger?.parent?.sObjectType;
    }

    // ------------------------------ utility methods ------------------------------

    private static void debug( String action, String log ) {
        System.debug( 'ZAK: ' + System.now().format( 'hh:mm:ss.SSS' ) + ' ' + action + ': ' + log );
    }

    // ------------------------------ performance logging ------------------------------
    private String logSubject( Object h ) {
        String s = '' + this.sObjectType + ' / ' + String.valueOf( this.operation ).substringAfter( '.' );
        if ( h <> null ) {
            if ( h instanceof String ) {
                s += ' / ' + h;
            } else {
                s += ' / ' + String.valueOf( h ).substringBefore( ':' );
            }
        }
        return s;
    }

    // ------------------------------ instance variables and methods ------------------------------ //

    // parent is closest known trigger instance where DML triggered this trigger invocation
    private zak_Trigger parent;
    private HandlerInstance activeHandler;
    // initialised from Trigger
    public Schema.SObjectType sObjectType;
    public Type operation;
    // scope is Trigger.old for Delete and Trigger.new for all the other DMLs
    private List<SObject> scope;
    // olds is Trigger.old for Update
    private List<SObject> olds;

    // initialises trigger run/invocation from Trigger
    private zak_Trigger( zak_Trigger parent ) {
        if ( parent <> null ) {
            this.parent = parent;
            if ( Trigger.isExecuting ) {
                switch on Trigger.operationType {
                    when BEFORE_INSERT {
                        this.operation = BeforeInsert.class;
                        this.scope = Trigger.new;
                    }
                    when AFTER_INSERT {
                        this.operation = AfterInsert.class;
                        this.scope = Trigger.new;
                    }
                    when BEFORE_UPDATE {
                        this.operation = BeforeUpdate.class;
                        this.scope = Trigger.new;
                        this.olds = Trigger.old;
                    }
                    when AFTER_UPDATE {
                        this.operation = AfterUpdate.class;
                        this.scope = Trigger.new;
                        this.olds = Trigger.old;
                    }
                    when BEFORE_DELETE {
                        this.operation = BeforeDelete.class;
                        this.scope = Trigger.old;
                    }
                    when AFTER_DELETE {
                        this.operation = AfterDelete.class;
                        this.scope = Trigger.old;
                    }
                    when AFTER_UNDELETE {
                        this.operation = AfterUndelete.class;
                        this.scope = Trigger.new;
                    }
                }
                this.sObjectType = this.scope[0].getSObjectType();
            }
        } else {
            // for ROOT trigger create and set dummy handler to enable bypasses and injections on ROOT.
            this.activeHandler = new HandlerInstance();
        }
    }

    private static final Set<Type> beforeOperations = new Set<Type>{ BeforeInsert.class, BeforeUpdate.class, BeforeDelete.class };
    private static final Set<Type> afterOperations = new Set<Type>{ AfterInsert.class, AfterUpdate.class, AfterDelete.class, AfterUndelete.class };

    // runs handlers within trigger
    private void run( List<HandlerInstance> handlers ) {
        List<HandlerInstance> injected = this.getInjected( this.sObjectType );
        zak_PerfLogger pl;
        // run injected hanlders for before triggers
        if ( ! injected.isEmpty() && beforeOperations.contains( this.operation ) ) {
            for ( HandlerInstance hi : injected ) {
                if ( hi.handlerInstance <> null && hi.isImplemented( this.operation ) ) {
                    if ( ! ( hi.handlerInstance instanceof Recursive ) && isOnStack( hi ) ) {
                        if ( logDebug ) {
                            zak_Trigger.debug( 'SKIP NON-RECURSIVE', String.valueOf( this.operation ) + ' in ' + String.valueOf( hi ) );
                        }
                        continue;
                    }
                    try {
                        this.activeHandler = hi;
                        if ( logDebug ) {
                            zak_Trigger.debug( 'INJECTED START', String.valueOf( this.operation ) + ' in ' + String.valueOf( hi ) );
                        }
                        if ( logPerf ) {
                            pl = new zak_PerfLogger( this.logSubject( hi ) );
                        }
                        hi.run( this.operation, this.scope, this.olds );
                    } finally {
                        if ( logDebug ) {
                            zak_Trigger.debug( 'INJECTED FINISH', String.valueOf( this.operation ) + ' in ' + String.valueOf( hi ) );
                        }
                        if ( pl <> null ) {
                            pl.finish();
                            pl = null;
                        }
                        this.activeHandler = null;
                    }
                }
            }
        }
        if ( ! handlers.isEmpty() && ! checkBypass( this.sObjectType ) ) {
            for ( HandlerInstance hi : handlers ) {
                if ( hi.isImplemented( this.operation ) ) {
                    if ( ! Recursive.class.isAssignableFrom( hi.handlerClass ) && isOnStack( hi ) ) {
                        if ( logDebug ) {
                            zak_Trigger.debug( 'SKIP NON-RECURSIVE', String.valueOf( hi.handlerClass ) + ' as ' + this.operation );
                        }
                        continue;
                    }
                    if ( checkBypass( hi.handlerClass ) ) {
                        if ( logDebug ) {
                            zak_Trigger.debug( 'BYPASS', String.valueOf( hi.handlerClass ) + ' as ' + this.operation );
                        }
                        continue;
                    }
                    try {
                        this.activeHandler = hi;
                        if ( logDebug ) {
                            zak_Trigger.debug( 'HANDLER START', String.valueOf( hi.handlerClass ) + ' as ' + this.operation );
                        }
                        if ( logPerf ) {
                            pl = new zak_PerfLogger( this.logSubject( String.valueOf( hi.handlerClass ) ) );
                        }
                        hi.run( this.operation, this.scope, this.olds );
                    } finally {
                        if ( logDebug ) {
                            zak_Trigger.debug( 'HANDLER FINISH', String.valueOf( hi.handlerClass ) + ' as ' + this.operation );
                        }
                        if ( pl <> null ) {
                            pl.finish();
                            pl = null;
                        }
                        this.activeHandler = null;
                    }
                }
            }
        }
        // run injected handlers for after triggers
        if ( ! injected.isEmpty() && afterOperations.contains( this.operation ) ) {
            for ( HandlerInstance hi : injected ) {
                if ( hi.handlerInstance <> null && hi.isImplemented( this.operation ) ) {
                    if ( ! ( hi.handlerInstance instanceof Recursive ) && isOnStack( hi ) ) {
                        if ( logDebug ) {
                            zak_Trigger.debug( 'SKIP NON-RECURSIVE', String.valueOf( this.operation ) + ' in ' + String.valueOf( hi ) );
                        }
                        continue;
                    }
                    try {
                        this.activeHandler = hi;
                        if ( logDebug ) {
                            zak_Trigger.debug( 'INJECTED START', String.valueOf( this.operation ) + ' in ' + String.valueOf( hi ) );
                        }
                        if ( logPerf ) {
                            pl = new zak_PerfLogger( this.logSubject( hi ) );
                        }
                        hi.run( this.operation, this.scope, this.olds );
                    } finally {
                        this.activeHandler = null;
                        if ( logDebug ) {
                            zak_Trigger.debug( 'INJECTED FINISH', String.valueOf( this.operation ) + ' in ' + String.valueOf( hi ) );
                        }
                        if ( pl <> null ) {
                            pl.finish();
                            pl = null;
                        }
                    }
                }
            }
        }
        // finalise trigger
        if ( this.parent === ROOT ) {
            zak_ErrorLog.flush();
        }
    }

    // checks global and trigger parent bypasses for all and/or sobject
    private Boolean checkBypass( Schema.SObjectType t ) {
        if ( zak_Bypass.isEnabled( BYPASS_TRIGGERS + '.' + String.valueOf( t ) ) ) return true;
        for ( zak_Trigger parent = this.parent; parent <> null; parent = parent.parent ) {
            if ( parent.activeHandler?.checkBypass( t ) == true ) return true;
        }
        return false;
    }

    // checks global and trigger parent bypasses for handler class
    private Boolean checkBypass( Type t ) {
        if ( zak_Bypass.isEnabled( BYPASS_TRIGGERS + '.' + String.valueOf( this.sObjectType ) + '.' + String.valueOf( t ) ) ) {
            return true;
        }
        for ( zak_Trigger parent = this.parent; parent <> null; parent = parent.parent ) {
            if ( parent.activeHandler?.checkBypass( t ) == true ) return true;
        }
        return false;
    }

    // returns list of injected handlers
    private List<HandlerInstance> getInjected( Schema.SObjectType sObjectType ) {
        List<HandlerInstance> injectedHandlers = new List<HandlerInstance>();
        for ( zak_Trigger parent = this.parent; parent <> null; parent = parent.parent ) {
            List<HandlerInstance> l = parent.activeHandler?.getInjected( sObjectType );
            if ( l <> null ) {
                injectedHandlers.addAll( l );
            }
        }
        return injectedHandlers;
    }

    private Boolean isOnStack( HandlerInstance hi ) {
        if ( this.parent == ROOT ) return false;
        if ( ( hi.handlerClass <> null && hi.handlerClass == this.parent.activeHandler?.handlerClass )
          || ( hi.handlerInstance <> null && hi.handlerInstance === this.parent.activeHandler?.handlerInstance ) )
        {
            return true;
        }
        return this.parent.isOnStack( hi );
    }

    @TestVisible
    private static Map<SObjectType,List<HandlerDef>> handlers = new Map<SObjectType,List<HandlerDef>>();
    private static List<HandlerInstance> getHandlers( SObjectType t, Type operation ) {
        List<HandlerDef> defs = handlers.get( t );
        if ( defs == null ) {
            defs = new List<HandlerDef>();
            for ( zak_TriggerHandler__mdt m : [select SObject__c, HandlerClass__c, RecordType__c, SequenceNumber__c
                                                 from zak_TriggerHandler__mdt
                                                where SObject__c = :String.valueOf( t )
                                             order by SequenceNumber__c] ) {
                defs.add( new HandlerDef( t, m ) );
            }
            handlers.put( t, defs );
        }
        List<HandlerInstance> instances = new List<HandlerInstance>();
        for ( HandlerDef d : defs ) {
            if ( operation.isAssignableFrom( d.handlerClass ) ) {
                instances.add( new HandlerInstance( d ) );
            }
        }
        return instances;
    }

    @TestVisible
    private class HandlerDef {
        private String sObjectName;
        private SObjectType sObjectType;
        private String recordTypeDeveloperName;
        private ID recordTypeId;
        private String handlerName;
        private Type handlerClass;
        @TestVisible
        private HandlerDef( Schema.SObjectType t, zak_TriggerHandler__mdt meta ) {
            this.sObjectName = meta.SObject__c;
            this.sObjectType = t;
            this.recordTypeDeveloperName = meta.RecordType__c;
            if ( ! String.isBlank( this.recordTypeDeveloperName ) ) {
                this.recordTypeId = t.getDescribe().getRecordTypeInfosByDeveloperName()?.get( this.recordTypeDeveloperName )?.getRecordTypeId();
                if ( this.recordTypeId == null ) {
                    throw new TriggerException( 'no record type: ' + this.recordTypeDeveloperName + ' for ' + t );
                }
            }
            this.handlerName = meta.HandlerClass__c;
            this.handlerClass = Type.forName( this.handlerName );
            if ( this.handlerName <> String.valueOf( this.handlerClass ) ) {
                throw new TriggerException( 'undefined class: ' + this.handlerName );
            }
        }
    }

    private class HandlerInstance {
        private SObjectType sObjectType;
        private ID recordTypeId;
        private Type handlerClass;
        private Object handlerInstance;
        private Boolean bypassAll = false;
        private Set<Schema.SObjectType> bypassSObjects;
        private Set<Type> bypassHandlers;
        private Map<Schema.SObjectType,List<HandlerInstance>> injectedHandlers;
        private Long started;
        private Long finished;
        private HandlerInstance() {}
        private HandlerInstance( HandlerDef d ) {
            this.sObjectType = d.sObjectType;
            this.recordTypeId = d.recordTypeId;
            this.handlerClass = d.handlerClass;
        }
        private HandlerInstance( SObjectType sObjectType, Object handler ) {
            this.sObjectType = sObjectType;
            if ( handler instanceof Type ) {
                this.handlerClass = (Type) handler;
            } else {
                this.handlerInstance = handler;
            }
        }
        private Boolean checkBypass( Schema.SObjectType t ) {
            if ( bypassAll || bypassSObjects?.contains( t ) == true ) return true;
            return false;
        }
        private Boolean checkBypass( Type t ) {
            if ( bypassAll || bypassHandlers?.contains( t ) == true ) return true;
            return false;
        }
        private void bypass() {
            this.bypassAll = true;
        }
        private void bypass( SObjectType t ) {
            if ( this.bypassSObjects == null ) {
                this.bypassSObjects = new Set<SObjectType>{ t };
            } else {
                this.bypassSObjects.add( t );
            }
        }
        private void removeBypass( SObjectType t ) {
            if ( this.bypassSObjects <> null ) {
                this.bypassSObjects.remove( t );
            }
        }
        private void bypass( Type handler ) {
            if ( this.bypassHandlers == null ) {
                this.bypassHandlers = new Set<Type>{ handler };
            } else {
                this.bypassHandlers.add( handler );
            }
        }
        private void removeBypass( Type handler ) {
            if ( this.bypassHandlers <> null ) {
                this.bypassHandlers.remove( handler );
            }
        }
        private void inject( Schema.SObjectType sObjectType, Object handler ) {
            if ( sObjectType <> null && handler <> null ) {
                HandlerInstance handlerInstance = new HandlerInstance();
                handlerInstance.sObjectType = sObjectType;
                handlerInstance.handlerInstance = handler;
                if ( this.injectedHandlers == null ) {
                    this.injectedHandlers = new Map<Schema.SObjectType,List<HandlerInstance>>{
                        sObjectType => new List<HandlerInstance>{ handlerInstance }
                    };
                } else {
                    List<HandlerInstance> l = this.injectedHandlers.get( sObjectType );
                    if ( l == null ) {
                        this.injectedHandlers.put( sObjectType, new List<HandlerInstance>{ handlerInstance } );
                    } else {
                        l.add( handlerInstance );
                    }
                }
            }
        }
        private List<HandlerInstance> getInjected( Schema.SObjectType sObjectType ) {
            return this.injectedHandlers?.get( sObjectType );
        }
        private Boolean isImplemented( Type operation ) {
            if ( this.handlerClass <> null ) {
                return operation.isAssignableFrom( this.handlerClass );
            } else if ( this.handlerInstance <> null ) {
                if ( operation == BeforeInsert.class ) {
                    return this.handlerInstance instanceof BeforeInsert;
                } else if ( operation == AfterInsert.class ) {
                    return this.handlerInstance instanceof AfterInsert;
                } else if ( operation == BeforeUpdate.class ) {
                    return this.handlerInstance instanceof BeforeUpdate;
                } else if ( operation == AfterUpdate.class ) {
                    return this.handlerInstance instanceof AfterUpdate;
                } else if ( operation == BeforeDelete.class ) {
                    return this.handlerInstance instanceof BeforeDelete;
                } else if ( operation == AfterDelete.class ) {
                    return this.handlerInstance instanceof AfterDelete;
                } else if ( operation == AfterUndelete.class ) {
                    return this.handlerInstance instanceof AfterUndelete;
                }
            }
            return false;
        }
        private void run( Type operation, List<SObject> scope, List<SObject> olds ) {
            if ( logPerf ) {
                this.started = System.now().getTime();
            }
            // instantiate instance
            if ( this.handlerInstance == null && this.handlerClass <> null ) {
                if ( operation.isAssignableFrom( this.handlerClass ) ) {
                    this.handlerInstance = this.handlerClass.newInstance();
                }
            }
            if ( this.handlerInstance <> null ) {
                List<SObject> filteredScope;
                List<SObject> filteredOlds;
                if ( this.recordTypeId <> null ) {
                    filteredScope = new List<SObject>();
                    if ( olds == null ) {
                        for ( Integer i = 0; i < scope.size(); i++ ) {
                            if ( scope[i].get( 'RecordTypeId' ) == this.recordTypeId ) {
                                filteredScope.add( scope[i] );
                            }
                        }
                    } else {
                        filteredOlds = new List<SObject>();
                        for ( Integer i = 0; i < scope.size(); i++ ) {
                            if ( scope[i].get( 'RecordTypeId' ) == this.recordTypeId || olds[i].get( 'RecordTypeId' ) == this.recordTypeId ) {
                                filteredScope.add( scope[i] );
                                filteredOlds.add( olds[i] );
                            }
                        }
                    }
                } else {
                    filteredScope = scope;
                    filteredOlds = olds;
                }
                // run the instance
                if ( operation == BeforeInsert.class ) {
                    if ( this.handlerInstance instanceof BeforeInsert ) {
                        ((BeforeInsert) this.handlerInstance).beforeInsert( filteredScope );
                    }
                } else if ( operation == AfterInsert.class ) {
                    if ( this.handlerInstance instanceof AfterInsert ) {
                        ((AfterInsert) this.handlerInstance).afterInsert( filteredScope );
                    }
                } else if ( operation == BeforeUpdate.class ) {
                    if ( this.handlerInstance instanceof BeforeUpdate ) {
                        ((BeforeUpdate) this.handlerInstance).beforeUpdate( filteredScope, filteredOlds );
                    }
                } else if ( operation == AfterUpdate.class ) {
                    if ( this.handlerInstance instanceof AfterUpdate ) {
                        ((AfterUpdate) this.handlerInstance).afterUpdate( filteredScope, filteredOlds );
                    }
                } else if ( operation == BeforeDelete.class ) {
                    if ( this.handlerInstance instanceof BeforeDelete ) {
                        ((BeforeDelete) this.handlerInstance).beforeDelete( filteredScope );
                    }
                } else if ( operation == AfterDelete.class ) {
                    if ( this.handlerInstance instanceof AfterDelete ) {
                        ((AfterDelete) this.handlerInstance).afterDelete( filteredScope );
                    }
                } else if ( operation == AfterUndelete.class ) {
                    if ( this.handlerInstance instanceof AfterUndelete ) {
                        ((AfterUndelete) this.handlerInstance).afterUndelete( filteredScope );
                    }
                }
            }
            if ( logPerf ) {
                this.finished = System.now().getTime();
            }
        }
    }

    public class TriggerException extends Exception {}

}
