package Nephia::View::MicroTemplate;
use strict;
use warnings;
use Text::MicroTemplate::File;
use File::Spec;
use Carp;
use Data::Dumper;

sub new {
    my ( $class, %opts ) = @_;
    $opts{include_path} ||= ["$FindBin::Bin/view"];
    my $mt = Text::MicroTemplate::File->new(%opts);
    bless {mt => $mt}, $class;
}

sub render {
    my ( $self, $file, @params ) = @_;
    $self->{mt}->render_file($file, @params);
}

1;
