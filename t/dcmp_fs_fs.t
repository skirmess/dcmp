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

    my $symlink_supported = 0;
    {
        no autodie;
        eval {
            symlink q{}, q{};
            $symlink_supported = 1;
        };
    }

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

                my $dir             = _normalize_filename("dir${file_suffix}");
                my $dir2            = _normalize_filename("dir2${file_suffix}");
                my $dir3            = _normalize_filename("dir3${file_suffix}");
                my $dir4            = _normalize_filename("dir4${file_suffix}");
                my $file            = _normalize_filename("file${file_suffix}.txt");
                my $file2           = _normalize_filename("file2${file_suffix}.txt");
                my $invalid_link    = _normalize_filename("invalid_link${file_suffix}.txt");
                my $invalid_target  = _normalize_filename("invalid_target${file_suffix}.txt");
                my $invalid_target2 = _normalize_filename("invalid_target2${file_suffix}.txt");
                my $valid_link      = _normalize_filename("valid_link${file_suffix}.txt");
                my $valid_link2     = _normalize_filename("valid_link2${file_suffix}.txt");

                my $dir_l = File::Spec->catdir( tempdir(), "dirL${dir_l_suffix}" );
                mkdir encode( 'UTF-8', $dir_l );

                my $dir_r = File::Spec->catdir( tempdir(), "dirR${dir_r_suffix}" );
                mkdir encode( 'UTF-8', $dir_r );

                my $chdir_l = sub { return App::DCMP::_chdir( $dir_l, @_ ); };
                my $it_l = sub {
                    return App::DCMP::_iterator_dir_fs( $chdir_l, sub { return App::DCMP::_collect_file_info(@_); }, undef, @_ );
                };

                if ($symlink_supported) {
                    symlink encode( 'UTF-8', $invalid_target ), encode( 'UTF-8', File::Spec->catfile( $dir_l, $invalid_link ) );
                }

                mkdir encode( 'UTF-8', File::Spec->catdir( $dir_l, $dir ) );

                open my $fh, '>', encode( 'UTF-8', File::Spec->catfile( $dir_l, $dir, $file2 ) );
                close $fh;

                if ($symlink_supported) {
                    symlink encode( 'UTF-8', $file ), encode( 'UTF-8', File::Spec->catfile( $dir_l, $valid_link ) );
                }

                open $fh, '>', encode( 'UTF-8', File::Spec->catfile( $dir_l, $file ) );
                print {$fh} "hello world\n";
                close $fh;

                #
                my $chdir_r = sub { return App::DCMP::_chdir( $dir_r, @_ ); };
                my $it_r = sub {
                    return App::DCMP::_iterator_dir_fs( $chdir_r, sub { return App::DCMP::_collect_file_info(@_); }, undef, @_ );
                };

                #
                my $compare_file = sub { App::DCMP::_compare_file_fs_fs( $chdir_l, $chdir_r, @_ ) };

                my @output;
                my $printer = sub {
                    my ( $action, $dirs_ref, $name ) = @_;
                    push @output, [ $action, File::Spec->catdir( @{$dirs_ref}, $name ) ];
                    return;
                };

                is( App::DCMP::_dcmp( $it_l, $it_r, $compare_file, $printer ), undef, '_dcmp returns undef' );

                my @output_expected = sort { $a->[1] cmp $b->[1] } (
                    [ App::DCMP::FILE_ADDITIONAL(), $dir ],
                    [ App::DCMP::FILE_ADDITIONAL(), File::Spec->catfile( $dir, $file2 ) ],
                    [ App::DCMP::FILE_ADDITIONAL(), $file ],
                    $symlink_supported
                    ? (
                        [ App::DCMP::FILE_ADDITIONAL(), $invalid_link ],
                        [ App::DCMP::FILE_ADDITIONAL(), $valid_link ],
                      )
                    : (),
                );

                is_deeply( \@output, \@output_expected, '... and prints the correct output' );

                # ----------------------------------------------------------
                $dir_r = File::Spec->catdir( tempdir(), "dirR${dir_r_suffix}" );
                mkdir encode( 'UTF-8', $dir_r );
                $chdir_r = sub { return App::DCMP::_chdir( $dir_r, @_ ); };
                $it_r = sub {
                    return App::DCMP::_iterator_dir_fs( $chdir_r, sub { return App::DCMP::_collect_file_info(@_); }, undef, @_ );
                };

                if ($symlink_supported) {
                    symlink encode( 'UTF-8', $invalid_target ), encode( 'UTF-8', File::Spec->catfile( $dir_r, $invalid_link ) );
                }

                mkdir encode( 'UTF-8', File::Spec->catdir( $dir_r, $dir ) );

                open $fh, '>', encode( 'UTF-8', File::Spec->catfile( $dir_r, $dir, $file2 ) );
                close $fh;

                if ($symlink_supported) {
                    symlink encode( 'UTF-8', $file ), encode( 'UTF-8', File::Spec->catfile( $dir_r, $valid_link ) );
                }

                open $fh, '>', encode( 'UTF-8', File::Spec->catfile( $dir_r, $file ) );
                print {$fh} "hello world\n";
                close $fh;

                undef @output;

                is( App::DCMP::_dcmp( $it_l, $it_r, $compare_file, $printer ), undef, '_dcmp returns undef' );

                @output_expected = ();

                is_deeply( \@output, \@output_expected, '... and prints the correct output' );

                # -----------------------
                $dir_r = File::Spec->catdir( tempdir(), "dirR${dir_r_suffix}" );
                mkdir encode( 'UTF-8', $dir_r );
                $chdir_r = sub { return App::DCMP::_chdir( $dir_r, @_ ); };
                $it_r = sub {
                    return App::DCMP::_iterator_dir_fs( $chdir_r, sub { return App::DCMP::_collect_file_info(@_); }, undef, @_ );
                };

                if ($symlink_supported) {
                    symlink encode( 'UTF-8', $invalid_target2 ), encode( 'UTF-8', File::Spec->catfile( $dir_r, $invalid_link ) );
                }

                mkdir encode( 'UTF-8', File::Spec->catdir( $dir_r, $dir ) );

                open $fh, '>', encode( 'UTF-8', File::Spec->catfile( $dir_r, $dir, $file2 ) );
                print {$fh} "test\n";
                close $fh;

                mkdir encode( 'UTF-8', File::Spec->catdir( $dir_r, $dir2 ) );

                open $fh, '>', encode( 'UTF-8', File::Spec->catdir( $dir_r, $dir2, $file2 ) );
                close $fh;

                if ($symlink_supported) {
                    symlink encode( 'UTF-8', $file ), encode( 'UTF-8', File::Spec->catfile( $dir_r, $valid_link2 ) );
                }

                open $fh, '>', encode( 'UTF-8', File::Spec->catfile( $dir_r, $file ) );
                print {$fh} "\nhello world\n";
                close $fh;

                # --------------------------------------------------
                mkdir encode( 'UTF-8', File::Spec->catdir( $dir_r, $dir3 ) );

                open $fh, '>', encode( 'UTF-8', File::Spec->catdir( $dir_r, $dir3, $file2 ) );
                close $fh;

                # yes, dir3 as file for different type!
                open $fh, '>', encode( 'UTF-8', File::Spec->catdir( $dir_l, $dir3 ) );
                close $fh;

                # --------------------------------------------------
                mkdir encode( 'UTF-8', File::Spec->catdir( $dir_l, $dir4 ) );

                open $fh, '>', encode( 'UTF-8', File::Spec->catdir( $dir_l, $dir4, $file ) );
                close $fh;

                # yes, dir4 as file for different type!
                open $fh, '>', encode( 'UTF-8', File::Spec->catdir( $dir_r, $dir4 ) );
                close $fh;

                # --------------------------------------------------
                undef @output;

                is( App::DCMP::_dcmp( $it_l, $it_r, $compare_file, $printer ), undef, '_dcmp returns undef' );

                @output_expected = sort { $a->[1] cmp $b->[1] } (
                    [ App::DCMP::FILE_CONTENT_DIFFERS(), File::Spec->catfile( $dir,  $file2 ) ],
                    [ App::DCMP::FILE_MISSING(),         File::Spec->catfile($dir2) ],
                    [ App::DCMP::FILE_MISSING(),         File::Spec->catfile( $dir2, $file2 ) ],
                    [ App::DCMP::FILE_TYPE_DIFFERS(),    File::Spec->catfile($dir3) ],
                    [ App::DCMP::FILE_MISSING(),         File::Spec->catfile( $dir3, $file2 ) ],
                    [ App::DCMP::FILE_TYPE_DIFFERS(),    File::Spec->catfile($dir4) ],
                    [ App::DCMP::FILE_ADDITIONAL(),      File::Spec->catfile( $dir4, $file ) ],
                    [ App::DCMP::FILE_CONTENT_DIFFERS(), $file ],
                    $symlink_supported
                    ? (
                        [ App::DCMP::LINK_TARGET_DIFFERS(), $invalid_link ],
                        [ App::DCMP::FILE_ADDITIONAL(),     $valid_link ],
                        [ App::DCMP::FILE_MISSING(),        $valid_link2 ],
                      )
                    : (),
                );

                is_deeply( \@output, \@output_expected, '... and prints the correct output' );

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
