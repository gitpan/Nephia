package MyApp::Oreore;

use strict;
use warnings;
use Nephia;

path '/oreore' => sub {
    my $req = shift;
    return $req->param('q') ? 
        { query => $req->param('q') } : 
        { message => 'input query' }
    ;
};

1;
