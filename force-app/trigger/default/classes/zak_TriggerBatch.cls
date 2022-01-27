public without sharing class zak_TriggerBatch implements Batchable, Schedulable {

    public zak_TriggerBatch( Type operation, String soql ) {}


    public void execute() {
        new zak_Trigger( zak_Trigger.AfterUpdate.class, newvals, oldvals ).run( List<Type>{ handler.class } );
        zak_Trigger.run( List<Type>{ handler.class }, zak_Trigger.AfterUpdate.class, newvals, oldvals )
    }


}
