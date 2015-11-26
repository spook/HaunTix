#!/usr/bin/perl -w
use strict;
use test::utils;    ## Hauntix Test Utilities
use Test::More tests => 3;
use X11::GUITest qw/
    StartApp
    WaitWindowClose
    WaitWindowViewable
    SendKeys
    SetInputFocus
    GetWindowName
    GetChildWindows
    /;

diag " ";
diag "-------------------------";
diag "Start the HaunTix POS GUI";
diag "-------------------------";

diag "Inits";
nuke_bill;
nuke_itms;
nuke_nums;

diag "Starting hauntix";
StartApp("$CMD_HTXPOS 1>test/hauntix.out 2>&1 &");
my ($mw) = WaitWindowViewable('Ticketing System');
BAIL_OUT "Did not find main HaunTix window\n" if !$mw;
ok 1, "Hauntix Started";

BAIL_OUT "Could not focus on GUI" if !SetInputFocus($mw);
ok 1, "HaunTix window focused";
sleep 1;

my $wn = GetWindowName($mw);
ok $wn, "Using window '$wn'";
sleep 3;    # Still need some delay for htx to start processing inputs

# Done
done_testing();
exit 0;

