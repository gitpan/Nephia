package Nephia::Setup;
use strict;
use warnings;
use Nephia::ClassLoader;
use Nephia::Setup::Base;

sub new {
    my ( $class, %opts ) = @_;
    $opts{flavor} ||= [];

    my $flavors = delete $opts{flavor};
    my $setup = Nephia::Setup::Base->new( %opts );

    my @template_data = ();
    {
        no strict 'refs';

        my $dh = *{'Nephia::Setup::Base::DATA'}{IO};
        push @template_data, (<$dh>);

        for my $flavor (sort {($b =~ /^View::/) <=> ($a =~ /^View::/)} @$flavors) {
            my $flavor_class = $class->load_flavor($setup, $flavor);
            my $_dh = *{$flavor_class.'::DATA'}{IO};
            push @template_data, (<$_dh>) if $_dh;
        }
    }
    $setup->_parse_template_data( @template_data );

    return $setup;
}

sub load_flavor {
    my ($class, $setup, $flavor) = @_;

    my $flavor_class = $class.'::'.$flavor;
    Nephia::ClassLoader->load($flavor_class);

    my $flavor_rtn = $flavor_class->can('on_load') ? $flavor_class->on_load($setup) : undef;
    if (ref($flavor_rtn) =~ /^Nephia::Setup::/) {
        $setup = $flavor_rtn if $flavor_rtn->isa('Nephia::Setup::Base');
    }

    $class->_export_flavor_functions($flavor_class);
    return $flavor_class;
}

sub _export_flavor_functions {
    my ($class, $flavor_class) = @_;
    {
        no strict 'refs';
        my @funcs = grep { $_ =~ /^[a-z]/ && $_ !~ /^(import|on_load)$/ } keys %{$flavor_class.'::'};
        *{'Nephia::Setup::Base::'.$_} = *{$flavor_class.'::'.$_} for @funcs;
    }
}

sub get_version {
    my $class = shift;
    my $version;
    {
        use Nephia ();
        $version = $Nephia::VERSION;
        no Nephia;
    };
    return $version;
}

1;
