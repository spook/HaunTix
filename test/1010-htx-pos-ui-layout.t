#!/usr/bin/perl -w
use strict;
use test::utils;    ## Hauntix Test Utilities
use Test::More tests => 18;
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
diag "-------------------------------";
diag "Check the initial window layout";
diag "-------------------------------";

# Find the GUI
my ($mw) = WaitWindowViewable('Ticketing System');
BAIL_OUT "Did not find HaunTix window\n" if !$mw;
diag "HaunTix window $mw found";
BAIL_OUT "Could not focus on GUI" if !SetInputFocus($mw);
diag "HaunTix window focused";
sleep 1;

# Ready for sales?
my $bill = read_bill();
ok $bill->{ReadyForSale}, "Ready for sales";

# Initial nums value is not set
is read_nums(), q{}, "Initial nums display unset";

# Send Clear to nums, read it back
SendKeys('c');
sleep 1;
is read_nums(), q{Amt: 0}, "Nums is amount zero";

# Check buttons
diag "Checking item buttons";
my $items = read_itms();
ok keys %$items, "Items exists";
foreach my $btxt (
    (   "Regular Admission",
        "VIP Admission",
        "Museum Admission",
        "VIP Upgrade",
        "Regular Timed",
        "VIP Timed",
        "Early Rehearsal",
        "Late Rehearsal",
        "Rehearsal Timed VIP",
        "Beanie",
        "T-Shirt Basic",
        "T-Shirt Premium",
        "Haunt Shirt",
        "Hoodie"
    ))
{
    is $items->{"Name $btxt"}, "normal", "Have normal button $btxt";
}

# All done
exit 0;

