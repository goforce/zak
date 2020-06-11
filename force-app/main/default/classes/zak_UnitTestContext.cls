// context is set of records created (or to be created) by factory run. records are grouped by entity type.
// context has no knowledge about how to create records or what entities should be created as pre-requisites.
// it defines scope in terms of target objects to be created and after factory run contains all created records.
// scope of context could also be set using intents, set of sobject types for which all pre-requisites are added
// to the scope.
// often context has defined set of values which distiguish records created within this context from records
// created in other contexts.
public virtual class zak_UnitTestContext {

    private Set<Type> intents = new Set<Type>();
    private Set<Type> scope = new Set<Type>();
    private Map<Type,List<zak_UnitTestRecord>> records = new Map<Type,List<zak_UnitTestRecord>>();

    // few ootb properties
    public Datetime now { protected set; public get; }
    public Date today { protected set; public get; }
    public String key { protected set; public get; }

    public zak_UnitTestContext() {
        this.now = System.now();
        this.today = System.today();
    }

    public zak_UnitTestContext( String key ) {
        this();
        this.key = key;
    }

    public zak_UnitTestContext( String key, Datetime now, Date today ) {
        this.now = now;
        this.today = today;
        this.key = key;
    }

    public zak_UnitTestContext intent( Type entity ) {
        if ( entity <> null ) intents.add( entity );
        return this;
    }

    public zak_UnitTestContext intent( Type[] entities ) {
        if ( entities <> null && ! entities.isEmpty() ) intents.addAll( entities );
        return this;
    }

    // creates template and returns reference to object (to allow chaining)
    // this is recommended way to add entities to the scope of the context.
    public zak_UnitTestRecord add( Type entity, SObject obj ) {
        if ( entity == null || obj == null ) return null;
        List<zak_UnitTestRecord> l = records.get( entity );
        if ( l == null ) {
            l = new List<zak_UnitTestRecord>();
            records.put( entity, l );
            scope.add( entity );
        }
        zak_UnitTestRecord rec = new zak_UnitTestRecord( obj );
        l.add( rec );
        return rec;
    }

    // adds multiple entities to the scope
    public zak_UnitTestContext add( Type[] entities ) {
        if ( entities <> null && ! entities.isEmpty() ) scope.addAll( entities );
        return this;
    }

    // adds multiple entities to the scope
    public zak_UnitTestContext add( Set<Type> entities ) {
        if ( entities <> null && ! entities.isEmpty() ) scope.addAll( entities );
        return this;
    }

    // adds one entity to the scope
    public zak_UnitTestContext add( Type entity ) {
        if ( entity <> null ) scope.add( entity );
        return this;
    }

    // returns list of templates, if no templates added then returns empty list
    public List<zak_UnitTestRecord> get( Type entity ) {
        if ( ! records.containsKey( entity ) ) return new List<zak_UnitTestRecord>();
        return records.get( entity );
    }

    public Boolean isInScope( Type entity ) {
        return scope.contains( entity );
    }

    public Boolean isIntent( Type entity ) {
        return intents.contains( entity );
    }

    // used internally by factory run to get set of all mentioned entities within the context
    public Set<Type> getTypes() {
        Set<Type> r = scope.clone();
        r.addAll( intents );
        return r;
    }

    // to be used in entities to resolve references. required should be set to false for
    // lookups which should be resolved only if explicitly set.
    public void resolve( zak_UnitTestRecord rec, Schema.SObjectField f, Type entity, Boolean required ) {
        if ( scope.contains( entity ) ) {
            SObject r = rec.sobj();
            SObject o = rec.get( f );
            if ( o == null ) {
                if ( required && ! r.isSet( f ) ) {
                    r.put( f, records.get( entity )[0].sobj().Id );
                }
            } else {
                if ( o.Id <> null ) r.put( f, o.Id );
            }
        }
    }

    // helper method to generate next index per sobject type within context
    private static Map<Type,Integer> indexes = new Map<Type,Integer>();
    public Integer getNextIndex( Type entity ) {
        Integer i = indexes.get( entity );
        if ( i == null ) { i = 0; }
        indexes.put( entity, ++i );
        return i;
    }

}