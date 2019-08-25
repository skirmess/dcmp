package Local::Suffixes;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Encode;

sub suffix_iterator {
    my @suffixes;

    # text string => binary string

    # empty string
    push @suffixes, [ q{} => q{} ];

    # euro sign as UTF-8
    push @suffixes, [ "\x{20ac}" => encode( 'UTF-8', "\x{20ac}" ) ];

    # "Latin Capital Letter a with Grave" as Latin-1, which is an invalid UTF-8 char
    push @suffixes, [ "\x{00C0}" => "\x{00C0}" ];

    # UTF-8 encoded "Latin Capital Letter a with Grave"
    push @suffixes, [ "\x{00C0}" => encode( 'UTF-8', "\x{00C0}" ) ];

    # UTF-8 encoded "Latin Capital Letter a with Grave" in decomposed form
    push @suffixes, [ "\x{0041}\x{0300}" => encode( 'UTF-8', "\x{0041}\x{0300}" ) ];

    if ( $^O ne 'MSWin32' ) {
        push @suffixes, [ 'a\nb', "a\nb" ];
    }

    return sub {
        return if !@suffixes;
        return @{ shift @suffixes };
    };
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
