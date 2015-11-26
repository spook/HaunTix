#!/usr/bin/perl -w
use strict;
use test::utils;    ## Hauntix Test Utilities
use Test::More tests => 2;
use X11::GUITest qw/
    StartApp
    WaitWindowClose
    WaitWindowViewable
    SetInputFocus
    SendKeys
    GetWindowName
    GetChildWindows
    /;

diag " ";
diag "------------------------";
diag "Close the HaunTix POS UI";
diag "------------------------";

# Find the GUI
my ($mw) = WaitWindowViewable('Ticketing System');
BAIL_OUT "Did not find HaunTix window\n" if !$mw;
diag "HaunTix window $mw found";
BAIL_OUT "Could not focus on GUI" if !SetInputFocus($mw);
diag "HaunTix window focused";
sleep 3;

# Close HauntTix
ok SendKeys('%(f)q'), "Sent Quit Sequence";    # Alt-f q
ok WaitWindowClose($mw), "Closed hauntix";

# All done
exit 0;

