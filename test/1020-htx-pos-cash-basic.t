#!/usr/bin/perl -w
use strict;
use test::utils;    ## Hauntix Test Utilities
use Test::More tests => 46;
use X11::GUITest qw/
    StartApp
    WaitWindowClose
    WaitWindowViewable
    SendKeys
    SetInputFocus
    GetWindowName
    GetChildWindows
    /;

diag "-----------------------";
diag "Basic Cash Transactions";
diag "-----------------------";

# Find the GUI
my ($mw) = WaitWindowViewable('Ticketing System');
BAIL_OUT "Did not find HaunTix window\n" if !$mw;
diag "HaunTix window $mw found";
BAIL_OUT "Could not focus on GUI" if !SetInputFocus($mw);
diag "HaunTix window focused";
sleep 1;

# Ready for sales?
wait_for_ready();

# Load item buttons so we know what to push
diag "Reading product buttons";
my $items = read_itms();
ok keys %$items, "Buttons loaded";

my $bill;

# ---------- o ----------

# One regular admission ticket
diag "Transaction: Buy one ticket for exact cash";
my $keycode = $items->{"Code Regular Admission"};
ok defined $keycode, "Found key for Regular Admission ticket";
is length($keycode), 1, "key code seems ok";

SendKeys("%(i)$keycode");
sleep 2;

is read_nums(), q{Tot: $15.00}, "Nums shows correct running total";

$bill = read_bill();
like $bill->{Transaction}, qr/^\d+$/, "Has a transaction number";
my $trnid = $bill->{Transaction};
ok $trnid > 0, "Transaction number is positive";
is_deeply $bill,
    {
    Timestamp    => $bill->{Timestamp},
    Transaction  => $trnid,
    Item         => q{. tix 1 'Regular Admission' $15.00 > $15.00},
    Info         => q{},
    Subtotal     => '$15.00',
    Tax          => '$0.00',
    TaxRate      => '7.40%',
    Total        => '$15.00',
    Summary      => '1 Items Sold * 0 Upgrades * 0 Discounts Given',
    },
    "Bill correct and complete";

# pay cash using amount in display (don't key in amount)
SendKeys("%(c)a");
sleep 1;

is read_nums(), q{Chg: $0.00}, "Nums shows correct change";

$bill = read_bill();
is $bill->{Transaction}, $trnid, "Still the same transaction";
is_deeply $bill,
    {
    Timestamp    => $bill->{Timestamp},
    Transaction  => $trnid,
    Item         => q{. tix 1 'Regular Admission' $15.00 > $15.00},
    Info         => q{},
    Subtotal     => '$15.00',
    Tax          => '$0.00',
    TaxRate      => '7.40%',
    Total        => '$15.00',
    CashPaid     => '$15.00',
    Change       => '$0.00',
    Summary      => '1 Items Sold * 0 Upgrades * 0 Discounts Given',
    SaleComplete => 1
    },
    "Bill correct and complete";

# Check the database for the transaction and associated records
### TODO

# Wait for next transaction
wait_for_ready();


# ---------- o ----------

# Two regular admission tickets
diag "Transaction: Buy two of same ticket for exact cash";
$keycode = $items->{"Code Regular Admission"};
is length($keycode), 1, "key code seems ok";

SendKeys("%(i)$keycode");
sleep 2;

is read_nums(), q{Tot: $15.00}, "Nums shows correct running total";

$bill = read_bill();
like $bill->{Transaction}, qr/^\d+$/, "Has a transaction number";
$trnid = $bill->{Transaction};
ok $trnid > 0, "Transaction number is positive";
is_deeply $bill,
    {
    Timestamp    => $bill->{Timestamp},
    Transaction  => $trnid,
    Item         => q{. tix 1 'Regular Admission' $15.00 > $15.00},
    Info         => q{},
    Subtotal     => '$15.00',
    Tax          => '$0.00',
    TaxRate      => '7.40%',
    Total        => '$15.00',
    Summary      => '1 Items Sold * 0 Upgrades * 0 Discounts Given',
    },
    "Bill correct and complete";

$keycode = $items->{"Code Regular Admission"};
ok defined $keycode, "Found key for Regular Admission ticket";
is length($keycode), 1, "key code seems ok";
SendKeys("%(i)$keycode");
sleep 2;

is read_nums(), q{Tot: $30.00}, "Nums shows correct running total";

$bill = read_bill();
like $bill->{Transaction}, qr/^\d+$/, "Has a transaction number";
$trnid = $bill->{Transaction};
ok $trnid > 0, "Transaction number is positive";
is_deeply $bill,
    {
    Timestamp    => $bill->{Timestamp},
    Transaction  => $trnid,
    Item         => q{. tix 2 'Regular Admission' $15.00 > $30.00},
    Info         => q{},
    Subtotal     => '$30.00',
    Tax          => '$0.00',
    TaxRate      => '7.40%',
    Total        => '$30.00',
    Summary      => '2 Items Sold * 0 Upgrades * 0 Discounts Given',
    },
    "Bill correct and complete";


# pay cash using amount in display (don't key in amount)
SendKeys("%(c)a");
sleep 2;

is read_nums(), q{Chg: $0.00}, "Nums shows correct change";

$bill = read_bill();
is $bill->{Transaction}, $trnid, "Still the same transaction";
is_deeply $bill,
    {
    Timestamp    => $bill->{Timestamp},
    Transaction  => $trnid,
    Item         => q{. tix 2 'Regular Admission' $15.00 > $30.00},
    Info         => q{},
    Subtotal     => '$30.00',
    Tax          => '$0.00',
    TaxRate      => '7.40%',
    Total        => '$30.00',
    CashPaid     => '$30.00',
    Change       => '$0.00',
    Summary      => '2 Items Sold * 0 Upgrades * 0 Discounts Given',
    SaleComplete => 1
    },
    "Bill correct and complete";

# Check the database for the transaction and associated records
### TODO

# Wait for next transaction
wait_for_ready();


# ---------- o ----------

# Two regular admission tickets
diag "Transaction: Buy two of different tickets for quick-50 cash";
$keycode = $items->{"Code VIP Admission"};
is length($keycode), 1, "key code seems ok";

SendKeys("%(i)$keycode");
sleep 2;

is read_nums(), q{Tot: $20.00}, "Nums shows correct running total";

$bill = read_bill();
like $bill->{Transaction}, qr/^\d+$/, "Has a transaction number";
$trnid = $bill->{Transaction};
ok $trnid > 0, "Transaction number is positive";
is_deeply $bill,
    {
    Timestamp    => $bill->{Timestamp},
    Transaction  => $trnid,
    Item         => q{. tix 1 'VIP Admission' $20.00 > $20.00},
    Info         => q{},
    Subtotal     => '$20.00',
    Tax          => '$0.00',
    TaxRate      => '7.40%',
    Total        => '$20.00',
    Summary      => '1 Items Sold * 0 Upgrades * 0 Discounts Given',
    },
    "Bill correct and complete";

$keycode = $items->{"Code Regular Admission"};
ok defined $keycode, "Found key for Regular Admission ticket";
is length($keycode), 1, "key code seems ok";
SendKeys("%(i)$keycode");
sleep 2;

is read_nums(), q{Tot: $35.00}, "Nums shows correct running total";

$bill = read_bill();
like $bill->{Transaction}, qr/^\d+$/, "Has a transaction number";
$trnid = $bill->{Transaction};
ok $trnid > 0, "Transaction number is positive";
is_deeply $bill,
    {
    Timestamp    => $bill->{Timestamp},
    Transaction  => $trnid,
    Item         => [q{. tix 1 'VIP Admission' $20.00 > $20.00},
                     q{. tix 1 'Regular Admission' $15.00 > $15.00},
                    ],
    Info         => [q{}, q{}],
    Subtotal     => '$35.00',
    Tax          => '$0.00',
    TaxRate      => '7.40%',
    Total        => '$35.00',
    Summary      => '2 Items Sold * 0 Upgrades * 0 Discounts Given',
    },
    "Bill correct and complete";


# pay $50 cash using quick-50 key
SendKeys("%(c)5");
sleep 2;

is read_nums(), q{Chg: $15.00}, "Nums shows correct change";

$bill = read_bill();
is $bill->{Transaction}, $trnid, "Still the same transaction";
is_deeply $bill,
    {
    Timestamp    => $bill->{Timestamp},
    Transaction  => $trnid,
    Item         => [q{. tix 1 'VIP Admission' $20.00 > $20.00},
                     q{. tix 1 'Regular Admission' $15.00 > $15.00},
                    ],
    Info         => [q{}, q{}],
    Subtotal     => '$35.00',
    Tax          => '$0.00',
    TaxRate      => '7.40%',
    Total        => '$35.00',
    CashPaid     => '$50.00',
    Change       => '$15.00',
    Summary      => '2 Items Sold * 0 Upgrades * 0 Discounts Given',
    SaleComplete => 1
    },
    "Bill correct and complete";

# Check the database for the transaction and associated records
### TODO

# Wait for next transaction
wait_for_ready();


# ---------- o ----------


# All done
exit 0;

