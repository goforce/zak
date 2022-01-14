// scope, context and container classes could be considered same with slightly different interfaces and use cases.
// base class is container which is set of test data records.
// scope contains container and provides methods to add new records to the scope.
// context could be overwritten and implements zak_UnitTestEntity.Context which allows to provide default values and
// manages linking and injection of pre-requisites into the container.
public without sharing virtual class zak_UnitTestScope {

    private Context ctx;

    public zak_UnitTestScope( Context ctx ) {
        this.ctx = ctx == null ? new Context() : ctx;
    }

    // adds single entity sobject from initialised obj.
    public SObject add( Type t, SObject o ) {
        this.ctx.cnt.append( t ).sobjects.add( o );
        return o;
    }

    // adds multiple entity sobjects from initialised objs.
    public List<SObject> add( Type t, List<SObject> l ) {
        for ( SObject o : l ) {
            this.ctx.cnt.append( t ).sobjects.add( o );
        }
        return l;
    }

    // adds one entity to the scope.
    public SObject add( Type t ) {
        t = zak_UnitTestEntity.validate( t );
        Entity e = this.ctx.cnt.append( t );
        SObject o = e.instance.create();
        e.sobjects.add( o );
        return o;
    }

    // returns list of sobjects, if no sobjects added then returns empty list.
    public List<SObject> get( Type t ) {
        t = zak_UnitTestEntity.validate( t );
        if ( ! this.ctx.cnt.contains( t ) ) return new List<SObject>();
        return this.ctx.cnt.get( t ).sobjects;
    }

    // link is called from factory to start linking phase.
    public List<Entity> link() {
        return ctx.link();
    }

    // context is meant to be overwritten and provide properties to be used in entity definition as default values.
    // context provides methods to add pre-requisites during entity definition (must, one).
    public virtual class Context implements zak_UnitTestEntity.Context {

        private Container cnt = new Container();

        public Datetime now { protected set; public get; }
        public Date today { protected set; public get; }
        public String currencyIsoCode { protected set; public get; }

        public Context() {
            this.now = System.now();
            this.today = System.today();
            this.currencyIsoCode = 'EUR';
        }

        public Context( Datetime now, Date today, String currencyIsoCode ) {
            this.now = now;
            this.today = today;
            this.currencyIsoCode = currencyIsoCode;
        }

        // to be used in entity link method to get first record of type or create one if there is none.
        // new entity will be set as prerequisite for currently linking entity.
        public SObject must( Type t ) {
            Entity e;
            t = zak_UnitTestEntity.validate( t );
            if ( this.cnt.entities.containsKey( t ) ) {
                e = this.cnt.entities.get( t );
                if ( this.run <> null ) this.run.requires.add( t );
                return e.sobjects[0];
            }
            return this.one( t );
        }

        // one adds new entity instance to scope and adds it as pre-requisite.
        public SObject one( Type t ) {
            Entity e = this.cnt.add( t );
            SObject o = e.instance.create();
            e.sobjects.add( o );
            push( e );
            e.instance.link( this, o );
            pop();
            if ( this.run <> null ) this.run.requires.add( t );
            return o;
        }

        // starts factory run (linking) of the context. factory run scope is populated as contexts get linked.
        private List<Entity> link() {
            List<Entity> scope = new List<Entity>( this.cnt.entities.values() );
            for ( Entity e : scope ) {
                push( e );
                for ( SObject o : e.sobjects ) {
                    e.instance.link( this, o );
                }
                pop();
            }
            return new List<Entity>( this.cnt.entities.values() );
        }
        // run is current entity linking. as must() may add new entities to the context then
        // these are linked immmediately unfolding dependency tree.
        private Entity run;
        private List<Entity> runs = new List<Entity>();
        // push current run to stack and set new run as current
        private void push( Entity run ) {
            runs.add( run );
            this.run = run;
        }
        private void pop() {
            runs.remove( runs.size() - 1 );
            this.run = runs.size() >= 1 ? runs[runs.size() - 1] : null;
        }
    }

    // container is used to keep entities added to the scope. same container is shared between context and scope.
    public class Container {

        private final Map<Type,Entity> entities = new Map<Type,Entity>();

        // get returns entity from the container.
        private Entity get( Type t ) {
            return entities.get( zak_UnitTestEntity.validate( t ) );
        }

        // add returns entity from the container. if not added before then it adds entity to the container.
        private Entity add( Type t ) {
            t = zak_UnitTestEntity.validate( t );
            Entity e = entities.get( t );
            if ( e <> null ) return e;
            e = new Entity( t );
            entities.put( e.t, e );
            return e;
        }

        // append returns entity from the container. if not added before then it will add entity to the container
        // and add all the entities in the container as pre-requisites for the entity (this is done only on first append).
        private Entity append( Type t ) {
            t = zak_UnitTestEntity.validate( t );
            if ( entities.containsKey( t ) ) {
                return entities.get( t );
            }
            Set<Type> requires = entities.keySet().clone();
            Entity e = new Entity( t );
            e.requires = requires;
            entities.put( e.t, e );
            return e;
        }

        // contains returns true if entity was added to the container.
        private Boolean contains( Type t ) {
            return entities.containsKey( zak_UnitTestEntity.validate( t ) );
        }

    }

    // entity is used by container to keep definition, pre-requisites and records added to the container.
    public class Entity {
        public Type t;
        public zak_UnitTestEntity instance;
        public Set<Type> requires = new Set<Type>();
        private List<SObject> sobjects = new List<SObject>();
        private Entity( Type t ) {
            this.t = t;
            this.instance = (zak_UnitTestEntity) this.t.newInstance();
        }
    }

    public class ScopeException extends Exception {}

}