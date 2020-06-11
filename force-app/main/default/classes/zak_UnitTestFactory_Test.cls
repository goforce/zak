@isTest
private class zak_UnitTestFactory_Test {

    private static List<String> results = new List<String>();

    @isTest
    static void testAll() {
        Test.startTest();
        try {
            insert new PermissionSet( Name = 'zak_unit_test_permission', Label = 'zak_unit_test_permission' );
            zak_UnitTestFactory.run( new zak_UnitTestContext().add( A.class ) );
            System.assert( results[0] == 'D', 'D is first' );
            System.assert( results[1] == 'C', 'C is second' );
            System.assert( results[2] == 'B', 'B is third' );
            System.assert( results[3] == 'E', 'E is fourth' );
            System.assert( results[4] == 'A', 'A is last' );
            List<PermissionSetAssignment> psa = [select Id
                                                   from PermissionSetAssignment
                                                  where AssigneeId = :UserInfo.getUserId()
                                                    and PermissionSet.Name = 'zak_unit_test_permission'];
            System.assertEquals( 1, psa.size(), 'permissions added' );
        } catch ( Exception e ) {
            System.assert( true, 'no exceptions expected' );
        }
        // test exception on cyclic references
        try {
            zak_UnitTestFactory.run( new zak_UnitTestContext().add( L1.class ) );
            System.assert( true, 'no exception on cyclic references' );
        } catch ( zak_UnitTestSequencer.UnitTestCyclicReferenceException e ) {
            // do nothing
        } catch ( Exception e ) {
            System.assert( true, 'incorrect exception' );
        }
        Test.stopTest();
    }

    private virtual class A extends zak_UnitTestEntity {
        public override Set<Type> requires() { return new Set<Type>{ E.class, B.class }; }
        public override void link( zak_UnitTestContext ctx, zak_UnitTestRecord o ) { results.add( 'A' ); }
    }

    private class B extends zak_UnitTestEntity {
        public override Set<Type> requires() { return new Set<Type>{ C.class }; }
        public override User runAs() { return getMe(); }
        public override List<String> permissions() { return new List<String>{ 'zak_unit_test_permission' }; }
        public override void link( zak_UnitTestContext ctx, zak_UnitTestRecord o ) { results.add( 'B' ); }
    }

    private class C extends zak_UnitTestEntity {
        public override Set<Type> requires() { return new Set<Type>{ D.class }; }
        public override void link( zak_UnitTestContext ctx, zak_UnitTestRecord o ) { results.add( 'C' ); }
    }

    private class D extends zak_UnitTestEntity {
        public override Set<Type> requires() { return null; }
        public override void link( zak_UnitTestContext ctx, zak_UnitTestRecord o ) { results.add( 'D' ); }
    }

    private class E extends zak_UnitTestEntity {
        public override Set<Type> requires() { return new Set<Type>{ D.class, B.class, C.class }; }
        public override void link( zak_UnitTestContext ctx, zak_UnitTestRecord o ) { results.add( 'E' ); }
    }

    private class L1 extends zak_UnitTestEntity {
        public override Set<Type> requires() { return new Set<Type>{ L2.class }; }
        public override void link( zak_UnitTestContext ctx, zak_UnitTestRecord o ) { results.add( 'L1' ); }
    }

    private class L2 extends zak_UnitTestEntity {
        public override Set<Type> requires() { return new Set<Type>{ L3.class }; }
        public override void link( zak_UnitTestContext ctx, zak_UnitTestRecord o ) { results.add( 'L2' ); }
    }

    private class L3 extends zak_UnitTestEntity {
        public override Set<Type> requires() { return new Set<Type>{ L1.class }; }
        public override void link( zak_UnitTestContext ctx, zak_UnitTestRecord o ) { results.add( 'L3' ); }
    }

}