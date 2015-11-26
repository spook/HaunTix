#!/usr/bin/perl -w
use strict;
use Config::Std;
use Test::More;

diag " ";
diag "-------------------------------------------------------";
diag "Cleanup the test environment from the 10xx-series tests";
diag "-------------------------------------------------------";


my $out = qx(cancel -a tix-3 2>&1);
chomp $out;
is $out, q{}, "Ticket printer queue cleared";

$out = qx(cancel -a receipt-3 2>&1);
chomp $out;
is $out, q{}, "Receipt printer queue cleared";

# All done
done_testing();
exit 0;

