# Collection of utility functions for testing HaunTix

package test::utils;
use Config::Std;
use Test::More;
require Exporter;
@ISA    = 'Exporter';
@EXPORT = qw/nuke_bill
    nuke_itms
    nuke_nums
    read_bill
    read_itms
    read_nums
    wait_for_ready
    $TOUT_BILL $TOUT_ITMS $TOUT_NUMS $CMD_HTXPOS/;

our $TOUT_BILL = 'htx-pos-bill.t.out';
our $TOUT_ITMS = 'htx-pos-itms.t.out';
our $TOUT_NUMS = 'htx-pos-nums.t.out';

our $CMD_HTXPOS = "HTX_TEST=ibn perl -I pkg/usr/share/perl5/ pkg/usr/bin/hauntix-pos";

# Erase any prior bill test output
sub nuke_bill {
    return unlink $TOUT_BILL;
}

# Erase any prior itms test output
sub nuke_itms {
    return unlink $TOUT_ITMS;
}

# Erase any prior nums test output
sub nuke_nums {
    return unlink $TOUT_NUMS;
}

# Read in the bill / receipt / tally, return as a hash in {Bill}
sub read_bill {
    my $h;
    eval {read_config $TOUT_BILL => $h;};
    return {} if $@;
    return $h->{Bill};
}

# Read the item buttons, return as a hash in {Items}
sub read_itms {
    my $h;
    eval {read_config $TOUT_ITMS => $h;};
    return {} if $@;
    return $h->{Items};
}

# Read the nums display, return as a string
sub read_nums {
    my $a = qx(cat $TOUT_NUMS 2>/dev/null);
    chomp $a;
    return $a;
}

# Wait until ready for the next sale.  Counts as two tests.
#   Optional arg, how long to wait, 0..n, default 13 secs
sub wait_for_ready {
    my $bill;
    my $n = @_ ? shift : 13;
    for (0 .. $n) {
        $bill = read_bill();
        last if $bill->{ReadyForSale};
        sleep 1 if $n;
    };
    ok $bill->{ReadyForSale}, "Ready for sales again";
    is read_nums(), q{Amt: 0}, "Nums back to zero";
    sleep 1; # Still need a bit of delay, tho...
}

1;

