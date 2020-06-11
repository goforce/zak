// wrapper for SObject
public class zak_UnitTestRecord {

    private SObject rec;

    public zak_UnitTestRecord( SObject obj ) { this.rec = obj; }

    private Map<SObjectField,SObject> lookups;
    public zak_UnitTestRecord lookup( SObjectField f, zak_UnitTestRecord ref ) {
        return lookup( f, ref.rec );
    }
    public zak_UnitTestRecord lookup( SObjectField f, SObject obj ) {
        if ( lookups == null ) lookups = new Map<SObjectField,SObject>();
        lookups.put( f, obj );
        return this;
    }
    // use rec.get( SObjectField f ) to get related object.
    // get also checks fields directly for cases when polymorhpic relation is not needed.
    public SObject get( SObjectField f ) {
        // check lookups
        if ( lookups <> null ) {
            SObject o = lookups.get( f );
            if ( o <> null ) return o;
        }
        // if nothing in lookups then check object itself
        return rec.getSObject( f );
    }
    public SObject sobj() { return rec; }

}