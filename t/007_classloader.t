use strict;
use warnings;
use Test::More;
use Nephia::ClassLoader;

ok( ! Nephia::ClassLoader->is_loaded('Nephia') );

ok( Nephia::ClassLoader->load('Nephia') );

ok( Nephia::ClassLoader->is_loaded('Nephia') );

done_testing;
