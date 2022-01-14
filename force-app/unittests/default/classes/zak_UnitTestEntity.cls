// Unit test entity defines step in test data preparation. In most cases entity is SObject which knows
// how to default fields so that insert would not fail. Entities should implement two main methods:
// link - defaults fields using context;
// make - takes list of records, resolves Ids from lookups (and refs) and inserts/updates them.
// Examples of entities could be from very general like Account to very granular like 
// ConsumerCustomerWithEmailOnlyAndLinkedIndividual.
public abstract class zak_UnitTestEntity {

    // returns SObjectType of the entity. May return null if entity is not represented by a record.
    public abstract Schema.SObjectType sObjectType();

    // initializes passed in record in context of ctx. if entity is represented by
    // record (code only entities) then it is linked just once per context.
    public abstract void link( Context ctx, SObject o );

    // make is final phase of factory run. called once per entity type for all entities
    // added to all contexts. make should resolve referenced sobjects to ids and insert/update.
    public virtual void make( List<SObject> records ) {
        List<SObject> r2upsert = new List<SObject>();
        for ( SObject o : records ) {
            this.resolve( o );
            r2upsert.add( o );
        }
logStart();
        upsert r2upsert;
logFinish();
    }

private static Long start = 0;
private void logStart() {
    system.debug( 'UTF> ' + this.sObjectType() + ' / ' + System.now().format( 'HH:mm:ss.SSS' ) );
    start = System.now().getTime();
}
private void logFinish() {
    Long finish = System.now().getTime();
    system.debug( 'UTF> ' + this.sObjectType() + ' / ' + System.now().format( 'HH:mm:ss.SSS' ) + ' / ' + ((Integer)(finish - start)) );
}

    // resolve lookups for the record. should be called before entity record is linked.
    // as pre-requisites have been created already and have Id fields populated then these
    // should be unwrap and set explicitly to lookup fields.
    public void resolve( SObject o ) {
        if ( o == null ) return;
        Map<String,Object> fm = o.getPopulatedFieldsAsMap();
        for ( String f : fm.keySet() ) {
            Object v = fm.get( f );
            if ( v instanceof SObject ) {
                Schema.SObjectField ft = getFieldToken( o.getSObjectType(), f );
                if ( ! o.isSet( ft ) ) o.put( ft, ((SObject) v)?.Id );
            }
        }
    }

    public SObject create() {
        Schema.SObjectType sot = this.sObjectType();
        if ( sot == null ) return null;
        return sot.newSObject();
    }

    // default method sets field value if it was not set before. it returns value of the field after default.
    // do not use default method for polymorphic fields, instead use hasRef and ref methods.
    public static Object default( SObject o, SObjectField f, Object value ) {
        if ( value instanceof SObject ) {
            if ( o.isSet( f ) ) return o.get( f );
            SObject r = o.getSObject( f );
            if ( r <> null ) return r;
            r = (SObject) value;
            ID id = r?.Id;
            if ( id <> null ) {
                o.Id = id;
                return id;
            } else {
                o.putSObject( f, r );
                return r;
            }
        }
        if ( o.isSet( f ) ) return o.get( f );
        o.put( f, value );
        return value;
    }

    // shortcut for default
    public static Object def( SObject o, SObjectField f, Object value ) {
        return default( o, f, value );
    }

    // in complex multi-package developments substitutes allow to replace on implementation
    // of the entity with another in cases when entities are created implicitly (as pre-requisites)
    // substitutes should be initialized before any entities get added to the contexts.
    private static Map<Type,Type> substitutes = new Map<Type,Type>();

    // adds substitute s for type t
    public static void substitute( Type t, Type s ) {
        substitutes.put( t, s );
    }

    // validates that t is Entity type and returns either t or type which should be used as substitute for t.
    public static Type validate( Type t ) {
        Type s = substitutes.get( t );
        if ( s == null ) {
            if ( ! zak_UnitTestEntity.class.isAssignableFrom( t ) ) {
                throw new EntityException( 'ERROR: ' + t + ' is not subclass of zak_UnitTestEntity' );
            }
            return t;
        }
        return s;
    }

    public interface Context {}

    /* --------------------- metadata and caching --------------------- */
    private static Map<SObjectType,DescribeInfo> describes = new Map<SObjectType,DescribeInfo>();

    private static DescribeInfo describe( SObjectType t ) {
        if ( t == null ) return null;
        DescribeInfo d = describes.get( t );
        if ( d == null ) {
            d = new DescribeInfo( t );
            describes.put( t, d );
        }
        return d;
    }

    private class DescribeInfo {
        private Map<String,Schema.RecordTypeInfo> recordTypesByDeveloperName;
        private Map<ID,Schema.RecordTypeInfo> recordTypesById;
        private Map<String,SObjectField> fields;
        private Map<String,SObjectField> lookups;
        private DescribeInfo( SObjectType t ) {
            Schema.DescribeSObjectResult r = t.getDescribe();
            this.recordTypesByDeveloperName = r.getRecordTypeInfosByDeveloperName();
            this.recordTypesById = r.getRecordTypeInfosById();
            this.fields = r.fields.getMap();
        }
        private SObjectField getFieldToken( String fieldName ) {
            SObjectField t = this.fields.get( fieldName.toLowerCase() );
            if ( t <> null ) return t;
            if ( lookups == null ) {
                this.lookups = new Map<String,SObjectField>();
                for( SobjectField f : this.fields.values() ) {
                    String rn = f.getDescribe().getRelationshipName();
                    if ( rn <> null ) {
                        this.lookups.put( rn.toLowerCase(), f );
                    }
                }
            }
            return this.lookups.get( fieldName.toLowerCase() );
        }
    }

    public static void setRecordType( SObject o, String devName ) {
        DescribeInfo d = describe( o.getSObjectType() );
        o.put( 'RecordTypeId', d?.recordTypesByDeveloperName?.get( devName )?.getRecordTypeId() );
    }

    public static String getRecordType( SObject o ) {
        ID recordTypeId = (ID) o.get( 'RecordTypeId' );
        DescribeInfo d = describe( o.getSObjectType() );
        return d?.recordTypesById?.get( recordTypeId )?.getDeveloperName();
    }

    public static SObjectField getFieldToken( SObjectType t, String fn ) {
        if ( t == null || fn == null ) return null;
        return describe( t )?.getFieldToken( fn );
    }

    /* --------------------- util methods --------------------- */

    // counter per sobjecttype to generate unique keys
    private static Map<SObjectType,Integer> nexts = new Map<SObjectType,Integer>();
    public static Integer next( SObjectType t ) {
        Integer i = nexts.get( t );
        if ( i == null ) i = 0;
        i++;
        nexts.put( t, i );
        return i;
    }
    public Integer next() {
        return next( this.sObjectType() );
    }

    public static final String alphanums = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    // generates random string
    public static String genString( Integer len ) {
        return genString( len, alphanums );
    }

    public static final String loweralphanums = '0123456789abcdefghijklmnopqrstuvwxyz';
    public static String genLower( Integer len ) {
        return genString( len, loweralphanums );
    }

    public static String genString( Integer len, String chars ) {
        String r = '';
        while ( r.length() < len ) {
           Integer idx = Math.mod( Math.abs( Crypto.getRandomInteger() ), chars.length() );
           r += chars.substring( idx, idx + 1 );
        }
        return r;
    }

    public class EntityException extends Exception {}

}