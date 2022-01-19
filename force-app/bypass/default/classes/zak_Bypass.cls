public without sharing class zak_Bypass {

    private static Node root;

    // variant of isEnabled exposed as invocable method to be used in flows. labeled Is Bypass Enabled in category Platform.
    @InvocableMethod( label = 'Is Bypass Enabled'
                      description = 'Returns true if bypass has been enabled for automation.'
                      category = 'Platform' )
    public static List<Boolean> isEnabled( List<String> paths ) {
        if ( root == null ) {
            root = init();
        }
        List<Boolean> results = new List<Boolean>();
        for ( String path : paths ) {
            results.add( root.match( path ) );
        }
        return results;
    }

    // returns true if path can by bypassed.
    public static Boolean isEnabled( String path ) {
        if ( root == null ) {
            root = init();
        }
        return root.match( path );
    }

    // adds path to be bypassed. returns true if path already was added before.
    // if any of segments is empty then false is returned and no path added.
    public static Boolean add( String path ) {
        if ( root == null ) {
            root = init();
        }
        return root.add( path );
    }

    // removes path from to be bypassed. returns true if it was set to be bypassed.
    public static Boolean remove( String path ) {
        if ( root == null ) {
            root = init();
        }
        return root.remove( path );
    }

    private static Node init() {
        Node root = new Node();
        for ( zak_BypassMapping__mdt meta : zak_BypassMapping__mdt.getAll().values() ) {
            String path = meta.Path__c;
            if ( path == null || path == '' ) continue;
            if ( meta.EntityType__c == 'PERMISSIONS' ) {
                if ( FeatureManagement.checkPermission( meta.Entity__c ) ) {
                    root.add( path );
                }
            } else if ( meta.EntityType__c == 'SETTINGS' ) {
                zak_Bypass__c s = zak_Bypass__c.getInstance();
                if ( s.get( meta.Entity__c ) == true ) {
                    root.add( path );
                }
            }
        }
        return root;
    }

    private class Node {
        private Map<String,Node> edges = new Map<String,Node>();
        private Boolean stop = false;
        private Boolean add( String path ) {
            if ( ! String.isBlank( path ) ) {
                List<String> p = path.toLowerCase().split( '\\.' );
                if ( p.size() > 0 ) {
                    return add( p, 0 );
                }
            }
            return false;
        }
        // recursively adds idx item from path array to the node
        // if any of path elements is empty then no bypass will be added and false will be returned
        private Boolean add( List<String> path, Integer idx ) {
            if ( path.size() <= idx ) {
                return put( true );
            }
            if ( String.isBlank( path[idx] ) ) {
                return false;
            }
            Node next = edges.get( path[idx] );
            if ( next == null ) {
                next = new Node();
                edges.put( path[idx], next );
            }
            return next.add( path, idx + 1 );
        }
        private Boolean remove( String path ) {
            if ( ! String.isBlank( path ) ) {
                List<String> p = path.toLowerCase().split( '\\.' );
                if ( p.size() > 0 ) {
                    return remove( p, 0 );
                }
            }
            return false;
        }
        // clear stop on node matching path. branch itself is not removed.
        private Boolean remove( List<String> path, Integer idx ) {
            if ( path.size() <= idx ) {
                return put( false );
            }
            if ( String.isBlank( path[idx] ) ) {
                return false;
            }
            Node next = edges.get( path[idx] );
            if ( next <> null ) {
                return next.remove( path, idx + 1 );
            }
            return false;
        }
        private Boolean match( String path ) {
            if ( ! String.isBlank( path ) ) {
                List<String> p = path.toLowerCase().split( '\\.' );
                if ( p.size() > 0 ) {
                    return match( p, 0 );
                }
            }
            return false;
        }
        private Boolean match( List<String> path, Integer idx ) {
            if ( stop || path.size() <= idx ) {
                return stop;
            }
            if ( String.isBlank( path[idx] ) ) {
                return false;
            }
            Node next = edges.get( path[idx] );
            if ( next <> null && next.match( path, idx + 1 ) ) {
                return true;
            }
            next = edges.get( '*' );
            if ( next <> null ) {
                return next.match( path, idx + 1 );
            }
            return false;
        }
        private Boolean put( Boolean stop ) {
            Boolean b = this.stop;
            this.stop = stop;
            return b;
        }
    }

}
