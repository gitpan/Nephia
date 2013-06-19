requires 'Class::Accessor::Lite';
requires 'JSON';
requires 'Plack';
requires 'Router::Simple';
requires 'Text::MicroTemplate::File';
requires 'URL::Encode';
requires 'parent';

recommends 'URL::Encode::XS';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
    requires 'perl', '5.010001';
};

on test => sub {
    requires 'Capture::Tiny';
    requires 'Guard';
    requires 'HTTP::Request::Common';
    requires 'Test::More', "0.98";
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
