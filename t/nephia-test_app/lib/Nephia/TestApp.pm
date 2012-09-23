package Nephia::TestApp;
use strict;
use warnings;
use Nephia;
use Mouse::Util::TypeConstraints;
use utf8;

our $VERSION = 0.01;

enum 'Sex' => qw( male female shemale );

path '/' => sub {
    return {
        template => 'index.tx',
        title => 'Nephia::TestApp',
    };
};

path '/json' => sub {
    my $query = req->param('q');
    return $query ? 
        { query => $query, message => 'Query OK' } :
        { message => 'Please input a query' }
    ;
};

path '/direct/js' => sub {
    return res {
        content_type( 'text/javascript' );
        body('console.log("foobar");');
    };
};

path '/validate' => sub {
    return validate 
        name => { isa => 'Str' },
        age => { isa => 'Int', default => 72 },
        sex => { isa => 'Sex', default => 'shemale'}
    ;
};

path '/configtest' => sub {
    return config;
};

path '/nihongo' => sub {
    return {
        template => 'index.tx',
        title => '日本語であそぼ',
    };
};

1;
__END__

=head1 NAME

Nephia-TestApp - Test Web Application for Nephia

=head1 SYNOPSIS

  $ plackup

=head1 DESCRIPTION

Nephia::TestApp is web application based Nephia.

=head1 AUTHOR

ytnobody

=head1 SEE ALSO

Nephia

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
