package Nephia::Setup;
use strict;
use warnings;
use Nephia::Setup::Base;

use Module::Load ();

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
            my ($flavor_class, $required_modules, $additional_methods) = $class->load_flavor($setup, $flavor);
            my $_dh = *{$flavor_class.'::DATA'}{IO};
            push @template_data, (<$_dh>) if $_dh;

            $setup->_set_required_modules( $required_modules );

            for my $module (@{$additional_methods}) {
                $setup->{additional_methods}->{$module} = 1;
            }
        }
    }
    $setup->_parse_template_data( @template_data );

    return $setup;
}

sub load_flavor {
    my ($class, $setup, $flavor) = @_;

    my $flavor_class = $class.'::'.$flavor;
    Module::Load::load($flavor_class);

    my $flavor_rtn = $flavor_class->can('on_load') ? $flavor_class->on_load($setup) : undef;
    if (ref($flavor_rtn) =~ /^Nephia::Setup::/) {
        $setup = $flavor_rtn if $flavor_rtn->isa('Nephia::Setup::Base');
    }

    $class->_export_flavor_functions($flavor_class);

    my ($required_modules, $additional_methods);
    {
        no strict 'refs';
        $required_modules = $flavor_class->can('required_modules') ? { &{$flavor_class.'::required_modules'} } : {};
        $additional_methods = $flavor_class->can('additional_methods') ? [ &{$flavor_class.'::additional_methods'} ] : [];
    }

    return ($flavor_class, $required_modules, $additional_methods);
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
    require Nephia;
    return $Nephia::VERSION;
}

1;
