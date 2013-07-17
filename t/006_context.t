use strict;
use warnings;
use Test::More;

subtest normal => sub {
    use Nephia::Context;
    my $c = Nephia::Context->new( foo => 123, bar => { hoge => 'abc' } );
    is( $c->{foo}, 123, 'simple scalar' );
    isa_ok( $c->{bar}, 'HASH' );
    is( $c->{bar}{hoge}, 'abc', 'hash' );
};

done_testing;

