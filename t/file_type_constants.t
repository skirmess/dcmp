#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    ok( declared('App::DCMP::FILE_TYPE_DIRECTORY'), 'constant FILE_TYPE_DIRECTORY is defined' );
    ok( declared('App::DCMP::FILE_TYPE_OTHER'),     'constant FILE_TYPE_OTHER is defined' );
    ok( declared('App::DCMP::FILE_TYPE_REGULAR'),   'constant FILE_TYPE_REGULAR is defined' );
    ok( declared('App::DCMP::FILE_TYPE_SYMLINK'),   'constant FILE_TYPE_SYMLINK is defined' );

    done_testing();

    exit 0;
}

# copied from 'perldoc constant'
sub declared ($) {
    use constant 1.01;    # don't omit this!
    my $name = shift;
    $name =~ s/^::/main::/;
    my $pkg = caller;
    my $full_name = $name =~ /::/ ? $name : "${pkg}::$name";
    $constant::declared{$full_name};
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
