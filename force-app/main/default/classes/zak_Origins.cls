// origins is small class to trace dependencies between object Ids.
// used to simplify error handling from related records.
// addition of connections is cheap, resolving origin is expensive.
public class zak_Origins {

    private Set<ID> origins;
    private Map<ID,Set<ID>> ancestors = new Map<ID,Set<ID>>();

    public zak_Origins( Set<ID> origins ) {
        this.origins = origins;
    }

    // link descendant to ancenstor.
    public void add( ID descendant, ID ancestor ) {
        if ( ancestor == null || descendant == null || ancestor == descendant ) return;
        if ( origins.contains( descendant ) ) return;
        Set<ID> s = ancestors.get( descendant );
        if ( s == null ) ancestors.put( descendant, new Set<ID>{ ancestor } );
        else s.add( ancestor );
    }

    // unlinks descendant from all ancestors. returns true if there was any and false if there were
    // no connections.
    public Boolean remove( ID descendant ) {
        Set<ID> s = ancestors.remove( descendant );
        return s <> null && ! s.isEmpty();
    }

    // return list of origins linked to descendant
    public Set<ID> get( ID id ) {
        Set<ID> result = new Set<ID>();
        if ( id == null ) return result;
        if ( origins.contains( id ) ) {
            result.add( id );
            return result;
        }
        get( id, result );
        return result;
    }

    private void get( ID id, Set<ID> result ) {
        Set<ID> s = ancestors.get( id );
        if ( s == null ) return;
        for ( ID a : s ) {
            if ( origins.contains( a ) ) result.add( a );
            else get( a, result );
        }
    }

}