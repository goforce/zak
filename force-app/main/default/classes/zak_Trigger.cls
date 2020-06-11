// trigger handler to be called in triggers. it accepts implementation of the trigger handler.
public class zak_Trigger {

    public static void run() {
        for ( zak_TriggerHandler__mdt m : [select DeveloperName, SObject__c from zak_TriggerHandler__mdt] ) {
            if ( m.SObject__c == 'Account' ) {
                zak_TriggerHandler h = (zak_TriggerHandler) Type.forName( m.DeveloperName );
                if ( h <> null ) {
                    run( h );
                }
            }
        }
    }

    public static void run( zak_TriggerHandler h ) {

        // not allowed to run not in Trigger context
        if ( ! ( Test.isRunningTest() || Trigger.isExecuting ) ) {
            throw new TriggerException( 'not allowed' );
        }

        // bypasses and actions are reset on root run
        // root run is first invocation of trigger on empty stack of trigger invocations
        if ( stack.isEmpty() ) {
            queue = null;
        }

        // check is run allowed and not bypassed
        zak_TriggerContext ctx = new zak_TriggerContext();
        if ( addToStack( ctx ) ) {
            // context is object containing full information about invocation of the trigger
            try {
                switch on ctx.operation {
                    when BEFORE_INSERT {
                        h.beforeInsert( ctx );
                    }
                    when AFTER_INSERT {
                        h.afterInsert( ctx );
                    }
                    when BEFORE_UPDATE {
                        h.beforeUpdate( ctx );
                    }
                    when AFTER_UPDATE {
                        h.afterUpdate( ctx );
                    }
                    when BEFORE_DELETE {
                        h.beforeDelete( ctx );
                    }
                    when AFTER_DELETE {
                        h.afterDelete( ctx );
                    }
                    when AFTER_UNDELETE {
                        h.afterUndelete( ctx );
                    }
                }
            } finally {
                removeFromStack();
            }
            if ( stack.isEmpty() ) {
                runQueue();
            }
        }

    }

    // ------------------------------ stack related methods ------------------------------

    // stack of trigger invocations
    private static List<zak_TriggerContext> stack = new List<zak_TriggerContext>();

    // check should handler be run and add run to the stack
    private static Boolean addToStack( zak_TriggerContext ctx ) {
        if ( isBypassed( ctx.sObjectType ) ) return false;
        Integer i = stack.size();
        if ( i > 0 && stack[i-1].isBypassed( ctx.sObjectType ) ) return false; 
        stack.add( ctx );
        return true;
    }

    // finalize run removes it from the stack
    private static void removeFromStack() {
        zak_TriggerContext ctx = stack.remove( stack.size() - 1 );
        ctx.close();
    }

    public static SObjectType firstSObject() {
        Integer i = stack.size();
        if ( i > 0 ) return stack[0].sObjectType;
        return null;
    }

    public static SObjectType prevSObject() {
        Integer i = stack.size();
        if ( i > 1 ) return stack[i-2].sObjectType;
        return null;
    }

    // ------------------------------ queueing related methods ------------------------------

    private static List<Queueable> queue;

    public static void enqueue( Queueable job ) {
        if ( job == null ) return;
        if ( queue == null ) queue = new List<Queueable>();
        queue.add( job );
    }

    private static void runQueue() {
        if ( queue <> null && ! queue.isEmpty() ) {
            try {
                System.enqueueJob( new zak_QueueManager( queue ) );
            } catch ( Exception e ) {
                zak_ErrorLog.log( 'zak_QueueManager', e );
            }
        }
    }

    // ------------------------------ bypass related methods ------------------------------

    // bypasses contains set of sObjects which were set to bypass triggers
    private static Set<Schema.SObjectType> bypasses = new Set<Schema.SObjectType>();

    // bypass with no parameters will bypass all the trigger handlers
    public static void bypass() {
        bypasses = null;
    }

    // bypass the set of handlers for specified sobject types
    public static void bypass( List<Schema.SObjectType> sObjectTypes ) {
        if ( bypasses <> null ) bypasses.addAll( sObjectTypes );
    }

    // bypass handler of sobject type
    public static void bypass( Schema.SObjectType sObjectType ) {
        if ( bypasses <> null ) bypasses.add( sObjectType );
    }

    public static Boolean isBypassed( Schema.SObjectType sObjectType ) {
        return bypasses == null || bypasses.contains( sObjectType );
    }

    public static void clearBypasses() { bypasses = new Set<Schema.SObjectType>(); }

    public class TriggerException extends Exception {}

}