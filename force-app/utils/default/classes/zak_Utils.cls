// useful utility methods
public inherited sharing virtual class zak_Utils {

    // ------------------------- sobject related methods ------------------------- //

    // getStrings returns set of String of field values from the list of SObjects.
    // null values are removed
    // shortcut to retrieve data used in filtering
    public static Set<String> getStrings( List<SObject> records, Schema.SObjectField f ) {
        Set<String> s = new Set<String>();
        if ( records == null ) return s;
        for ( SObject rec : records ) {
            s.add( (String) rec.get( f ) );
        }
        s.remove( null );
        return s;
    }

    // getIDs returns set of Ids of field values from the list of SObjects.
    // null values are removed
    // shortcut to retrieve data used in filtering
    public static Set<ID> getIds( List<SObject> records, Schema.SObjectField f ) {
        Set<ID> s = new Set<ID>();
        if ( records == null ) return s;
        for ( SObject rec : records ) {
            s.add( (ID) rec.get( f ) );
        }
        s.remove( null );
        return s;
    }

    // assort sobjects by value of the field of type string.
    public static Map<String,List<SObject>> assort( List<SObject> records, Schema.SObjectField f ) {
        Map<String,List<SObject>> m = new Map<String,List<SObject>>();
        if ( records == null || records.isEmpty() ) return m;
        for ( SObject rec : records ) {
            String k = (String) rec.get( f );
            List<SObject> l = m.get( k );
            if ( l == null ) {
                m.put( k, new List<SObject>{ rec } );
            } else {
                l.add( rec );
            }
        }
        return m;
    }

    // ------------------------- string related methods ------------------------- //

    // hash used to concatenate strings to produce key. segments are separated with # to make it readable in
    // debug log.
    private static final String SEP = '#';
    public static String hash( String a, String b ) { return a + SEP + b; }
    public static String hash( String a, String b, String c ) { return a + SEP + b + SEP + c; }
    public static String hash( String a, String b, String c, String d ) { return a + SEP + b + SEP + c + SEP + d; }
    public static String hash( String a, String b, String c, String d, String e ) { return a + SEP + b + SEP + c + SEP + d + SEP + e; }

    // returns same string or empty string for null.
    public static String ns( String s ) {
        return s == null ? '' : s;
    }

    // returns trimmed string or empty string for null.
    public static String trim( String s ) {
        return s == null ? '' : s.trim();
    }

    // check that picklist value is selected in multi-picklist this is case insensitive
    public static Boolean isSelected( String fieldValue, String value ) {
        if ( fieldValue == null || value == null ) return false;
        Integer fl = fieldValue.length();
        Integer l = value.length();
        for ( Integer i = fieldValue.indexOfIgnoreCase( value ); i >= 0; i = fieldValue.indexOfIgnoreCase( value, ++i ) ) {
            if ( ( i == 0 || fieldValue.mid( i - 1, 1 ) == ';' ) && ( ( i + l ) == fl || fieldValue.mid( i + l, 1 ) == ';'  ) ) return true;
        }
        return false;
    }

    // ------------------------- date/time related methods ------------------------- //

    // parse time in hh:mm:ss format
    public static Time parseTime( String f ) {
        try {
            Integer h, m, s;
            if ( f == null || f == '' ) return null;
            List<String> l = f.split( ':' );
            if ( l.size() > 0 ) h = Integer.valueOf( l[0] );
            if ( l.size() > 1 ) m = Integer.valueOf( l[1] );
            if ( l.size() > 2 ) s = Integer.valueOf( l[2] );
            return Time.newInstance( h, m, s, 0 );
        } catch ( Exception e ) {
            throw new TimeFormatException( 'incorrect time format: "' + f + '"' );
        }
    }
    public class TimeFormatException extends Exception {}

    // returns weekday, 0 for monday and 6 for sunday
    private static final Date MONDAY = Date.newInstance( 1900, 1, 1 );
    public static Integer weekDay( Date d ) {
        return Math.mod( MONDAY.daysBetween( d ), 7 );
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

    // ------------------------- number related methods ------------------------- //

    // returns same number or 0 for null.
    public static Long nn( Long n ) {
        return n == null ? 0 : n;
    }
    public static Integer nn( Integer n ) {
        return n == null ? 0 : n;
    }
    public static Decimal nn( Decimal n ) {
        return n == null ? 0 : n;
    }

    // ------------------------- unit test related methods ------------------------- //

    private static Integer idCounter = 1;
    // generate dummy 15 char ID for sobject type. to be used only in unit tests.
    public static ID nextId( Schema.SObjectType t ) {
        if ( t == null ) return null;
        String prefix = t.getDescribe().getKeyPrefix();
        return prefix + String.valueOf( idCounter++ ).leftPad( 12, '0' );
    }

    public static final String alphanums = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    // generates random string from upper and lower case latin letters and numbers
    public static String genString( Integer len ) {
        return genString( len, alphanums );
    }

    public static final String loweralphanums = '0123456789abcdefghijklmnopqrstuvwxyz';
    // generates randow string from lower case latin letters and numbers
    public static String genLower( Integer len ) {
        return genString( len, loweralphanums );
    }

    // generates random string of length len from set of characters in chars
    public static String genString( Integer len, String chars ) {
        String r = '';
        while ( r.length() < len ) {
           Integer idx = Math.mod( Math.abs( Crypto.getRandomInteger() ), chars.length() );
           r += chars.substring( idx, idx + 1 );
        }
        return r;
    }

    // ------------------------- generic patterns ------------------------- //

    // refinable are used in services accepting array of inputs. these inputs should be
    // refined to remove duplicates and keep the newest versions only.
    public interface Refinable {
        String getKey();
        Boolean isNewerThan( Object prev );
    }
    public static void refine( List<Refinable> scope ) {
        Map<String,Refinable> m = new Map<String,Refinable>();
        for ( Refinable r : scope ) {
            String key = r.getKey();
            Refinable prev = m.get( key );
            if ( prev == null || r.isNewerThan( prev ) ) {
                m.put( key, r );
            }
        }
        scope.clear();
        for ( Refinable r : m.values() ) scope.add( r );
    }

}