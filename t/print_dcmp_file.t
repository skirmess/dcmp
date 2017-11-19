#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;
use Test::TempDir::Tiny;

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use Encode;
use File::Spec;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $basedir = cwd();

    my @suffixes = ( q{}, "_\x{20ac}", "_\x{00C0}", "_\x{0041}\x{0300}", ' hello world ' );

    if ( $^O ne 'MSWin32' ) {
        push @suffixes, "a\nb";
    }

    for my $suffix (@suffixes) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix" ) );

        my $suffix_escaped = $suffix;
        $suffix_escaped =~ s{[ ]}{%20}xsmg;
        $suffix_escaped =~ s{\n}{%0A}xsmg;

        my $dir                    = "dir${suffix}";
        my $dir_escaped            = "dir${suffix_escaped}";
        my $dir_utf8               = encode( 'UTF-8', $dir );
        my $file                   = "file${suffix}.txt";
        my $file_escaped           = "file${suffix_escaped}.txt";
        my $file_utf8              = encode( 'UTF-8', $file );
        my $file2                  = "file2${suffix}.txt";
        my $file2_escaped          = "file2${suffix_escaped}.txt";
        my $invalid_link           = "invalid_link${suffix}.txt";
        my $invalid_link_escaped   = "invalid_link${suffix_escaped}.txt";
        my $invalid_link_utf8      = encode( 'UTF-8', $invalid_link );
        my $invalid_target         = "invalid_target${suffix}.txt";
        my $invalid_target_escaped = "invalid_target${suffix_escaped}.txt";
        my $invalid_target_utf8    = encode( 'UTF-8', $invalid_target );
        my $valid_link             = "valid_link${suffix}.txt";
        my $valid_link_escaped     = "valid_link${suffix_escaped}.txt";
        my $valid_link_utf8        = encode( 'UTF-8', $valid_link );

        my $tmpdir = tempdir();
        chdir $tmpdir;

        open my $fh, '>', $file_utf8;
        print {$fh} 'hello world';
        close $fh;
        my $file_size = -s $file_utf8;

        symlink $file_utf8,           $valid_link_utf8;
        symlink $invalid_target_utf8, $invalid_link_utf8;

        mkdir $dir_utf8;

        open $fh, '>', encode( 'UTF-8', File::Spec->catfile( $dir, $file2 ) );
        close $fh;

        chdir $basedir;

        my $chdir             = sub { return App::DCMP::_chdir( $tmpdir, @_ ); };
        my $collect_file_info = sub { return App::DCMP::_collect_file_info_report(@_); };
        my $iterate_dir_fs    = sub { return App::DCMP::_iterator_dir_fs( $chdir, $collect_file_info, undef, @_ ); };

        my ( $stdout, $stderr, @result );

        ( $stdout, $stderr, @result ) = capture { App::DCMP::_print_dcmp_file($iterate_dir_fs); };
        is( @result, 0, '_print_dcmp_file returns nothing' );
        my @stdout = split /\n/xsm, $stdout;

        is( @stdout, 7, '... prints 7 lines to stdout' );
        my $i = 0;
        is( $stdout[ $i++ ], encode( 'UTF-8', "DIR $dir_escaped" ), encode( 'UTF-8', "...DIR $dir_escaped" ) );
        is( $stdout[ $i++ ], encode( 'UTF-8', "FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e" ), encode( 'UTF-8', "... FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e" ) );
        is( $stdout[ $i++ ], '-DIR', '... -DIR' );
        is( $stdout[ $i++ ], encode( 'UTF-8', "FILE $file_escaped $file_size 5eb63bbbe01eeed093cb22bb8f5acdc3" ), encode( 'UTF-8', "... FILE $file_escaped $file_size 5eb63bbbe01eeed093cb22bb8f5acdc3" ) );
        is( $stdout[ $i++ ], encode( 'UTF-8', "LINK $invalid_link_escaped $invalid_target_escaped" ),             encode( 'UTF-8', "... LINK $invalid_link_escaped $invalid_target_escaped" ) );
        is( $stdout[ $i++ ], encode( 'UTF-8', "LINK $valid_link_escaped $file_escaped" ),                         encode( 'UTF-8', "... LINK $valid_link_escaped $file_escaped" ) );
        is( $stdout[ $i++ ], '-DIR', '... -DIR' );

        is( $stderr, q{}, '... prints nothing to stderr' );

    }
    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
