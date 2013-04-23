use inc::Module::Install;
name 'Nephia';
all_from 'lib/Nephia.pm';

requires 'Exporter';
requires 'Plack';
requires 'JSON';
requires 'Text::Xslate';
requires 'Data::Validator';
requires 'Class::Load';
requires 'Class::Accessor::Fast';
requires 'Class::Accessor::Lite';
requires 'Config::Micro';
requires 'Encode';
requires 'Router::Simple';
requires 'Path::Class' => 0.26;
requires 'Cwd';
requires 'File::Spec';
requires 'File::Basename';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Mouse::Util::TypeConstraints';

install_script 'bin/nephia-setup';

auto_set_repository;
auto_include;
WriteAll;
