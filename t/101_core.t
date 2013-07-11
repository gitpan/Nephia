use strict;
use warnings;
use utf8;
use Test::More;

use Nephia::Core;
pass 'Nephia::Core loaded';

can_ok __PACKAGE__, qw/
   get post put del path 
   req res param path_param nip 
   run config app 
   nephia_plugins base_dir 
   cookie set_cookie
/;

my @raw    = qw/Hoge +Piyo::Piyo/;
my @plugins = Nephia::Core::normalize_plugin_names(@raw);
is_deeply \@plugins, [qw/Nephia::Plugin::Hoge Piyo::Piyo/];
is_deeply \@raw,     [qw/Hoge +Piyo::Piyo/];

done_testing;
