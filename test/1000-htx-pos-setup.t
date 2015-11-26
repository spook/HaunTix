#!/usr/bin/perl -w
use strict;
use Config::Std;
use Test::More tests => 2;

diag " ";
diag "-----------------------------------------------------------------------";
diag "Prepare test environment for 10xx-series HaunTix Point of Sale UI Tests";
diag "-----------------------------------------------------------------------";


my $out = qx(mysql -u root --pass=some.password.goes.here < pkg/usr/share/htx/hauntix_create.sql 2>&1);
chomp $out;
is $out, q{}, "Wipeout and schema";

$out = qx(mysql -u root --pass=some.password.goes.here < pkg/usr/share/htx/hauntix_test_data.sql 2>&1);
chomp $out;
is $out, q{}, "Test data load";

# All done
done_testing();
exit 0;

