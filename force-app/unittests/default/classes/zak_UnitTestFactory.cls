// factory's run is main method to prepare unit test data. it iterates over contexts and creates all the
// entities in scope of the run defined per context.
public virtual class zak_UnitTestFactory {

    public static void run( List<zak_UnitTestScope> scopes ) {
        zak_UnitTestFactory factory = new zak_UnitTestFactory();
        factory.scopes = scopes;
        factory.run();
    }

    public static void run( zak_UnitTestScope scope ) {
        zak_UnitTestFactory factory = new zak_UnitTestFactory();
        factory.scopes = new List<zak_UnitTestScope>{ scope };
        factory.run();
    }

    protected List<zak_UnitTestScope> scopes;

    protected virtual void run() {
system.debug( 'factory run start: ' + Limits.getCpuTime() + ' / ' + Limits.getHeapSize() );

        if ( scopes == null || scopes.isEmpty() ) throw new NoScopeException( 'no scope(s) added to the factory.' );

        Map<Type,zak_UnitTestScope.Entity> entities = new Map<Type,zak_UnitTestScope.Entity>();

        // run through scopes and link all records + prerequisites will get added if not there
        for ( zak_UnitTestScope scope : scopes ) {
            for ( zak_UnitTestScope.Entity e : scope.link() ) {
                zak_UnitTestScope.Entity x = entities.get( e.t );
                if ( x == null ) {
                    entities.put( e.t, e );
                } else {
                    x.requires.addAll( e.requires );
                }
            }
        }

system.debug( 'factory run linked: ' + Limits.getCpuTime() + ' / ' + Limits.getHeapSize() );
        List<zak_UnitTestScope.Entity> ordered = new Sequencer().sort( entities.values() );
system.debug( 'factory run sequenced: ' + Limits.getCpuTime() + ' / ' + Limits.getHeapSize() );

        // iterate over sequence of entities
        for ( zak_UnitTestScope.Entity e : ordered ) {
            List<SObject> l = new List<SObject>();
            for ( zak_UnitTestScope scope : scopes ) {
                List<SObject> sobjects = scope.get( e.t );
                if ( sobjects <> null ) {
                    l.addAll( sobjects );
                }
            }
            e.instance.make( l );
        }
system.debug( 'factory run end: ' + Limits.getCpuTime() + ' / ' + Limits.getHeapSize() );
    }

    // implements Kahn's algorithm for topological sorting. used to resolve sequence of creation
    // of entities.
    private class Sequencer {

        private Map<Type,zak_UnitTestScope.Entity> scope = new Map<Type,zak_UnitTestScope.Entity>();

        private List<zak_UnitTestScope.Entity> sorted = new List<zak_UnitTestScope.Entity>();
        private Map<Type,Set<Type>> dependencies = new Map<Type,Set<Type>>();
        private Map<Type,Set<Type>> prerequisites = new Map<Type,Set<Type>>();
        private Map<Type,zak_UnitTestScope.Entity> entities = new Map<Type,zak_UnitTestScope.Entity>();
        private List<Type> cleared = new List<Type>();

        private List<zak_UnitTestScope.Entity> sort( List<zak_UnitTestScope.Entity> scope ) {
            for ( zak_UnitTestScope.Entity e : scope ) {
                this.scope.put( e.t, e );
            }
            // initiate all the entities in scope and explode them
            for ( zak_UnitTestScope.Entity e : scope ) {
                addEntity( e );
            }
            // kahn's sorting. modifies requires list of entity
            while( cleared.size() > 0 ) {
                Type t = cleared.remove( cleared.size() - 1 );
                sorted.add( entities.remove( t ) );
                Set<Type> deps = dependencies.get( t );
                if ( deps <> null ) {
                    for ( Type d : deps ) {
                        zak_UnitTestScope.Entity e = entities.get( d );
                        Set<Type> reqs = prerequisites.get( d );
                        reqs.remove( t );
                        if ( reqs.isEmpty() ) cleared.add( d );
                    }
                }
            }
            if ( ! entities.isEmpty() ) throw new UnitTestCyclicReferenceException();
            return sorted;
        }

        private void addEntity( zak_UnitTestScope.Entity e ) {
            if ( entities.containsKey( e.t ) ) return;
            entities.put( e.t, e );
            if ( e.requires == null || e.requires.size() == 0 ) {
                cleared.add( e.t );
            } else {
                prerequisites.put( e.t, e.requires );
                for ( Type t : e.requires ) {
                    Set<Type> d = dependencies.get( t );
                    if ( d == null ) dependencies.put( t, new Set<Type>{ e.t } );
                    else d.add( e.t );
                    addEntity( scope.get( t ) );
                }
            }
        }

    }

    public class NoScopeException extends Exception {}
    public class UnitTestCyclicReferenceException extends Exception {}

}