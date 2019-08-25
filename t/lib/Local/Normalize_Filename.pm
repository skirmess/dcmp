package Local::Normalize_Filename;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Test::Builder;
use Test::TempDir::Tiny;

use Cwd qw(cwd);

use FindBin qw($RealBin);
use lib "$RealBin/lib";

use Local::Test::Util;

# If the OS/filesystem normalizes the Unicode file name, the file name read
# with readdir might return a UTF-8 string that differs from the UTF-8 string
# that was used to create the file. OS/X does that. This function is used to
# normalize the file name in the same way.
{
    my %normalized_filename;
    my $test = Local::Test::Util->new;

    sub normalize_filename {
        my ($filename) = @_;

        if ( !exists $normalized_filename{$filename} ) {
            my $tmpdir  = tempdir();
            my $basedir = cwd();

            $test->chdir($tmpdir);
            $test->touch($filename);

            my $fh;
            if ( !opendir $fh, q{.} ) {
                Test::Builder->new->BAIL_OUT("opendir .: $!");
            }

            my @dents = grep { $_ ne q{.} && $_ ne q{..} } readdir $fh;

            if ( !closedir $fh ) {
                Test::Builder->new->BAIL_OUT("opendir .: $!");
            }

            $test->chdir($basedir);

            die "Expected a single file in $tmpdir but got " . scalar(@dents) . " for $filename: " . join( q{ }, @dents ) . "\n" if @dents != 1;

            $normalized_filename{$filename} = $dents[0];
        }

        return $normalized_filename{$filename};
    }
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl

