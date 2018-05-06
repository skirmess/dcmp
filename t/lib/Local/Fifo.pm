package Local::Fifo;

use 5.006;
use strict;
use warnings;

use POSIX 'mkfifo';

{
    my $_fifo_supported;

    sub fifo_supported {
        if ( !defined $_fifo_supported ) {
            $_fifo_supported = 0;

            eval {
                mkfifo q{}, 0666;
                $_fifo_supported = 1;
            };
        }

        return $_fifo_supported;
    }
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
