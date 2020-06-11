@isTest
private class zak_Utils_Test {

    @isTest
    static void testAll() {
        // getStrings and getIDs
        List<Account> accounts = new List<Account>{
            new Account( Id = '001000000000001', Name = 'A' )
          , new Account( Id = '001000000000002', Name = 'A' )
          , new Account( Id = '001000000000003', Name = 'B' )
          , new Account( Id = '001000000000002', Name = 'B' )
          , new Account( Id = '001000000000002', Name = 'B' )
          , new Account( Id = '001000000000001', Name = 'C' )
          , new Account( Id = '001000000000002', Name = 'C' )
          , new Account( Id = null, Name = 'C' )
          , new Account( Id = '001000000000003', Name = null )
        };
        Set<String> names = zak_Utils.getStrings( accounts, Schema.Account.Name );
        System.assertEquals( new Set<String>{ 'A', 'B', 'C' }, names, 'getStrings failed' );
        Set<ID> ids = zak_Utils.getIDs( accounts, Schema.Account.Id );
        System.assertEquals( new Set<ID>{ '001000000000001', '001000000000002', '001000000000003' }, ids, 'getIDs failed' );
        // hash
        System.assertEquals( 'a#b#c#d#e', zak_Utils.hash( 'a', 'b', 'c', 'd', 'e' ) );
        // ns and trim
        System.assertEquals( '', zak_Utils.ns( null ), 'ns - null - failed' );
        System.assertEquals( 'a', zak_Utils.ns( 'a' ), 'ns - a - failed' );
        System.assertEquals( '', zak_Utils.ns( '' ), 'ns - blank - failed' );
        System.assertEquals( '', zak_Utils.trim( null ), 'ns - null - failed' );
        System.assertEquals( 'a', zak_Utils.trim( ' a ' ), 'ns - a - failed' );
        System.assertEquals( '', zak_Utils.trim( '' ), 'ns - blank - failed' );
        System.assertEquals( '', zak_Utils.trim( ' ' ), 'ns - space - failed' );
        // user profile
        String n = [select Id, Name from Profile where Id = :UserInfo.getProfileId()].Name;
        System.assertEquals( n, zak_Utils.getUserProfile(), 'getUserProfile failed' );
        // dates and time zones
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

        String tzn = [select TimeZoneSidKey from Organization].TimeZoneSidKey;
        System.assertEquals( tzn, String.valueOf( zak_Utils.getOrgTimeZone() ), 'getOrgTimeZone failed' );

    }

}