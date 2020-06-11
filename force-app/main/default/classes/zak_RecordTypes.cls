// optimise record type Id mapping by using cache. for noticeable performance increase platform cache should be used.
// it means zak_Defaults should be created and cache-partition setting should be added pointing to valid partition.
// it is highly recommended to keep record types and profiles (along with other low volume objects) be cached in
// separate partition so that values are not evicted till max time-to-live (48 hours).
// avoid requesting Id of non-existing record types as missing Id invalidates cached record types of the sobject
// and re-populates values. It allows to avoid cache reset after deployments or manual changes thou.
// for more information read Platform Cache Considerations in Apex Developer Guide.
public class zak_RecordTypes {

    private static final String CACHE_KEY;
    static {
        String s = zak_Settings.get( zak_Keys.SETTINGS_CACHE_PARTITION, null );
        CACHE_KEY = s == null ? null : s + '.RecordTypes';
    }

    private static Map<SObjectType,Map<String,ID>> recordTypes = new Map<SObjectType,Map<String,ID>>();

    // returns Id of Record Type for sobj and developer name.
    public static ID getRecordTypeId( SObjectType sobj, String developerName ) {
        Map<String,ID> m = recordTypes.get( sobj );
        if ( m <> null ) {
            ID id = m.get( developerName );
            if ( id <> null ) return id;
        }
        // if Id was not found try to re-read cache
        if ( CACHE_KEY <> null ) {
            try {
                Map<SObjectType,Map<String,ID>> mm = (Map<SObjectType,Map<String,ID>>) Cache.Org.get( CACHE_KEY );
                if ( mm <> null ) {
                    recordTypes.putAll( mm );
                    m = mm.get( sobj );
                    if ( m <> null ) {
                        ID id = m.get( developerName );
                        if ( id <> null ) return id;
                    }
                }
            } catch ( Exception e ) {
                zak_ErrorLog.log( 'zak_RecordTypes', e );
            }
        }
        Map<String,RecordTypeInfo> d = sobj.getDescribe().getRecordTypeInfosByDeveloperName();
        m = new Map<String,ID>();
        for ( String s : d.keySet() ) {
            m.put( s, d.get( s ).getRecordTypeId() );
        }
        // if requested record type has not been found even after explicit describe it is added with null Id
        ID id = m.get( developerName );
        if ( id == null ) m.put( developerName, null );
        recordTypes.put( sobj, m );
        if ( CACHE_KEY <> null ) {
            try {
                Cache.Org.put( CACHE_KEY, recordTypes, 172800 );
            } catch ( Exception e ) {
                zak_ErrorLog.log( 'zak_RecordTypes', e );
            }
        }
        return id;
    }

}