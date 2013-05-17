package Nephia::Plugin::Bark;
use Exporter 'import';
our @EXPORT = qw[ bark barkbark ];

sub bark {
    return [200, [], ['Bark!']];
}

sub barkbark {
    return [200, [], [join(' ', 'Bark', @_)]];
}
  
1;

