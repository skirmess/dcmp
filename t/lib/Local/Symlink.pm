package Local::Symlink;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

{
    my $_symlink_supported;

    sub symlink_supported {
        if ( !defined $_symlink_supported ) {
            $_symlink_supported = 0;

            eval {
                symlink q{}, q{};    ## no critic (InputOutput::RequireCheckedSyscalls)
                $_symlink_supported = 1;
            };
        }

        return $_symlink_supported;
    }
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
