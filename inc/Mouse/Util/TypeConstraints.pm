#line 1
package Mouse::Util::TypeConstraints;
use Mouse::Util; # enables strict and warnings

use Mouse::Meta::TypeConstraint;
use Mouse::Exporter;

use Carp         ();
use Scalar::Util ();

Mouse::Exporter->setup_import_methods(
    as_is => [qw(
        as where message optimize_as
        from via

        type subtype class_type role_type duck_type
        enum
        coerce

        find_type_constraint
        register_type_constraint
    )],
);

our @CARP_NOT = qw(Mouse::Meta::Attribute);

my %TYPE;

# The root type
$TYPE{Any} = Mouse::Meta::TypeConstraint->new(
    name => 'Any',
);

my @builtins = (
    # $name    => $parent,   $code,

    # the base type
    Item       => 'Any',     undef,

    # the maybe[] type
    Maybe      => 'Item',    undef,

    # value types
    Undef      => 'Item',    \&Undef,
    Defined    => 'Item',    \&Defined,
    Bool       => 'Item',    \&Bool,
    Value      => 'Defined', \&Value,
    Str        => 'Value',   \&Str,
    Num        => 'Str',     \&Num,
    Int        => 'Num',     \&Int,

    # ref types
    Ref        => 'Defined', \&Ref,
    ScalarRef  => 'Ref',     \&ScalarRef,
    ArrayRef   => 'Ref',     \&ArrayRef,
    HashRef    => 'Ref',     \&HashRef,
    CodeRef    => 'Ref',     \&CodeRef,
    RegexpRef  => 'Ref',     \&RegexpRef,
    GlobRef    => 'Ref',     \&GlobRef,

    # object types
    FileHandle => 'GlobRef', \&FileHandle,
    Object     => 'Ref',     \&Object,

    # special string types
    ClassName  => 'Str',       \&ClassName,
    RoleName   => 'ClassName', \&RoleName,
);

while (my ($name, $parent, $code) = splice @builtins, 0, 3) {
    $TYPE{$name} = Mouse::Meta::TypeConstraint->new(
        name      => $name,
        parent    => $TYPE{$parent},
        optimized => $code,
    );
}

# parametarizable types
$TYPE{Maybe}   {constraint_generator} = \&_parameterize_Maybe_for;
$TYPE{ArrayRef}{constraint_generator} = \&_parameterize_ArrayRef_for;
$TYPE{HashRef} {constraint_generator} = \&_parameterize_HashRef_for;

# sugars
sub as          ($) { (as          => $_[0]) } ## no critic
sub where       (&) { (where       => $_[0]) } ## no critic
sub message     (&) { (message     => $_[0]) } ## no critic
sub optimize_as (&) { (optimize_as => $_[0]) } ## no critic

sub from    { @_ }
sub via (&) { $_[0] } ## no critic

# type utilities

sub optimized_constraints { # DEPRECATED
    Carp::cluck('optimized_constraints() has been deprecated');
    return \%TYPE;
}

undef @builtins;        # free the allocated memory
@builtins = keys %TYPE; # reuse it
sub list_all_builtin_type_constraints { @builtins }
sub list_all_type_constraints         { keys %TYPE }

sub _define_type {
    my $is_subtype = shift;
    my $name;
    my %args;

    if(@_ == 1 && ref $_[0] ){    # @_ : { name => $name, where => ... }
        %args = %{$_[0]};
    }
    elsif(@_ == 2 && ref $_[1]) { # @_ : $name => { where => ... }
        $name = $_[0];
        %args = %{$_[1]};
    }
    elsif(@_ % 2) {               # @_ : $name => ( where => ... )
        ($name, %args) = @_;
    }
    else{                         # @_ : (name => $name, where => ...)
        %args = @_;
    }

    if(!defined $name){
        $name = $args{name};
    }

    $args{name} = $name;

    my $parent = delete $args{as};
    if($is_subtype && !$parent){
        $parent = delete $args{name};
        $name   = undef;
    }

    if(defined $parent) {
        $args{parent} = find_or_create_isa_type_constraint($parent);
    }

    if(defined $name){
        # set 'package_defined_in' only if it is not a core package
        my $this = $args{package_defined_in};
        if(!$this){
            $this = caller(1);
            if($this !~ /\A Mouse \b/xms){
                $args{package_defined_in} = $this;
            }
        }

        if(defined $TYPE{$name}){
            my $that = $TYPE{$name}->{package_defined_in} || __PACKAGE__;
            if($this ne $that) {
                my $note = '';
                if($that eq __PACKAGE__) {
                    $note = sprintf " ('%s' is %s type constraint)",
                        $name,
                        scalar(grep { $name eq $_ } list_all_builtin_type_constraints())
                            ? 'a builtin'
                            : 'an implicitly created';
                }
                Carp::croak("The type constraint '$name' has already been created in $that"
                          . " and cannot be created again in $this" . $note);
            }
        }
    }

    $args{constraint} = delete $args{where}        if exists $args{where};
    $args{optimized}  = delete $args{optimized_as} if exists $args{optimized_as};

    my $constraint = Mouse::Meta::TypeConstraint->new(%args);

    if(defined $name){
        return $TYPE{$name} = $constraint;
    }
    else{
        return $constraint;
    }
}

sub type {
    return _define_type 0, @_;
}

sub subtype {
    return _define_type 1, @_;
}

sub coerce { # coerce $type, from $from, via { ... }, ...
    my $type_name = shift;
    my $type = find_type_constraint($type_name)
        or Carp::croak("Cannot find type '$type_name', perhaps you forgot to load it");

    $type->_add_type_coercions(@_);
    return;
}

sub class_type {
    my($name, $options) = @_;
    my $class = $options->{class} || $name;

    # ClassType
    return subtype $name => (
        as           => 'Object',
        optimized_as => Mouse::Util::generate_isa_predicate_for($class),
        class        => $class,
    );
}

sub role_type {
    my($name, $options) = @_;
    my $role = $options->{role} || $name;

    # RoleType
    return subtype $name => (
        as           => 'Object',
        optimized_as => sub {
            return Scalar::Util::blessed($_[0])
                && Mouse::Util::does_role($_[0], $role);
        },
        role         => $role,
    );
}

sub duck_type {
    my($name, @methods);

    if(ref($_[0]) ne 'ARRAY'){
        $name = shift;
    }

    @methods = (@_ == 1 && ref($_[0]) eq 'ARRAY') ? @{$_[0]} : @_;

    # DuckType
    return _define_type 1, $name => (
        as           => 'Object',
        optimized_as => Mouse::Util::generate_can_predicate_for(\@methods),
        message      => sub {
            my($object) = @_;
            my @missing = grep { !$object->can($_) } @methods;
            return ref($object)
                . ' is missing methods '
                . Mouse::Util::quoted_english_list(@missing);
        },
        methods      => \@methods,
    );
}

sub enum {
    my($name, %valid);

    if(!(@_ == 1 && ref($_[0]) eq 'ARRAY')){
        $name = shift;
    }

    %valid = map{ $_ => undef }
        (@_ == 1 && ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_);

    # EnumType
    return _define_type 1, $name => (
        as            => 'Str',
        optimized_as  => sub{
            return defined($_[0]) && !ref($_[0]) && exists $valid{$_[0]};
        },
    );
}

sub _find_or_create_regular_type{
    my($spec, $create)  = @_;

    return $TYPE{$spec} if exists $TYPE{$spec};

    my $meta = Mouse::Util::get_metaclass_by_name($spec);

    if(!defined $meta){
        return $create ? class_type($spec) : undef;
    }

    if(Mouse::Util::is_a_metarole($meta)){
        return role_type($spec);
    }
    else{
        return class_type($spec);
    }
}

sub _find_or_create_parameterized_type{
    my($base, $param) = @_;

    my $name = sprintf '%s[%s]', $base->name, $param->name;

    $TYPE{$name} ||= $base->parameterize($param, $name);
}

sub _find_or_create_union_type{
    return if grep{ not defined } @_; # all things must be defined
    my @types = sort
        map{ $_->{type_constraints} ? @{$_->{type_constraints}} : $_ } @_;

    my $name = join '|', @types;

    # UnionType
    $TYPE{$name} ||= Mouse::Meta::TypeConstraint->new(
        name              => $name,
        type_constraints  => \@types,
    );
}

# The type parser

# param : '[' type ']' | NOTHING
sub _parse_param {
    my($c) = @_;

    if($c->{spec} =~ s/^\[//){
        my $type = _parse_type($c, 1);

        if($c->{spec} =~ s/^\]//){
            return $type;
        }
        Carp::croak("Syntax error in type: missing right square bracket in '$c->{orig}'");
    }

    return undef;
}

# name : [\w.:]+
sub _parse_name {
    my($c, $create) = @_;

    if($c->{spec} =~ s/\A ([\w.:]+) //xms){
        return _find_or_create_regular_type($1, $create);
    }
    Carp::croak("Syntax error in type: expect type name near '$c->{spec}' in '$c->{orig}'");
}

# single_type : name param
sub _parse_single_type {
    my($c, $create) = @_;

    my $type  = _parse_name($c, $create);
    my $param = _parse_param($c);

    if(defined $type){
        if(defined $param){
            return _find_or_create_parameterized_type($type, $param);
        }
        else {
            return $type;
        }
    }
    elsif(defined $param){
        Carp::croak("Undefined type with parameter [$param] in '$c->{orig}'");
    }
    else{
        return undef;
    }
}

# type : single_type  ('|' single_type)*
sub _parse_type {
    my($c, $create) = @_;

    my $type = _parse_single_type($c, $create);
    if($c->{spec}){ # can be an union type
        my @types;
        while($c->{spec} =~ s/^\|//){
            push @types, _parse_single_type($c, $create);
        }
        if(@types){
            return _find_or_create_union_type($type, @types);
        }
    }
    return $type;
}


sub find_type_constraint {
    my($spec) = @_;
    return $spec if Mouse::Util::is_a_type_constraint($spec) or not defined $spec;

    $spec =~ s/\s+//g;
    return $TYPE{$spec};
}

sub register_type_constraint {
    my($constraint) = @_;
    Carp::croak("No type supplied / type is not a valid type constraint")
        unless Mouse::Util::is_a_type_constraint($constraint);
    return $TYPE{$constraint->name} = $constraint;
}

sub find_or_parse_type_constraint {
    my($spec) = @_;
    return $spec if Mouse::Util::is_a_type_constraint($spec) or not defined $spec;

    $spec =~ tr/ \t\r\n//d;

    my $tc = $TYPE{$spec};
    if(defined $tc) {
        return $tc;
    }

    my %context = (
        spec => $spec,
        orig => $spec,
    );
    $tc = _parse_type(\%context);

    if($context{spec}){
        Carp::croak("Syntax error: extra elements '$context{spec}' in '$context{orig}'");
    }

    return $TYPE{$spec} = $tc;
}

sub find_or_create_does_type_constraint{
    # XXX: Moose does not register a new role_type, but Mouse does.
    my $tc = find_or_parse_type_constraint(@_);
    return defined($tc) ? $tc : role_type(@_);
}

sub find_or_create_isa_type_constraint {
    # XXX: Moose does not register a new class_type, but Mouse does.
    my $tc = find_or_parse_type_constraint(@_);
    return defined($tc) ? $tc : class_type(@_);
}

1;
__END__

#line 640


