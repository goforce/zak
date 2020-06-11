// different (mostly static) utility methods
public virtual class zak_Utils {

    // ------------------------- sobject related methods ------------------------- //

    // getStrings returns set of String of field values from the list of SObjects.
    // null values are removed
    // shortcut to retrieve data used in filtering
    public static Set<String> getStrings( List<SObject> records, Schema.SObjectField f ) {
        Set<String> s = new Set<String>();
        if ( records == null ) return s;
        for ( SObject rec : records ) s.add( (String) rec.get( f ) );
        s.remove( null );
        return s;
    }

    // getIDs returns set of IDs of field values from the list of SObjects.
    // null values are removed
    // shortcut to retrieve data used in filtering
    public static Set<ID> getIDs( List<SObject> records, Schema.SObjectField f ) {
        Set<ID> s = new Set<ID>();
        if ( records == null ) return s;
        for ( SObject rec : records ) s.add( (ID) rec.get( f ) );
        s.remove( null );
        return s;
    }

    // ------------------------- string related methods ------------------------- //

    // hash used to concatenate strings to produce key. segments are separated with # to make it readable in
    // debug log.
    public static String hash( String a, String b ) { return a + '#' + b; }
    public static String hash( String a, String b, String c ) { return a + '#' + b + '#' + c; }
    public static String hash( String a, String b, String c, String d ) { return a + '#' + b + '#' + c + '#' + d; }
    public static String hash( String a, String b, String c, String d, String e ) { return a + '#' + b + '#' + c + '#' + d + '#' + e; }

    // returns same string or empty string for null.
    public static String ns( String s ) { return s == null ? '' : s; }

    // returns trimmed string or empty string for null.
    public static String trim( String s ) { return s == null ? '' : s.trim(); }

    // ------------------------- user related methods ------------------------- //

    private static String userProfileName;
    public static String getUserProfile() {
        if ( userProfileName <> null ) return userProfileName;
        if ( UserInfo.getProfileId() == null ) userProfileName = null;
        else userProfileName = zak_UserProfiles.getProfileName( UserInfo.getProfileId() );
        return userProfileName;
    }

    // ------------------------- date/time related methods ------------------------- //

    // returns weekday, 0 for monday and 6 for sunday
    private static final Date monday = Date.newInstance( 1900, 1, 1 );
    public static Integer weekDay( Date d ) {
        return Math.mod( monday.daysBetween( d ), 7 );
    }

    // get local Date for Datetime in TimeZone z. Use values from User.TimeZoneSidKey.getDescribe().getPicklistValues().
    // unknown time zones are considered GMT.
    public static Date getLocalDate( Datetime t, String z ) {
        if ( t == null || z == null )return null;
        return( getLocalDate( t, TimeZone.getTimeZone( z ) ) );
    }

    // get local Date for Datetime in TimeZone z.
    public static Date getLocalDate( Datetime t, TimeZone z ) {
        if ( t == null || z == null ) return null;
        return Datetime.newInstance( t.getTime() + z.getOffset( t ) ).dateGMT();
    }

    // get local Time for Datetime t in TimeZone z. Use values from User.TimeZoneSidKey.getDescribe().getPicklistValues().
    // unknown time zones are considered GMT.
    public static Time getLocalTime( Datetime t, String z ) {
        if ( t == null || z == null )return null;
        return( getLocalTime( t, TimeZone.getTimeZone( z ) ) );
    }

    // get local Time for Datetime t in TimeZone z.
    public static Time getLocalTime( Datetime t, TimeZone z ) {
        if ( t == null || z == null ) return null;
        return Datetime.newInstance( t.getTime() + z.getOffset( t ) ).timeGMT();
    }

    // get GMT/UTC Datetime from local Date and Time in TimeZone z. Use values from User.TimeZoneSidKey.getDescribe().getPicklistValues().
    // unknown time zones are considered GMT.
    public static Datetime getDatetime( Date d, Time t, String z ) {
        return getDatetime( d, t, TimeZone.getTimeZone( z ) );
    }

    // get GMT/UTC Datetime from local Date and Time in TimeZone z.
    public static Datetime getDatetime( Date d, Time t, TimeZone z ) {
        if ( d == null || t == null ||z == null ) return null;
        Datetime dt = Datetime.newInstanceGMT( d, t );
        return Datetime.newInstance( dt.getTime() - z.getOffset( dt ) );
    }

    // get org default time zone
    private static TimeZone tz;
    public static TimeZone getOrgTimeZone() {
        if ( tz <> null ) return tz;
        String tzn = [select TimeZoneSidKey from Organization].TimeZoneSidKey;
        tz = TimeZone.getTimeZone( tzn );
        return tz;
    }

}