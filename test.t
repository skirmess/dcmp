#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More 0.88;
use Test::TempDir::Tiny;

use Encode;

main();

sub main {
    chdir tempdir();

    my $c = 1;
    for my $suffix ( q{}, "_\x{20ac}", "_\x{00C0}", "_\x{0041}\x{0300}" ) {
        open my $fh, '>', "file$c$suffix";
        $c++;
    }

    print STDERR "\n";
    my $fh;
    opendir $fh, '.';
    while (my $dent = readdir $fh) {
        next if $dent eq '.' || $dent eq '..';
        for my $x (split //, $dent) {
            printf STDERR "0x%02X ", ord($x);
        }
        print STDERR "\t";
        print STDERR "$dent\n";

        my $dent2 = encode('UTF-8', decode('UTF-8', $dent));
        for my $x (split //, $dent2) {
            printf STDERR "0x%02X ", ord($x);
        }
        print STDERR "\t";
        print STDERR "$dent2\n";

        print STDERR "\n";
    }

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl

