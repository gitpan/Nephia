package t::Util;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw( test_config );

sub test_config () {
    +{
        view => {
            path => [ 't/nephia-test_app/view' ],
        },
    };
}

1;
