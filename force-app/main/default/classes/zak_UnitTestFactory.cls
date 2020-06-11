// factory's run is main method to prepare unit test data. it iterates over contexts and creates all the
// entities in scope of the run defined per context.
public virtual class zak_UnitTestFactory {

    public static void run( List<zak_UnitTestContext> contexts ) {
        zak_UnitTestFactory factory = new zak_UnitTestFactory();
        factory.contexts = contexts;
        factory.run();
    }

    public static void run( zak_UnitTestContext ctx ) {
        zak_UnitTestFactory factory = new zak_UnitTestFactory();
        factory.contexts = new List<zak_UnitTestContext>{ ctx };
        factory.run();
    }

    protected List<zak_UnitTestContext> contexts;

    protected virtual void run() {
        if ( contexts == null || contexts.isEmpty() ) throw new NoContextsException();
        // get all types mentioned in the contexts. intents also get added as explosion is done later.
        Set<Type> scope;
        if ( contexts.size() == 1 ) {
            scope = contexts[0].getTypes();
        } else {
            scope = new Set<Type>();
            for ( zak_UnitTestContext ctx : contexts ) scope.addAll( ctx.getTypes() );
        }
        List<Entity> entities = new Sequencer().sort( scope );

        addPermissions( entities );

        // fix scope for the contexts with dependencies
        for ( Integer i = entities.size() - 1; i >= 0; i-- ) {
            for ( zak_UnitTestContext ctx : contexts ) {
                Entity e = entities[i];
                if ( e.requires <> null && ctx.isInScope( e.entityType ) ) ctx.add( e.requires );
            }
        }

        // iterate over sequence of entities
        for ( Entity entity : entities ) {
            List<SObject> records = new List<SObject>();
            for ( zak_UnitTestContext ctx : contexts ) {
                if ( ctx.isInScope( entity.entityType ) ) {
                    Boolean none = true;
                    for ( zak_UnitTestRecord rec : ctx.get( entity.entityType ) ) {
                        entity.instance.link( ctx, rec );
                        records.add( rec.sobj() );
                        none = false;
                    }
                    if ( none ) {
                        SObject o = entity.instance.create();
                        if ( o <> null ) {
                            records.add( ctx.add( entity.entityType, entity.instance.link( ctx, o ) ).sobj() );
                        } else {
                            entity.instance.link( ctx, (zak_UnitTestRecord) null );
                        }
                    }
                }
            }
            if ( ! records.isEmpty() ) {
                if ( entity.runAs == null ) insert records;
                else System.runAs( entity.runAs ) { insert records; }
            }
        }
    }

    // create runAs users (if not created/Id not provided), add permission sets
    private void addPermissions( List<Entity> entities ) {
        // get all runAs users, matching permission sets and add them to the users. for inserted users
        // record Id should be provided (or user will be created again).
        List<User> users2insert = new List<User>();
        Set<String> names = new Set<String>();
        for ( Entity e : entities ) {
            if ( e.permissions <> null ) {
                names.addAll( e.permissions );
                if ( e.runAs <> null && e.runAs.Id == null ) {
                    Boolean add = true;
                    for ( User u : users2insert ) {
                        if ( e.runAs === u ) {
                            add = false;
                            break;
                        }
                    }
                    if ( add ) users2insert.add( e.runAs );
                }
            }
        }
        if ( ! names.isEmpty() ) {
            if ( ! users2insert.isEmpty() ) insert users2insert;
            List<String> n = new List<String>();
            for ( String s : names ) {
                String d = s.substringAfter( '.' );
                if ( d == null || d == '' ) n.add( s );
                else n.add( d );
            }
            Map<String,ID> permissionSets = new Map<String,ID>();
            for ( PermissionSet p : [select Id, NamespacePrefix, Name
                                       from PermissionSet
                                      where Name in :n] )
            {
                if ( p.NamespacePrefix == null ) {
                    permissionSets.put( p.Name, p.Id );
                } else {
                    permissionSets.put( p.NamespacePrefix + '.' + p.Name, p.Id );
                }
            }

            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for ( Entity e : entities ) {
                if ( e.permissions <> null ) {
                    for ( String s : e.permissions ) {
                        ID psid = permissionSets.get( s );
                        User u = e.runAs;
                        ID uid = u <> null && u.Id <> null ? u.Id : UserInfo.getUserId();
                        if ( psid <> null ) {
                            assignments.add( new PermissionSetAssignment( AssigneeId = uid, PermissionSetId = psid ) );
                        }
                    }
                }
            }
            insert assignments;
        }
    }

    public virtual void prerun() {}
    public virtual void postrun() {}

    // Entity class is used to pair Type and instance as Apex lacks getClass method.
    private class Entity {
        private Type entityType;
        private zak_UnitTestEntity instance;
        private Set<Type> requires;
        private User runAs;
        private List<String> permissions;
        private Entity( Type entityType, zak_UnitTestEntity instance ) {
            this.entityType = entityType;
            this.instance = instance;
            this.requires = instance.requires();
            if ( this.requires <> null ) {
                this.requires.remove( null );
                if ( this.requires.isEmpty() ) this.requires = null;
            }
            this.runAs = instance.runAs();
            this.permissions = instance.permissions();
        }
        // creates clone of requires for consumption in topological sorting.
        private Set<Type> requires2() {
            if ( requires == null ) return null;
            return requires.clone();
        }
    }

    // implements Kahn's algorithm for topological sorting. used to resolve sequence of creation
    // of entities.
    private class Sequencer {

        private List<Entity> sorted = new List<Entity>();
        private Map<Type,Set<Type>> dependencies = new Map<Type,Set<Type>>();
        private Map<Type,Set<Type>> prerequisites = new Map<Type,Set<Type>>();
        private Map<Type,zak_UnitTestEntity> entities = new Map<Type,zak_UnitTestEntity>();
        private List<Type> cleared = new List<Type>();

        private List<Entity> sort( Set<Type> scope ) {
            // initiate all the entities in scope and explode them
            for ( Type t : scope ) {
                addEntity( t );
            }
            // kahn's sorting. modifies requires list of entity
            while( cleared.size() > 0 ) {
                Type t = cleared.remove( cleared.size() - 1 );
                sorted.add( new Entity( t, entities.remove( t ) ) );
                Set<Type> deps = dependencies.get( t );
                if ( deps <> null ) {
                    for ( Type d : deps ) {
                        zak_UnitTestEntity e = entities.get( d );
                        Set<Type> reqs = prerequisites.get( d );
                        reqs.remove( t );
                        if ( reqs.isEmpty() ) cleared.add( d );
                    }
                }
            }
            if ( ! entities.isEmpty() ) throw new UnitTestCyclicReferenceException();
            return sorted;
        }

        private void addEntity( Type t ) {
            if ( entities.containsKey( t ) ) return;
            zak_UnitTestEntity e = (zak_UnitTestEntity) t.newInstance();
            entities.put( t, e );
            Set<Type> r = e.requires();
            if ( r == null ) {
                cleared.add( t );
            } else {
                prerequisites.put( t, r );
                for ( Type tt : r ) {
                    Set<Type> d = dependencies.get( tt );
                    if ( d == null ) dependencies.put( tt, new Set<Type>{ t } );
                    else d.add( t );
                    if ( ! entities.containsKey( tt ) ) {
                        addEntity( tt );
                    }
                }
            }
        }

    }

    public class NoContextsException extends Exception {}
    public class UnitTestCyclicReferenceException extends Exception {}

}