@isTest
private without sharing class zak_Utils_Test {

    @isTest
    static void testAll() {

        // getStrings and getIDs
        List<ID> ids = new List<ID>{ zak_Utils.nextId( Schema.Account.sObjectType )
                                   , zak_Utils.nextId( Schema.Account.sObjectType )
                                   , zak_Utils.nextId( Schema.Account.sObjectType ) };
        List<Account> accounts = new List<Account>{
            new Account( Id = ids[0], Name = 'A' )
          , new Account( Id = ids[1], Name = 'A' )
          , new Account( Id = ids[2], Name = 'B' )
          , new Account( Id = ids[1], Name = 'B' )
          , new Account( Id = ids[1], Name = 'B' )
          , new Account( Id = ids[0], Name = 'C' )
          , new Account( Id = ids[1], Name = 'C' )
          , new Account( Id = null, Name = 'C' )
          , new Account( Id = ids[2], Name = null )
        };
        Set<String> namesx = zak_Utils.getStrings( accounts, Schema.Account.Name );
        System.assertEquals( new Set<String>{ 'A', 'B', 'C' }, namesx, 'getStrings failed' );
        Set<ID> idsx = zak_Utils.getIDs( accounts, Schema.Account.Id );
        System.assertEquals( new Set<ID>{ ids[0], ids[1], ids[2] }, idsx, 'getIDs failed' );
        Map<String,List<Account>> m = (Map<String,List<Account>>) zak_Utils.assort( accounts, Schema.Account.Name );
        List<Account> a = m.get( 'A' );
        System.assertEquals( 2, a.size(), 'size of a' );
        System.assertEquals( ids[0], a[0].Id, 'a[0].Id' );
        System.assertEquals( ids[1], a[1].Id, 'a[1].Id' );
        List<Account> b = m.get( 'B' );
        System.assertEquals( 3, b.size(), 'size of b' );
        System.assertEquals( ids[2], b[0].Id, 'b[0].Id' );
        System.assertEquals( ids[1], b[1].Id, 'b[1].Id' );
        System.assertEquals( ids[1], b[2].Id, 'b[2].Id' );
        List<Account> c = m.get( 'C' );
        System.assertEquals( 3, c.size(), 'size of c' );
        System.assertEquals( ids[0], c[0].Id, 'c[0].Id' );
        System.assertEquals( ids[1], c[1].Id, 'c[1].Id' );
        System.assertEquals( null, c[2].Id, 'c[2].Id' );
        List<Account> nu = m.get( null );
        System.assertEquals( 1, nu.size(), 'size of null' );
        System.assertEquals( ids[2], nu[0].Id, 'nu[0].Id' );

        // hash
        System.assertEquals( 'a#b', zak_Utils.hash( 'a', 'b' ) );
        System.assertEquals( 'a#b#c', zak_Utils.hash( 'a', 'b', 'c' ) );
        System.assertEquals( 'a#b#c#d', zak_Utils.hash( 'a', 'b', 'c', 'd' ) );
        System.assertEquals( 'a#b#c#d#e', zak_Utils.hash( 'a', 'b', 'c', 'd', 'e' ) );

        // ns and trim
        System.assertEquals( '', zak_Utils.ns( null ), 'ns - null - failed' );
        System.assertEquals( 'a', zak_Utils.ns( 'a' ), 'ns - a - failed' );
        System.assertEquals( '', zak_Utils.ns( '' ), 'ns - blank - failed' );
        System.assertEquals( '', zak_Utils.trim( null ), 'ns - null - failed' );
        System.assertEquals( 'a', zak_Utils.trim( ' a ' ), 'ns - a - failed' );
        System.assertEquals( '', zak_Utils.trim( '' ), 'ns - blank - failed' );
        System.assertEquals( '', zak_Utils.trim( ' ' ), 'ns - space - failed' );

        System.assertEquals( 10, zak_Utils.genString( 10 ).length(), 'genString failed' );
        System.assertEquals( 10, zak_Utils.genLower( 10 ).length(), 'genLower failed' );

        System.assertEquals( true, zak_Utils.contains( 'teSta;teStb', 'testB' ), 'contains failed on true' );
        System.assertEquals( false, zak_Utils.contains( 'testa;testb', 'testc' ), 'contains failed on false' );
        System.assertEquals( 'teSta', zak_Utils.remove( 'teSta;teStb', 'testB' ), 'remove failed on testB' );
        System.assertEquals( 'teSta;testC', zak_Utils.remove( 'teSta;teStb;testC', 'tesTB' ), 'remove failed on tesTB' );
        System.assertEquals( 'teSta;teStb', zak_Utils.remove( 'teSta;teStb;testC', 'teStc' ), 'remove failed on teStc' );
        System.assertEquals( 'teSta;teStb;testC', zak_Utils.remove( 'teSta;teStb;testC', 'teStD' ), 'remove failed on teStD' );
        System.assertEquals( 'teSta;teStb', zak_Utils.add( 'teSta;teStb', 'testB' ), 'add failed on testB' );
        System.assertEquals( 'teSta;teStb;testC', zak_Utils.add( 'teSta;teStb', 'testC' ), 'add failed on testC' );

        // dates and time zones
        System.assertEquals( Time.newInstance( 09, 10, 11, 0 ), zak_Utils.parseTime( '09:10:11' ), 'time parsing failed' );
        System.assertEquals( Time.newInstance( 09, 11, 11, 0 ), zak_Utils.parseTime( '09:10:71' ), 'time parsing failed on overflow' );
        try {
            Time t = zak_Utils.parseTime( 'b:10:11' );
            System.assert( false, 'no exception on time format' );
        } catch ( Exception e ) {
            System.assert( e instanceof zak_Utils.TimeFormatException, 'exception is not time format exception' );
        }

        System.assertEquals( 0, zak_Utils.weekday( Date.newInstance( 2019, 12, 30 ) ), 'weekday failed' );
        System.assertEquals( 1, zak_Utils.weekday( Date.newInstance( 2019, 12, 31 ) ), 'weekday failed' );
        System.assertEquals( 2, zak_Utils.weekday( Date.newInstance( 2020, 1, 1 ) ), 'weekday failed' );
        System.assertEquals( 3, zak_Utils.weekday( Date.newInstance( 2020, 1, 2 ) ), 'weekday failed' );
        System.assertEquals( 4, zak_Utils.weekday( Date.newInstance( 2020, 1, 3 ) ), 'weekday failed' );
        System.assertEquals( 5, zak_Utils.weekday( Date.newInstance( 2020, 1, 4 ) ), 'weekday failed' );
        System.assertEquals( 6, zak_Utils.weekday( Date.newInstance( 2020, 1, 5 ) ), 'weekday failed' );

        Datetime dt = System.now();
        Date d = System.today();
        Time t = dt.time();
        TimeZone tz = UserInfo.getTimeZone();

        System.assertEquals( d, zak_Utils.getLocalDate( dt, String.valueOf ( tz ) ), 'getLocalDate(string) failed' );
        System.assertEquals( null, zak_Utils.getLocalDate( null, String.valueOf ( tz ) ), 'getLocalDate(string) failed' );

        System.assertEquals( d, zak_Utils.getLocalDate( dt, tz ), 'getLocalDate(tz) failed' );
        System.assertEquals( null, zak_Utils.getLocalDate( null, tz ), 'getLocalDate(tz) failed' );

        System.assertEquals( t, zak_Utils.getLocalTime( dt, String.valueOf ( tz ) ), 'getLocalTime(string) failed' );

        System.assertEquals( t, zak_Utils.getLocalTime( dt, tz ), 'getLocalTime(tz) failed' );

        System.assertEquals( dt, zak_Utils.getDatetime( d, t, tz ), 'v(tz) failed' );
        System.assertEquals( dt, zak_Utils.getDatetime( d, t, tz.toString() ), 'getDatetime failed' );

        String tzn = [select TimeZoneSidKey from Organization].TimeZoneSidKey;
        System.assertEquals( tzn, String.valueOf( zak_Utils.getOrgTimeZone() ), 'getOrgTimeZone failed' );

        // numbers
        System.assertEquals( 0, zak_Utils.nn( (Integer) null ), 'integer null' );
        System.assertEquals( 0, zak_Utils.nn( (Integer) 0 ), 'integer 0' );
        System.assertEquals( 1, zak_Utils.nn( (Integer) 1 ), 'integer 1' );
        System.assertEquals( 0, zak_Utils.nn( (Long) null ), 'long null' );
        System.assertEquals( 0, zak_Utils.nn( (Long) 0 ), 'long 0' );
        System.assertEquals( 1, zak_Utils.nn( (Long) 1 ), 'long 1' );
        System.assertEquals( 0, zak_Utils.nn( (Decimal) null ), 'decimal null' );
        System.assertEquals( 0, zak_Utils.nn( (Decimal) 0 ), 'decimal 0' );
        System.assertEquals( 1, zak_Utils.nn( (Decimal) 1 ), 'decimal 1' );

        // refinable
        List<A> rl = new List<A>{ new A( 'a', 2 ), new A( 'b', 1 ), new A( 'a', 1 ) };
        zak_Utils.refine( rl );
        System.assertEquals( 2, rl.size(), '2 As in refined list' );
        System.assertEquals( 2, rl[0].v, '1 a is correct' );
        System.assertEquals( 'b', rl[1].a, '2 a is correct' );
    }

    public class A implements zak_Utils.Refinable {
        String a;
        Integer v;
        A( String a, Integer v ) {
            this.a = a;
            this.v = v;
        }
        public String getKey() { return a; }
        public Boolean isNewerThan( Object prev ) {
            return this.v >= ( (A) prev ).v;
        }
    }

}