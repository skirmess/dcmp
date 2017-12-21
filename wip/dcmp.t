#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;
use Test::TempDir::Tiny;

#use Cwd qw(cwd);
use Encode;
use File::Spec;

use constant TYPE_FS     => 1;
use constant TYPE_DCMP_FILE => 2;

use lib qw(.);

use FindBin qw($Bin);
use lib "$Bin/lib";

use Local::Normalize_Filename;
use Local::Suffixes;
use Local::Symlink;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $suffix_iterator = Local::Suffixes::suffix_iterator();

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {

        my $dir_1_suffix_iterator = Local::Suffixes::suffix_iterator();

        while ( my ( $dir_1_suffix_text, $dir_1_suffix_bin ) = $dir_1_suffix_iterator->() ) {

            my $dir_2_suffix_iterator = Local::Suffixes::suffix_iterator();

            while ( my ( $dir_2_suffix_text, $dir_2_suffix_bin ) = $dir_2_suffix_iterator->() ) {

                for my $symlink_supported ( Local::Symlink::symlink_supported() ? ( 0, 1 ) : 0 ) {

                    for my $type1 ( TYPE_FS, TYPE_DCMP_FILE ) {

                        for my $type2 ( TYPE_FS, TYPE_DCMP_FILE ) {

                            _test_dcmp( $suffix_text, $suffix_bin, $dir_1_suffix_text, $dir_1_suffix_bin, $dir_2_suffix_text, $dir_2_suffix_bin, $symlink_supported, $type1, $type2 );
                        }
                    }
                }
            }
        }
    }

    done_testing();

    exit 0;
}

sub _test_dcmp {
    my ( $suffix_text, $suffix_bin, $dir_1_suffix_text, $dir_1_suffix_bin, $dir_2_suffix_text, $dir_2_suffix_bin, $symlink_supported, $type1, $type2 ) = @_;

    note(q{----------------------------------------------------------});
    note( encode( 'UTF-8', "file suffix: $suffix_text" ) );
    note( encode( 'UTF-8', "dir 1 suffix: $dir_1_suffix_text" ) );
    note( encode( 'UTF-8', "dir 2 suffix: $dir_2_suffix_text" ) );
    note( 'symlink ' . ( $symlink_supported ? q{} : 'not ' ) . 'supported' );
    note( 'mode: ' . ( $type1 == TYPE_FS ? 'FS' : 'DCMP_FILE' ) . q{/} . ( $type2 == TYPE_FS ? 'FS' : 'DCMP_FILE' ) );

                            # ----------------------------------------------------------
                            my @output;
                            my $printer = sub {
                                my ( $dirs_ref, $action, $name ) = @_;
                                push @output, [ $action, File::Spec->catdir( @{$dirs_ref}, $name ) ];
                                return;
                            };

                            # ----------------------------------------------------------
                            my $dcmp_filename_1         = "file1${suffix_bin}.dcmp";
                            my $dcmp_filename_2         = "file2${suffix_bin}.dcmp";
                            my $dir                     = Local::Normalize_Filename::normalize_filename("dir${suffix_bin}");
                            my $dir_escaped             = App::DCMP::_escape_filename($dir);
                            my $dir2                    = Local::Normalize_Filename::normalize_filename("dir2${suffix_bin}");
                            my $dir2_escaped            = App::DCMP::_escape_filename($dir2);
                            my $dir3                    = Local::Normalize_Filename::normalize_filename("dir3${suffix_bin}");
                            my $dir3_escaped            = App::DCMP::_escape_filename($dir3);
                            my $dir4                    = Local::Normalize_Filename::normalize_filename("dir4${suffix_bin}");
                            my $dir4_escaped            = App::DCMP::_escape_filename($dir4);
                            my $file                    = Local::Normalize_Filename::normalize_filename("file${suffix_bin}.txt");
                            my $file_escaped            = App::DCMP::_escape_filename($file);
                            my $file2                   = Local::Normalize_Filename::normalize_filename("file2${suffix_bin}.txt");
                            my $file2_escaped           = App::DCMP::_escape_filename($file2);
                            my $invalid_link            = Local::Normalize_Filename::normalize_filename("invalid_link${suffix_bin}.txt");
                            my $invalid_link_escaped    = App::DCMP::_escape_filename($invalid_link);
                            my $invalid_target          = Local::Normalize_Filename::normalize_filename("invalid_target${suffix_bin}.txt");
                            my $invalid_target_escaped  = App::DCMP::_escape_filename($invalid_target);
                            my $invalid_target2         = Local::Normalize_Filename::normalize_filename("invalid_target2${suffix_bin}.txt");
                            my $invalid_target2_escaped = App::DCMP::_escape_filename($invalid_target2);
                            my $valid_link              = Local::Normalize_Filename::normalize_filename("valid_link${suffix_bin}.txt");
                            my $valid_link_escaped      = App::DCMP::_escape_filename($valid_link);
                            my $valid_link2             = Local::Normalize_Filename::normalize_filename("valid_link2${suffix_bin}.txt");
                            my $valid_link2_escaped     = App::DCMP::_escape_filename($valid_link2);

                            # ----------------------------------------------------------
                            my $dir_1 = File::Spec->catdir( tempdir(), "dir1_${dir_1_suffix_bin}" );
                            mkdir $dir_1;

                            my $chdir_1;
                            my $it_1;

                            if ( $type1 == TYPE_FS ) {
                                $chdir_1 = sub {
                                    return App::DCMP::_chdir( $dir_1, @_ );
                                };

                                $it_1 = sub {
                                    return App::DCMP::_iterator_dir_fs( $chdir_1, sub { return App::DCMP::_collect_file_info(@_); }, undef, @_ );
                                };

                                if ($symlink_supported) {
                                    symlink $invalid_target, File::Spec->catfile( $dir_1, $invalid_link );
                                }

                                mkdir File::Spec->catdir( $dir_1, $dir );

                                open my $fh, '>', File::Spec->catfile( $dir_1, $dir, $file2 );
                                close $fh;

                                if ($symlink_supported) {
                                    symlink $file, File::Spec->catfile( $dir_1, $valid_link );
                                }

                                open $fh, '>', File::Spec->catfile( $dir_1, $file );
                                print {$fh} "hello world\n";
                                close $fh;
                            }
                            else {
                                my $dcmp_file_1 = File::Spec->catfile( $dir_1, $dcmp_filename_1 );
                                open my $fh, '>', $dcmp_file_1;

                                print {$fh} <<"RECORD_FILE";
dcmp v1
LINK $invalid_link_escaped $invalid_target_escaped
DIR $dir_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
LINK $valid_link_escaped $file_escaped
FILE $file_escaped 12 6f5902ac237024bdd0c176cb93063dc4
-DIR
RECORD_FILE
                                close $fh;

                                $it_1 = App::DCMP::_load_dcmp_file($dcmp_file_1);
                                is( ref $it_1, ref sub { }, '_load_records() returns a sub' );
                            }

                            # ----------------------------------------------------------
                            my $dir_2 = File::Spec->catdir( tempdir(), "dir2_${dir_2_suffix_bin}" );
                            mkdir $dir_2;

                            my $chdir_2;
                            my $it_2;

                            if ( $type2 == TYPE_FS ) {
                                $chdir_2 = sub {
                                    return App::DCMP::_chdir( $dir_2, @_ );
                                };

                                $it_2 = sub {
                                    return App::DCMP::_iterator_dir_fs( $chdir_2, sub { return App::DCMP::_collect_file_info(@_); }, undef, @_ );
                                };
                            }
                            else {
                                my $dcmp_file_2 = File::Spec->catfile( $dir_2, $dcmp_filename_2 );
                                open my $fh, '>', $dcmp_file_2;
                                print {$fh} <<'RECORD_FILE';
dcmp v1
-DIR
RECORD_FILE
                                close $fh;

                                $it_2 = App::DCMP::_load_dcmp_file($dcmp_file_2);
                                is( ref $it_2, ref sub { }, '_load_records() returns a sub' );
                            }

                            # ----------------------------------------------------------
                            my $compare_file = sub { return App::DCMP::_compare_file($chdir_1, $chdir_2, @_); };

                            # ----------------------------------------------------------

                            is( App::DCMP::_dcmp( $it_1, $it_2, $compare_file, $printer ), undef, '_dcmp returns undef' );

                            my %output_expected;
                            $output_expected{$dir} = App::DCMP::FILE_ADDITIONAL();
                            $output_expected{File::Spec->catfile( $dir, $file2 )} = App::DCMP::FILE_ADDITIONAL();
                            $output_expected{$file} = App::DCMP::FILE_ADDITIONAL();
                            if ( $symlink_supported || $type1 == TYPE_DCMP_FILE ) {
                                $output_expected{$invalid_link} = App::DCMP::FILE_ADDITIONAL();
                                $output_expected{$valid_link} = App::DCMP::FILE_ADDITIONAL();
                            }

                            my @output_expected;
                            for my $file ( App::DCMP::_sort(keys %output_expected) ) {
                                push @output_expected, [ $output_expected{$file}, $file ];
                            }

                            is_deeply( \@output, \@output_expected, '... and prints the correct output' );

                            # ----------------------------------------------------------
                            $dir_2 = File::Spec->catdir( tempdir(), "dir2_${dir_2_suffix_bin}" );
                            mkdir $dir_2;

                            if ( $type2 == TYPE_FS ) {
                                $chdir_2 = sub {
                                    return App::DCMP::_chdir( $dir_2, @_ );
                                };

                                $it_2 = sub {
                                    return App::DCMP::_iterator_dir_fs( $chdir_2, sub { return App::DCMP::_collect_file_info(@_); }, undef, @_ );
                                };

                                if ($symlink_supported) {
                                    symlink $invalid_target, File::Spec->catfile( $dir_2, $invalid_link );
                                }

                                mkdir File::Spec->catdir( $dir_2, $dir );

                                open my $fh, '>', File::Spec->catfile( $dir_2, $dir, $file2 );
                                close $fh;

                                if ($symlink_supported) {
                                    symlink $file, File::Spec->catfile( $dir_2, $valid_link );
                                }

                                open $fh, '>', File::Spec->catfile( $dir_2, $file );
                                print {$fh} "hello world\n";
                                close $fh;
                            }
                            else {
                                my $dcmp_file_2 = File::Spec->catfile( $dir_2, $dcmp_filename_2 );
                                open my $fh, '>', $dcmp_file_2;

                                print {$fh} <<"RECORD_FILE";
dcmp v1
LINK $invalid_link_escaped $invalid_target_escaped
DIR $dir_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
LINK $valid_link_escaped $file_escaped
FILE $file_escaped 12 6f5902ac237024bdd0c176cb93063dc4
-DIR
RECORD_FILE
                                close $fh;

                                $it_2 = App::DCMP::_load_dcmp_file($dcmp_file_2);
                                is( ref $it_2, ref sub { }, '_load_records() returns a sub' );
                            }

                            undef @output;

                            is( App::DCMP::_dcmp( $it_1, $it_2, $compare_file, $printer ), undef, '_dcmp returns undef' );

                            if ( !$symlink_supported && $type1 == TYPE_FS && $type2 == TYPE_DCMP_FILE ) {
                                @output_expected = (
                                    [ App::DCMP::FILE_MISSING(), $invalid_link ],
                                    [ App::DCMP::FILE_MISSING(), $valid_link ],
                                );
                            }
                            elsif ( !$symlink_supported && $type1 == TYPE_DCMP_FILE && $type2 == TYPE_FS ) {
                                @output_expected = (
                                    [ App::DCMP::FILE_ADDITIONAL(), $invalid_link ],
                                    [ App::DCMP::FILE_ADDITIONAL(), $valid_link ],
                                );
                            }
                            else {
                                @output_expected = ();
                            }

                            is_deeply( \@output, \@output_expected, '... and prints the correct output' );

                            # ----------------------------------------------------------
                            if ( $type1 == TYPE_FS ) {
                                mkdir File::Spec->catdir( $dir_1, $dir4 );

                                open my $fh, '>', File::Spec->catdir( $dir_1, $dir4, $file );
                                close $fh;

                                # yes, dir3 as file for different type!
                                open $fh, '>', File::Spec->catdir( $dir_1, $dir3 );
                                close $fh;
                            }
                            else {
                                my $dcmp_file_1 = File::Spec->catfile( $dir_2, $dcmp_filename_1 );
                                open my $fh, '>', $dcmp_file_1;

                                print {$fh} <<"RECORD_FILE";
dcmp v1
LINK $invalid_link_escaped $invalid_target_escaped
DIR $dir_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
LINK $valid_link_escaped $file_escaped
FILE $file_escaped 12 6f5902ac237024bdd0c176cb93063dc4
FILE $dir3_escaped 0 aaaaaa
DIR $dir4_escaped
FILE $file_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
-DIR
RECORD_FILE
                                close $fh;

                                $it_1 = App::DCMP::_load_dcmp_file($dcmp_file_1);
                                is( ref $it_1, ref sub { }, '_load_records() returns a sub' );
                            }

                            if ( $type2 == TYPE_FS ) {
                                $dir_2 = File::Spec->catdir( tempdir(), "dir2_${dir_2_suffix_bin}" );
                                mkdir $dir_2;

                                $chdir_2 = sub {
                                    return App::DCMP::_chdir( $dir_2, @_ );
                                };

                                $it_2 = sub {
                                    return App::DCMP::_iterator_dir_fs( $chdir_2, sub { return App::DCMP::_collect_file_info(@_); }, undef, @_ );
                                };

                                if ($symlink_supported) {
                                    symlink $invalid_target2, File::Spec->catfile( $dir_2, $invalid_link );
                                }

                                mkdir File::Spec->catdir( $dir_2, $dir );

                                open my $fh, '>', File::Spec->catfile( $dir_2, $dir, $file2 );
                                print {$fh} "test\n";
                                close $fh;

                                mkdir File::Spec->catdir( $dir_2, $dir2 );

                                open $fh, '>', File::Spec->catdir( $dir_2, $dir2, $file2 );
                                close $fh;

                                if ($symlink_supported) {
                                    symlink $file, File::Spec->catfile( $dir_2, $valid_link2 );
                                }

                                open $fh, '>', File::Spec->catfile( $dir_2, $file );
                                print {$fh} "\nhello world\n";
                                close $fh;

                                mkdir File::Spec->catdir( $dir_2, $dir3 );

                                open $fh, '>', File::Spec->catdir( $dir_2, $dir3, $file2 );
                                close $fh;

                                # yes, dir4 as file for different type!
                                open $fh, '>', File::Spec->catdir( $dir_2, $dir4 );
                                close $fh;
                            }
                            else {
                                my $dcmp_file_2 = File::Spec->catfile( $dir_2, $dcmp_filename_2 );
                                open my $fh, '>', $dcmp_file_2;

                                print {$fh} <<"RECORD_FILE";
dcmp v1
LINK $invalid_link_escaped $invalid_target2_escaped
LINK $valid_link2_escaped $file_escaped
DIR $dir2_escaped
FILE $file2_escaped 13 6f5902ac237024bdd0c176cb93063dc4
-DIR
FILE $file_escaped 13 6f5902ac237024bdd0c176cb93063dc4
FILE $dir4_escaped 0 aaaaa
DIR $dir_escaped
FILE $file2_escaped 13 6f5902ac237024bdd0c176cb93063dc4
-DIR
DIR $dir3_escaped
FILE $file2_escaped 13 6f5902ac237024bdd0c176cb93063dc4
-DIR
-DIR
RECORD_FILE
                                close $fh;

                                $it_2 = App::DCMP::_load_dcmp_file($dcmp_file_2);
                                is( ref $it_2, ref sub { }, '_load_records() returns a sub' );
                            }

                            # --------------------------------------------------
                            undef @output;

                            is( App::DCMP::_dcmp( $it_1, $it_2, $compare_file, $printer ), undef, '_dcmp returns undef' );

                            @output_expected = (
                                [ App::DCMP::FILE_CONTENT_DIFFERS(), File::Spec->catfile( $dir,  $file2 ) ],
                                [ App::DCMP::FILE_MISSING(),         $dir2 ],
                                [ App::DCMP::FILE_MISSING(),         File::Spec->catfile( $dir2, $file2 ) ],
                                [ App::DCMP::FILE_TYPE_DIFFERS(),    $dir3 ],
                                [ App::DCMP::FILE_MISSING(),         File::Spec->catfile( $dir3, $file2 ) ],
                                [ App::DCMP::FILE_TYPE_DIFFERS(),    $dir4 ],
                                [ App::DCMP::FILE_ADDITIONAL(),      File::Spec->catfile( $dir4, $file ) ],
                                [ App::DCMP::FILE_CONTENT_DIFFERS(), $file ],
                            );

                            if ( $symlink_supported || ( ( $type1 == TYPE_DCMP_FILE ) && ( $type2 == TYPE_DCMP_FILE ) ) ) {
                                push @output_expected,
                                  [ App::DCMP::LINK_TARGET_DIFFERS(), $invalid_link ],
                                  [ App::DCMP::FILE_ADDITIONAL(),     $valid_link ],
                                  [ App::DCMP::FILE_MISSING(),        $valid_link2 ];
                            }
                            elsif ( ( !$symlink_supported ) && ( $type1 == TYPE_DCMP_FILE ) ) {

                                # symlink from dcmp file are present, the ones on the filesystem are not
                                push @output_expected,
                                  [ App::DCMP::FILE_ADDITIONAL(), $invalid_link ],
                                  [ App::DCMP::FILE_ADDITIONAL(), $valid_link ];
                            }
                            elsif ( ( !$symlink_supported ) && ( $type2 == TYPE_DCMP_FILE ) ) {

                                # symlink from dcmp file are present, the ones on the filesystem are not
                                push @output_expected,
                                  [ App::DCMP::FILE_MISSING(), $invalid_link ],
                                  [ App::DCMP::FILE_MISSING(), $valid_link2 ];
                            }

#                            @output_expected = sort { $a->[1] cmp $b->[1] } @output_expected;

                            is_deeply( \@output, \@output_expected, '... and prints the correct output' ) or do {

                            use Data::Dx; Dx @output; Dx @output_expected;
                            die;
                        };
#                            use Data::Dx; Dx @output; Dx @output_expected;

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl