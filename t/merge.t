#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd qw(cwd);
use Encode;
use File::Spec;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $basedir = cwd();

    my @suffixes = ( q{}, "_\x{20ac}", "_\x{00C0}", "_\x{0041}\x{0300}" );

    if ( $^O ne 'MSWin32' ) {
        push @suffixes, "a\nb";
    }

    for my $dir_l_suffix (@suffixes) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "left dir suffix: $dir_l_suffix" ) );

        for my $dir_r_suffix (@suffixes) {
            note(q{----------------------------------------------------------});
            note( encode( 'UTF-8', "right dir suffix: $dir_r_suffix" ) );

            for my $file_suffix (@suffixes) {
                note(q{----------------------------------------------------------});
                note( encode( 'UTF-8', "file suffix: $file_suffix" ) );

                my $file_a      = "a{$file_suffix}.txt";
                my $file_a_utf8 = encode( 'UTF-8', $file_a );
                my $file_b      = "b{$file_suffix}.txt";
                my $file_b_utf8 = encode( 'UTF-8', $file_b );
                my $file_c      = "c{$file_suffix}.txt";
                my $file_c_utf8 = encode( 'UTF-8', $file_c );
                my $file_d      = "d{$file_suffix}.txt";
                my $file_d_utf8 = encode( 'UTF-8', $file_d );
                my $file_e      = "e{$file_suffix}.txt";
                my $file_e_utf8 = encode( 'UTF-8', $file_e );

                my $tmpdir_l = File::Spec->catdir( tempdir(), "base${dir_l_suffix}" );
                my $tmpdir_l_utf8 = encode( 'UTF-8', $tmpdir_l );
                mkdir $tmpdir_l_utf8;

                my $tmpdir_r = File::Spec->catdir( tempdir(), "base${dir_r_suffix}" );
                my $tmpdir_r_utf8 = encode( 'UTF-8', $tmpdir_r );
                mkdir $tmpdir_r_utf8;

                chdir $tmpdir_l_utf8;

                open my $fh, '>', $file_a_utf8;
                close $fh;

                open $fh, '>', $file_b_utf8;
                close $fh;

                open $fh, '>', $file_d_utf8;
                close $fh;

                chdir $tmpdir_r_utf8;

                open $fh, '>', $file_a_utf8;
                close $fh;

                open $fh, '>', $file_c_utf8;
                close $fh;

                for my $pass ( 0 .. 1 ) {

                    if ( $pass == 1 ) {
                        open $fh, '>', $file_e_utf8;
                        close $fh;
                    }

                    chdir $basedir;

                    my $chdir_l = sub { App::DCMP::_chdir( $tmpdir_l, @_ ); };
                    my $chdir_r = sub { App::DCMP::_chdir( $tmpdir_r, @_ ); };

                    my $collect_file_info = sub { App::DCMP::_collect_file_info(@_); };

                    my @dirs;

                    my $it_l = App::DCMP::_iterator_dir_fs( $chdir_l, $collect_file_info, \@dirs );
                    my $it_r = App::DCMP::_iterator_dir_fs( $chdir_r, $collect_file_info, \@dirs );

                    my $it = App::DCMP::_merge_iterators( $it_l, $it_r );
                    is( ref $it, ref sub { }, '_merge_iterators() returns a sub' );

                    #
                    note( encode( 'UTF-8', "$file_a / $file_a" ) );
                    my $merged_file_info = $it->();
                    is( ref $merged_file_info, ref [], 'merged file info is an array ref' );
                    is( scalar @{$merged_file_info}, 2, '... consisting of two values' );
                    is( ref ${$merged_file_info}[0], ref [], '... first value is an array ref' );
                    is( ref ${$merged_file_info}[1], ref [], '... second value is an array ref' );

                    my $file_info = ${$merged_file_info}[0];
                    is( scalar @{$file_info}, 3, '... first consists of three values' );
                    is( ${$file_info}[0], _normalize_filename($file_a), '... the file name' );
                    like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                    is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
                    is( ${$file_info}[2], 0, '... the file size' );

                    $file_info = ${$merged_file_info}[1];
                    is( scalar @{$file_info}, 3, '... second consists of three values' );
                    is( ${$file_info}[0], _normalize_filename($file_a), '... the file name' );
                    like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                    is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
                    is( ${$file_info}[2], 0, '... the file size' );

                    #
                    note( encode( 'UTF-8', "undef / $file_b" ) );
                    $merged_file_info = $it->();
                    is( ref $merged_file_info, ref [], 'merged file info is an array ref' );
                    is( scalar @{$merged_file_info}, 2, '... consisting of two values' );
                    is( ref ${$merged_file_info}[0], ref [], '... first value is an array ref' );
                    is( ${$merged_file_info}[1], undef, '... second value is undef' );

                    $file_info = ${$merged_file_info}[0];
                    is( ref $file_info, ref [], 'file info is an array ref' );
                    is( scalar @{$file_info}, 3, '... consisting of three values' );
                    is( ${$file_info}[0], _normalize_filename($file_b), '... the file name' );
                    like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                    is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
                    is( ${$file_info}[2], 0, '... the file size' );

                    #
                    note( encode( 'UTF-8', "$file_c / undef" ) );
                    $merged_file_info = $it->();

                    is( ref $merged_file_info, ref [], 'merged file info is an array ref' );
                    is( scalar @{$merged_file_info}, 2,     '... consisting of two values' );
                    is( ${$merged_file_info}[0],     undef, '... first value is undef' );
                    is( ref ${$merged_file_info}[1], ref [], '... second value is an array ref' );

                    $file_info = ${$merged_file_info}[1];
                    is( ref $file_info, ref [], 'file info is an array ref' );
                    is( scalar @{$file_info}, 3, '... consisting of three values' );
                    is( ${$file_info}[0], _normalize_filename($file_c), '... the file name' );
                    like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                    is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
                    is( ${$file_info}[2], 0, '... the file size' );

                    #
                    note( encode( 'UTF-8', "undef / $file_d" ) );
                    $merged_file_info = $it->();
                    is( ref $merged_file_info, ref [], 'merged file info is an array ref' );
                    is( scalar @{$merged_file_info}, 2, '... consisting of two values' );
                    is( ref ${$merged_file_info}[0], ref [], '... first value is an array ref' );
                    is( ${$merged_file_info}[1], undef, '... second value is undef' );

                    $file_info = ${$merged_file_info}[0];
                    is( ref $file_info, ref [], 'file info is an array ref' );
                    is( scalar @{$file_info}, 3, '... consisting of three values' );
                    is( ${$file_info}[0], _normalize_filename($file_d), '... the file name' );
                    like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                    is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
                    is( ${$file_info}[2], 0, '... the file size' );

                    if ( $pass == 1 ) {
                        #
                        note( encode( 'UTF-8', "$file_e / undef" ) );
                        $merged_file_info = $it->();

                        is( ref $merged_file_info, ref [], 'merged file info is an array ref' );
                        is( scalar @{$merged_file_info}, 2,     '... consisting of two values' );
                        is( ${$merged_file_info}[0],     undef, '... first value is undef' );
                        is( ref ${$merged_file_info}[1], ref [], '... second value is an array ref' );

                        $file_info = ${$merged_file_info}[1];
                        is( ref $file_info, ref [], 'file info is an array ref' );
                        is( scalar @{$file_info}, 3, '... consisting of three values' );
                        is( ${$file_info}[0], _normalize_filename($file_e), '... the file name' );
                        like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                        is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
                        is( ${$file_info}[2], 0, '... the file size' );
                    }

                    #
                    note('undef');
                    is( $it->(), undef, 'merged file info is undef - iterator is exhausted.' );

                }
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
