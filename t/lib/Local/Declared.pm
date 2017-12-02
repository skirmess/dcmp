package Local::Declared;

use 5.006;
use strict;
use warnings;

# copied from 'perldoc constant'
sub declared ($) {
    use constant 1.01;    # don't omit this!
    my $name = shift;
    $name =~ s/^::/main::/xsm;
    my $pkg = caller;
    my $full_name = $name =~ /::/xsm ? $name : "${pkg}::$name";
    return $constant::declared{$full_name};
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
