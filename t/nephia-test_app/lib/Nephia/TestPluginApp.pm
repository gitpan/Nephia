package Nephia::TestPluginApp;
use strict;
use warnings;
use utf8;
use Nephia plugins => [qw/Bark/, 'Macopy' => {wei => 'うぇーい'}];

our $VERSION = 0.37;

path '/bark' => sub {
    bark();
};

path '/wei' => sub {
    wei();
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
