#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd qw(cwd);
use Data::Dumper;
use Encode;
use POSIX qw(setlocale LC_ALL);

use lib qw(.);

main();

sub main {

    my $basedir = cwd();
    chdir tempdir();

    note('locale');
    print STDERR `locale`;

    my @names = ( 'e', 'E', 'f', 'F', '1', '2', '10', encode( 'UTF-8', "\x{20ac}" ), encode( 'UTF-8', "\x{00C0}" ), encode( 'UTF-8', "\x{0041}\x{0300}" ) );

    # create files
    for my $name (@names) {
        open my $fh, '>', "$name.txt";
        close $fh;
    }

    # get "reference sorting" by ls
    my @ls = `ls -1`;
    chomp @ls;

    #
    chdir $basedir;

    # sort with "sort"
    use locale;
    my @names_sorted = sort map { "$_.txt" } @names;

    note('@names_sorted');
    print STDERR Dumper( \@names_sorted );

    note('@ls');
    print STDERR Dumper( \@ls );

    is_deeply( \@names_sorted, \@ls, 'sort sorts the same way as ls' );

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
