use strict;
use warnings;
use Test::More;

subtest normal => sub {
    use Nephia::Context;
    my $c = Nephia::Context->new( foo => 123, bar => { hoge => 'abc' } );
    is( $c->{foo}, 123, 'simple scalar' );
    isa_ok( $c->{bar}, 'HASH' );
    is( $c->{bar}{hoge}, 'abc', 'hash' );
    $c->set(baz => 'xyz');
    my @rtn = $c->get(qw/foo baz/);
    is( $rtn[0], 123, 'get by array 1st');
    is( $rtn[1], 'xyz', 'get by array 2nd');
};

done_testing;

