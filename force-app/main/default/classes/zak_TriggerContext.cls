// context is single invocation of Handler. it contains information about invocation, like is it in trigger context
// or outside, trigger operation, few helpful methods.
// context should be closed by container (owner) of the context.
public class zak_TriggerContext {

    public Schema.SObjectType sObjectType { public get; private set; }
    public TriggerOperation operation { public get; private set; }
    public List<SObject> scope { public get; private set; }
    public List<SObject> olds { public get; private set; }

    // origins are wrapped (instead of extended) to keep interface minimalistic.
    protected zak_Origins origins;
    // errors will record all IDs from scope which got error added. these should be excluded from dmls.
    protected Set<ID> errors;
    protected Map<ID,SObject> errorTargets;

    public zak_TriggerContext() {
        if ( Trigger.isExecuting ) {
            this.operation = Trigger.operationType;
            if ( Trigger.isDelete ) {
                sObjectType = Trigger.old[0].getSObjectType();
                errorTargets = Trigger.oldMap;
                scope = Trigger.old;
                origins = new zak_Origins( Trigger.oldMap.keySet() );
            } else {
                sObjectType = Trigger.new[0].getSObjectType();
                scope = Trigger.new;
                errorTargets = Trigger.newMap;
                if ( Trigger.isUpdate ) {
                    olds = Trigger.old;
                    origins = new zak_Origins( Trigger.newMap.keySet() );
                } else if ( Trigger.isAfter && ( Trigger.isInsert || Trigger.isUndelete ) ) {
                    origins = new zak_Origins( Trigger.newMap.keySet() );
                }
            }
        }
    }

    public zak_TriggerContext( List<SObject> scope ) {
        this.scope = scope;
    }

    // flush all buffers, release all cache and scope variables
    public void close() {
        zak_ErrorLog.flush();
    }

    public static Boolean logErrors = zak_Settings.get( 'trigger_log_errors', null ) == 'false' ? false : true;

    // ------------------------------ bypass related methods ------------------------------

    // bypasses contains set of sObjects which were set to bypass triggers
    protected Set<Schema.SObjectType> bypasses;

    // bypass with no parameters will bypass all the trigger handlers
    public void bypass() {
        bypasses = null;
    }

    // bypass the set of handlers for specified sobject types
    public void bypass( List<Schema.SObjectType> sObjectTypes ) {
        if ( bypasses <> null ) bypasses.addAll( sObjectTypes );
    }

    // bypass handler of sobject type
    public void bypass( Schema.SObjectType sObjectType ) {
        if ( bypasses <> null ) bypasses.add( sObjectType );
    }

    public Boolean isBypassed( Schema.SObjectType sObjectType ) {
        return bypasses == null || bypasses.contains( sObjectType );
    }

    public void clearBypasses() { bypasses = new Set<Schema.SObjectType>(); }

    // ------------------------------ error handling related methods ------------------------------

    public void link( ID descendant, ID ancestor ) {
        if ( origins <> null ) origins.add( descendant, ancestor );
    }

    // add error to all ancestors and mark for removal from dml ops outside of trigger context.
    public Boolean addError( ID descendant, String error ) {
        logError( descendant, error );
        Boolean done = false;
        if ( ! Trigger.isExecuting ) return done;
        for ( ID o : origins.get( descendant ) ) {
            done = true;
            // add Id of the record to ones in error. that will allow to remove record from update dml.
            errors.add( o );
            // add error only if run in trigger context
            if ( errorTargets <> null ) {
                SObject obj = errorTargets.get( o );
                if ( obj <> null ) obj.addError( error );
            }
        }
        return done;
    }

    // log error on record. should be used in special cases when addError is called on field
    // and logging should be added
    public void logError( ID descendant, String error ) {
        if ( logErrors ) {
            zak_ErrorLog.add( zak_ErrorLog.ERR, 'zak_TriggerContext.addError', error, null, descendant, System.currentTimeMillis() );
        }
    }

    // returns true if error has been added to the record in scope identified by Id.
    public Boolean hasErrors( ID recordId ) {
        // in some cases errors may contain null
        if ( recordId == null ) return false;
        return errors.contains( recordId );
    }

}