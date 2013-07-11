package Nephia::View::MicroTemplate;
use strict;
use warnings;
use Text::MicroTemplate::File;
use Carp;

sub new {
    my ( $class, %opts ) = @_;
    $opts{include_path} ||= [ delete $opts{template_path} ];
    my $mt = Text::MicroTemplate::File->new(%opts);
    bless {mt => $mt}, $class;
}

sub render {
    my ( $self, $file, @params ) = @_;
    $self->{mt}->render_file($file, @params);
}

1;
