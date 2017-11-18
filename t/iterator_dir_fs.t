#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd qw(cwd);
use Encode;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my @suffixes = ( q{}, "_\x{20ac}", "_\x{00C0}", "_\x{0041}\x{0300}" );

    if ( $^O ne 'MSWin32' ) {
        push @suffixes, "a\nb";
    }

    my $collect_file_info = sub {
        App::DCMP::_collect_file_info(@_);
    };

    my $basedir = cwd();

    my $symlink_supported = 0;
    {
        no autodie;
        eval {
            symlink q{}, q{};
            $symlink_supported = 1;
        };
    }

    for my $suffix (@suffixes) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix" ) );

        {
            my $file_a         = "a${suffix}.txt";
            my $file_a_utf8    = encode( 'UTF-8', $file_a );
            my $file_b         = "b${suffix}.txt";
            my $file_b_utf8    = encode( 'UTF-8', $file_b );
            my $dir_c          = "c${suffix}";
            my $dir_c_utf8     = encode( 'UTF-8', $dir_c );
            my $symlink_d      = "d${suffix}.txt";
            my $symlink_d_utf8 = encode( 'UTF-8', $symlink_d );

            note('setup configuration for tests with empty @dirs');
            my $tmpdir = tempdir();

            chdir $tmpdir;
            open my $fh, '>', $file_a_utf8;
            close $fh;

            open $fh, '>', $file_b_utf8;
            print {$fh} "hello world\n";
            close $fh;
            my $file_size = -s $file_b_utf8;

            mkdir $dir_c_utf8;

            if ($symlink_supported) {
                symlink $file_a_utf8, $symlink_d_utf8;
            }

            chdir $basedir;

            my $chdir = sub {
                App::DCMP::_chdir( $tmpdir, @_ );
            };

            my @dirs;

            my $it = App::DCMP::_iterator_dir_fs( $chdir, $collect_file_info, undef, \@dirs );
            is( ref $it, ref sub { }, '_iterator_dir_fs() returns a sub' );

            #
            note('first file info');
            my $file_info = $it->();
            is( ref $file_info, ref [], 'file info is an array ref' );
            is( scalar @{$file_info}, 3, '... consisting of three values' );
            is( ${$file_info}[0], _normalize_filename($file_a), '... the file name' );
            like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
            is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
            is( ${$file_info}[2], 0, '... the file size' );

            #
            note('second file info');
            $file_info = $it->();
            is( ref $file_info, ref [], 'file info is an array ref' );
            is( scalar @{$file_info}, 3, '... consisting of three values' );
            is( ${$file_info}[0], _normalize_filename($file_b), '... the file name' );
            like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
            is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
            is( ${$file_info}[2], $file_size, '... the file size' );

            #
            note('third file info');
            $file_info = $it->();
            is( ref $file_info, ref [], 'file info is an array ref' );
            is( scalar @{$file_info}, 2, '... consisting of two values' );
            is( ${$file_info}[0], _normalize_filename($dir_c), '... the file name' );
            like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
            is( ${$file_info}[1], App::DCMP::FILE_TYPE_DIRECTORY(), '... which is from a directory' );

            if ($symlink_supported) {
                #
                note('fourth file info');
                $file_info = $it->();
                is( ref $file_info, ref [], 'file info is an array ref' );
                is( scalar @{$file_info}, 3, '... consisting of three values' );
                is( ${$file_info}[0], _normalize_filename($symlink_d), '... the file name' );
                like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                is( ${$file_info}[1], App::DCMP::FILE_TYPE_SYMLINK(), '... which is from a symlink' );
                is( ${$file_info}[2], $file_a, '... the links target' );
            }

        }

        {
            my $file_aa         = "AA${suffix}.txt";
            my $file_aa_utf8    = encode( 'UTF-8', $file_aa );
            my $file_bb         = "BB${suffix}.txt";
            my $file_bb_utf8    = encode( 'UTF-8', $file_bb );
            my $dir_cc          = "CC${suffix}";
            my $dir_cc_utf8     = encode( 'UTF-8', $dir_cc );
            my $symlink_dd      = "DD${suffix}.txt";
            my $symlink_dd_utf8 = encode( 'UTF-8', $symlink_dd );

            my $tmpdir = tempdir();
            my $chdir  = sub {
                App::DCMP::_chdir( $tmpdir, @_ );
            };
            #
            note('setup tests for 26 directories in @dir');
            chdir $tmpdir;
            my @dirs = map { "$_${suffix}" } 'a' .. 'z';
            for my $d (@dirs) {
                my $d_utf8 = encode( 'UTF-8', $d );
                mkdir $d_utf8;
                chdir $d_utf8;
            }

            open my $fh, '>', $file_aa_utf8;
            close $fh;

            open $fh, '>', $file_bb_utf8;
            print {$fh} "hello world\n";
            close $fh;
            my $file_size = -s $file_bb_utf8;

            mkdir $dir_cc_utf8;

            if ($symlink_supported) {
                symlink $file_aa_utf8, $symlink_dd_utf8;
            }

            chdir $basedir;

            my $it = App::DCMP::_iterator_dir_fs( $chdir, $collect_file_info, undef, \@dirs );
            is( ref $it, ref sub { }, '_iterator_dir_fs() returns a sub' );

            #
            note('first file info');
            my $file_info = $it->();
            is( ref $file_info, ref [], 'file info is an array ref' );
            is( scalar @{$file_info}, 3, '... consisting of three values' );
            is( ${$file_info}[0], _normalize_filename($file_aa), '... the file name' );
            like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
            is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
            is( ${$file_info}[2], 0, '... the file size' );

            #
            note('second file info');
            $file_info = $it->();
            is( ref $file_info, ref [], 'file info is an array ref' );
            is( scalar @{$file_info}, 3, '... consisting of three values' );
            is( ${$file_info}[0], _normalize_filename($file_bb), '... the file name' );
            like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
            is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
            is( ${$file_info}[2], $file_size, '... the file size' );

            #
            note('third file info');
            $file_info = $it->();
            is( ref $file_info, ref [], 'file info is an array ref' );
            is( scalar @{$file_info}, 2, '... consisting of two values' );
            is( ${$file_info}[0], _normalize_filename($dir_cc), '... the file name' );
            like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
            is( ${$file_info}[1], App::DCMP::FILE_TYPE_DIRECTORY(), '... which is from a directory' );

            if ($symlink_supported) {
                #
                note('fourth file info');
                $file_info = $it->();
                is( ref $file_info, ref [], 'file info is an array ref' );
                is( scalar @{$file_info}, 3, '... consisting of three values' );
                is( ${$file_info}[0], _normalize_filename($symlink_dd), '... the file name' );
                like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                is( ${$file_info}[1], App::DCMP::FILE_TYPE_SYMLINK(), '... which is from a symlink' );
                is( ${$file_info}[2], $file_aa, '... the links target' );
            }
        }

        {
            #
            note('ignore some dirs');
            my $tmpdir = tempdir();

            chdir $tmpdir;

            my $dir_a       = "a${suffix}";
            my $dir_a_utf8  = encode( 'UTF-8', $dir_a );
            my $dir_b       = "b${suffix}";
            my $dir_b_utf8  = encode( 'UTF-8', $dir_b );
            my $dir_c       = "c${suffix}";
            my $dir_c_utf8  = encode( 'UTF-8', $dir_c );
            my $file_d      = "d${suffix}.txt";
            my $file_d_utf8 = encode( 'UTF-8', $file_d );

            mkdir $dir_a_utf8;
            mkdir $dir_b_utf8;
            mkdir $dir_c_utf8;

            open my $fh, '>', $file_d_utf8;
            close $fh;

            chdir $basedir;

            my $chdir = sub {
                App::DCMP::_chdir( $tmpdir, @_ );
            };

            my @dirs;

            for my $state ( 0 .. 3 ) {
                my @ignore =
                    $state == 0 ? ()
                  : $state == 1 ? ($dir_a)
                  : $state == 2 ? ( $dir_a, $dir_b )
                  : $state == 3 ? ( $dir_a, $dir_b, $file_d )
                  :               BAIL_OUT 'internal error';

                if ( !@ignore ) {
                    note(q{### @ignore = ()});
                }
                else {
                    note( encode( 'UTF-8', q{### @ignore = ('} . join( q{', '}, @ignore ) . q{')} ) );
                }

                my $it = App::DCMP::_iterator_dir_fs( $chdir, $collect_file_info, \@ignore, \@dirs );
                is( ref $it, ref sub { }, '_iterator_dir_fs() returns a sub' );

                #
                my $file_info;
                if ( $state == 0 ) {
                    note($dir_a_utf8);
                    $file_info = $it->();
                    is( ref $file_info, ref [], 'file info is an array ref' );
                    is( scalar @{$file_info}, 2, '... consisting of three values' );
                    is( ${$file_info}[0], _normalize_filename($dir_a), '... the file name' );
                    like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                    is( ${$file_info}[1], App::DCMP::FILE_TYPE_DIRECTORY(), '... which is from a directory' );
                }

                if ( $state < 2 ) {
                    note($dir_b_utf8);
                    $file_info = $it->();
                    is( ref $file_info, ref [], 'file info is an array ref' );
                    is( scalar @{$file_info}, 2, '... consisting of three values' );
                    is( ${$file_info}[0], _normalize_filename($dir_b), '... the file name' );
                    like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                    is( ${$file_info}[1], App::DCMP::FILE_TYPE_DIRECTORY(), '... which is from a directory' );
                }

                note($dir_c_utf8);
                $file_info = $it->();
                is( ref $file_info, ref [], 'file info is an array ref' );
                is( scalar @{$file_info}, 2, '... consisting of three values' );
                is( ${$file_info}[0], _normalize_filename($dir_c), '... the file name' );
                like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                is( ${$file_info}[1], App::DCMP::FILE_TYPE_DIRECTORY(), '... which is from a directory' );

                if ( $state < 3 ) {
                    note($file_d_utf8);
                    $file_info = $it->();
                    is( ref $file_info, ref [], 'file info is an array ref' );
                    is( scalar @{$file_info}, 3, '... consisting of three values' );
                    is( ${$file_info}[0], _normalize_filename($file_d), '... the file name' );
                    like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                    is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
                    is( ${$file_info}[2], 0, '... the file size' );
                }

                note('exhausted');
                is( $it->(), undef, 'iterator is exhausted' );
            }
        }
    }
    #
    done_testing();

    exit 0;
}

# If the OS/filesystem normalizes the Unicode file name, the file name read
# with readdir might return a UTF-8 string that differs from the UTF-8 string
# that was used to create the file. OS/X does that. This function is used to
# normalize the file name in the same way.
{
    my %normalized_filename;

    sub _normalize_filename {
        my ($filename) = @_;

        if ( !exists $normalized_filename{$filename} ) {
            my $tmpdir  = tempdir();
            my $basedir = cwd();

            chdir $tmpdir;
            open my $fh, '>', encode( 'UTF-8', $filename );
            close $fh;

            opendir $fh, q{.};
            my @dents = grep { $_ ne q{.} && $_ ne q{..} } readdir $fh;
            closedir $fh;

            chdir $basedir;

            die encode( 'UTF-8', "Expected a single file in $tmpdir but got " . scalar(@dents) . " for $filename: " . join( q{ }, @dents ) . "\n" ) if @dents != 1;

            $normalized_filename{$filename} = decode( 'UTF-8', $dents[0] );
        }

        return $normalized_filename{$filename};

    }
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
