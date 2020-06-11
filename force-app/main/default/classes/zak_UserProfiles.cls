// use zak_Settings: cache-partition to cache profiles or all will be cached in apex map per session only.
// all profiles are read at once.
// avoid requesting profile with non-existing Id, it will trigger re-query of all profiles.
public class zak_UserProfiles {

    private static final String CACHE_KEY;
    static {
        String s = zak_Settings.get( zak_Keys.SETTINGS_CACHE_PARTITION, null );
        CACHE_KEY = s == null ? null : s + '.UserProfiles';
    }

    private static Map<Id,String> userProfiles = new Map<Id,String>();

    public static String getProfileName( ID profileId ) {
        // check cached in memory then cached in platform cache
        String n = userProfiles.get( profileId );
        if ( n <> null ) return n;
        if ( userProfiles.containsKey( profileId ) ) return null;
        if ( CACHE_KEY <> null ) {
            try {
                Map<Id,String> m = (Map<Id,String>) Cache.Org.get( CACHE_KEY );
                if ( m <> null ) {
                    userProfiles.putAll( m );
                    n = userProfiles.get( profileId );
                    if ( n <> null ) return n;
                    if ( userProfiles.containsKey( profileId ) ) return null;
                }
            } catch ( Exception e ) {
                zak_ErrorLog.log( 'zak_UserProfiles', e );
            }
        }
        String cp = zak_Settings.get( zak_Keys.SETTINGS_CACHE_PROFILES, null );
        if ( cp <> null ) {
            List<String> l = cp.split( ',' );
            for ( Profile p : [select Id, Name from Profile where Id = :profileId or Name in :l] ) {
                userProfiles.put( p.Id, p.Name );
            }
            // add non-existing profile id to avoid requery
            if ( ! userProfiles.containsKey( profileId ) ) userProfiles.put( profileId, null );
        } else {
            List<Profile> p = [select Id, Name from Profile where Id = :profileId];
            if ( p.size() > 0 ) userProfiles.put( p[0].Id, p[0].Name );
            else userProfiles.put( p[0].Id, null );
        }
        if ( CACHE_KEY <> null ) {
            try {
                Cache.Org.put( CACHE_KEY, userProfiles, 172800 );
            } catch ( Exception e ) {
                zak_ErrorLog.log( 'zak_UserProfiles', e );
            }
        }
        return userProfiles.get( profileId );
    }

}