@isTest
private class c_UnitTestTest {

    @isTest
    static void testAll() {
        TestContext ctx = new TestContext();
        c_UnitTest.Scope scope = new c_UnitTest.Scope( ctx );
        scope.add( TestChildEntity.class );
        c_UnitTest.Factory.run( scope );
        System.assertEquals( true, ctx.works, 'it works' );
        List<SObject> os = scope.get( TestParentEntity.class );
        System.assertEquals( 1, os.size(), 'there is one account in scope' );
        Account a = (Account) os[0];
        System.assertEquals( 'unit-test', a.Name );
        System.assertEquals( '12', sequence, 'sequence of actions is correct' );
    }

    static String sequence = '';

    private class TestContext extends c_UnitTest.Context {
        private String testString = 'unit-test';
        public Boolean works = false;
    }

    private class TestParentEntity extends c_UnitTest.Entity {
        public override Schema.SObjectType sObjectType() {
            return Schema.Account.sObjectType;
        }
        public override void link( c_UnitTest.Context ctx, SObject o ) {
            TestContext c = (TestContext) ctx;
            System.assertEquals( 'unit-test', c.testString, 'context passed' );
            c.works = true;
            def( o, Schema.Account.Name, c.testString );
            def( o, Schema.Account.AccountNumber, String.valueOf( next( Schema.Account.sObjectType ) ) );
        }
        public override void make( List<SObject> os ) {
            System.assertEquals( 1, os.size(), 'one account only' );
            Account a = (Account) os[0];
            System.assertEquals( 'unit-test', a.Name );
            sequence += '1';
        }
    }

    private class TestChildEntity extends c_UnitTest.Entity {
        public override Schema.SObjectType sObjectType() {
            return Schema.Contact.sObjectType;
        }
        public override void link( c_UnitTest.Context ctx, SObject o ) {
            TestContext c = (TestContext) ctx;
            System.assertEquals( 'unit-test', c.testString, 'context passed' );
            c.works = true;
            def( o, Schema.Contact.LastName, c.testString );
            def( o, Schema.Contact.AccountId, ctx.must( TestParentEntity.class ) );
        }
        public override void make( List<SObject> os ) {
            System.assertEquals( 1, os.size(), 'one contact only' );
            Contact c = (Contact) os[0];
            System.assertEquals( 'unit-test', c.LastName );
            sequence += '2';
        }
    }

}
