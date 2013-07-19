use strict;
use warnings;
use Test::More;
use Nephia::PluginLoader;

is Nephia::PluginLoader::_normalize_plugin_name('Hoge'), 'Nephia::Plugin::Hoge', '_normalize_plugin_name Hoge';
is Nephia::PluginLoader::_normalize_plugin_name('+Piyo::Piyo'), 'Piyo::Piyo', '_normalize_plugin_name +Piyo::Piyo';

done_testing;
