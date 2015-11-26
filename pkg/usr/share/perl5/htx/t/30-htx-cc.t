#!perl -w
use strict;
use warnings;
use Test::More tests => 61;

use Config::Std;
use FindBin;
use lib "$FindBin::RealBin/../../lib";
use htx;
use htx::cc;

my $out;
my $htx = {};
read_config $CONFIG_FILE => $htx->{cfg};

# Normal keyed submissions
$out = htx::cc::charge_keyed($htx,
    Amount   => "123.45",
    AcctNum  => "5454545454545454",
    ExpDate  => "1210",
    CardCode => "998",
    DuplicateMode   => "CHECKING_OFF",
    );
ok defined $out,                        "Normal keyed cc charge, got a response";
diag "Got $out->{ResponseCode} ($htx::cc::CC_CODES{$out->{ResponseCode}}), '$out->{ResponseDescription}'";
is $out->{ResponseCode}, q{000},        "Normal keyed cc charge, got approval";
like $out->{ApprovalCode}, qr/^\d+$/,   "Normal keyed cc charge, got approval code";
like $out->{BatchNum}, qr/^\d+$/,       "Normal keyed cc charge, got batch number";
like $out->{TransactionID}, qr/^\d+$/,  "Normal keyed cc charge, got transaction ID";
my $batchnum = $out->{BatchNum};    # Save for later tests

# Normal keyed submission but duplicate enabled
$out = htx::cc::charge_keyed($htx,
    Amount   => "123.45",
    AcctNum  => "5454545454545454",
    ExpDate  => "1210",
    CardCode => "998",
    DuplicateMode   => "CHECKING_ON",
    );
ok defined $out,                    "Dup keyed cc charge, got a response";
diag "Got $out->{ResponseCode} ($htx::cc::CC_CODES{$out->{ResponseCode}}), '$out->{ResponseDescription}'" if defined $out;
is $out->{ResponseCode}, q{813},    "Dup keyed cc charge, duplicate caught";

# Swiped charges
$out = htx::cc::charge_swiped($htx,
    Amount   => "123.45",
    Track    => "%B4003000123456781^GLOBAL PAYMENT TEST CARD/^151250254321987123456789012345?",
    TrackCapabilities => "TRACK1",
    DuplicateMode     => "CHECKING_OFF",
    );
ok defined $out,                        "Swiped t1 visa charge, got a response";
diag "Got $out->{ResponseCode} ($htx::cc::CC_CODES{$out->{ResponseCode}}), '$out->{ResponseDescription}'" if defined $out;
is $out->{ResponseCode}, q{000},        "Swiped t1 visa charge, got approval";
like $out->{ApprovalCode}, qr/^\d+$/,   "Swiped t1 visa charge, got approval code";
like $out->{BatchNum}, qr/^\d+$/,       "Swiped t1 visa charge, got batch number";
like $out->{TransactionID}, qr/^\d+$/,  "Swiped t1 visa charge, got transaction ID";

$out = htx::cc::charge_swiped($htx,
    Amount   => "123.45",
    Track    => "%B5499990123456781^GLOBAL PAYMENTS TEST CARD/^15125024321987123456789012345?",
    TrackCapabilities => "TRACK1",
    DuplicateMode     => "CHECKING_OFF",
    );
ok defined $out,                        "Swiped t1 mc charge, got a response";
diag "Got $out->{ResponseCode} ($htx::cc::CC_CODES{$out->{ResponseCode}}), '$out->{ResponseDescription}'" if defined $out;
is $out->{ResponseCode}, q{000},        "Swiped t1 mc charge, got approval";
like $out->{ApprovalCode}, qr/^\d+$/,   "Swiped t1 mc charge, got approval code";
like $out->{BatchNum}, qr/^\d+$/,       "Swiped t1 mc charge, got batch number";
like $out->{TransactionID}, qr/^\d+$/,  "Swiped t1 mc charge, got transaction ID";

$out = htx::cc::charge_swiped($htx,
    Amount   => "123.45",
    Track    => ";4003000123456781=15125025432198712345?",
    DuplicateMode   => "CHECKING_OFF",
    );
ok defined $out,                        "Swiped t2 visa charge, got a response";
diag "Got $out->{ResponseCode} ($htx::cc::CC_CODES{$out->{ResponseCode}}), '$out->{ResponseDescription}'" if defined $out;
is $out->{ResponseCode}, q{000},        "Swiped t2 visa charge, got approval";
like $out->{ApprovalCode}, qr/^\d+$/,   "Swiped t2 visa charge, got approval code";
like $out->{BatchNum}, qr/^\d+$/,       "Swiped t2 visa charge, got batch number";
like $out->{TransactionID}, qr/^\d+$/,  "Swiped t2 visa charge, got transaction ID";

$out = htx::cc::charge_swiped($htx,
    Amount   => "123.45",
    Track    => ";5499990123456781=15125025432198712345?",
    DuplicateMode   => "CHECKING_OFF",
    );
ok defined $out,                        "Swiped t2 mc charge, got a response";
diag "Got $out->{ResponseCode} ($htx::cc::CC_CODES{$out->{ResponseCode}}), '$out->{ResponseDescription}'" if defined $out;
is $out->{ResponseCode}, q{000},        "Swiped t2 mc charge, got approval";
like $out->{ApprovalCode}, qr/^\d+$/,   "Swiped t2 mc charge, got approval code";
like $out->{BatchNum}, qr/^\d+$/,       "Swiped t2 mc charge, got batch number";
like $out->{TransactionID}, qr/^\d+$/,  "Swiped t2 mc charge, got transaction ID";

$out = htx::cc::charge_swiped($htx,
    Amount   => "123.45",
    Track    => "%B4003000123456781^GLOBAL PAYMENT TEST CARD/^151250254321987123456789012345?;4003000123456781=15125025432198712345?",
    TrackCapabilities => "BOTH",
    DuplicateMode     => "CHECKING_OFF",
    );
ok defined $out,                        "Swiped t1+t2 visa charge, got a response";
diag "Got $out->{ResponseCode} ($htx::cc::CC_CODES{$out->{ResponseCode}}), '$out->{ResponseDescription}'" if defined $out;
is $out->{ResponseCode}, q{000},        "Swiped t1+t2 visa charge, got approval";
like $out->{ApprovalCode}, qr/^\d+$/,   "Swiped t1+t2 visa charge, got approval code";
like $out->{BatchNum}, qr/^\d+$/,       "Swiped t1+t2 visa charge, got batch number";
like $out->{TransactionID}, qr/^\d+$/,  "Swiped t1+t2 visa charge, got transaction ID";

$out = htx::cc::charge_swiped($htx,
    Amount   => "123.45",
    Track    => "%B5499990123456781^GLOBAL PAYMENTS TEST CARD/^15125024321987123456789012345?;5499990123456781=15125025432198712345?",
    TrackCapabilities => "BOTH",
    DuplicateMode     => "CHECKING_OFF",
    );
ok defined $out,                        "Swiped t1+t2 mc charge, got a response";
diag "Got $out->{ResponseCode} ($htx::cc::CC_CODES{$out->{ResponseCode}}), '$out->{ResponseDescription}'" if defined $out;
is $out->{ResponseCode}, q{000},        "Swiped t1+t2 mc charge, got approval";
like $out->{ApprovalCode}, qr/^\d+$/,   "Swiped t1+t2 mc charge, got approval code";
like $out->{BatchNum}, qr/^\d+$/,       "Swiped t1+t2 mc charge, got batch number";
like $out->{TransactionID}, qr/^\d+$/,  "Swiped t1+t2 mc charge, got transaction ID";


# Normal keyed submissions
$out = htx::cc::charge_keyed($htx,
    Amount   => "123.45",
    AcctNum  => "5454545454545454",
    ExpDate  => "1210",
    CardCode => "998",
    DuplicateMode   => "CHECKING_OFF",
    );
ok defined $out,                        "Normal keyed cc charge, got a response";
diag "Got $out->{ResponseCode} ($htx::cc::CC_CODES{$out->{ResponseCode}}), '$out->{ResponseDescription}'" if defined $out;
is $out->{ResponseCode}, q{000},        "Normal keyed cc charge, got approval";
like $out->{ApprovalCode}, qr/^\d+$/,   "Normal keyed cc charge, got approval code";
like $out->{BatchNum}, qr/^\d+$/,       "Normal keyed cc charge, got batch number";
like $out->{TransactionID}, qr/^\d+$/,  "Normal keyed cc charge, got transaction ID";

# Refunds
$out = htx::cc::refund_keyed($htx,
    Amount   => "123.45",
    AcctNum  => "5454545454545454",
    ExpDate  => "1210",
    );
ok defined $out,                        "Refund, got a response";
diag "Got $out->{ResponseCode} ($htx::cc::CC_CODES{$out->{ResponseCode}}), '$out->{ResponseDescription}'" if defined $out;
is $out->{ResponseCode}, q{000},        "Refund, got approval";
like $out->{BatchNum}, qr/^\d+$/,       "Refund, got batch number";
like $out->{TransactionID}, qr/^\d+$/,  "Normal keyed cc charge, got transaction ID";

$out = htx::cc::refund_keyed($htx,
    Amount   => "123.45",
    AcctNum  => "5454545454545454",
    ExpDate  => "1210",
    DuplicateMode   => "CHECKING_ON",
    );
ok defined $out,                    "Dup refund, got a response";
diag "Got $out->{ResponseCode} ($htx::cc::CC_CODES{$out->{ResponseCode}}), '$out->{ResponseDescription}'" if defined $out;
is $out->{ResponseCode}, q{813},    "Dup refund, duplicate caught";

# Batch inquiry
$out = htx::cc::batch_inquiry($htx, $batchnum || "000001");
ok defined $out,                            "Batch inquiry, got a response";
is $out->{ResponseCode}, q{004},            "Batch inquiry, response code ok";
diag "Got $out->{ResponseCode} ($htx::cc::CC_CODES{$out->{ResponseCode}}), '$out->{ResponseDescription}'" if defined $out;
like $out->{BatchAmount}, qr/^\d+\.\d\d$/,  "Batch inquiry, got batch amount";
like $out->{BatchCount}, qr/^\d+$/,         "Batch inquiry, got batch count";
like $out->{BatchNum}, qr/^\d+$/,           "Batch inquiry, got batch number";
like $out->{TransactionID}, qr/^\d+$/,      "Batch inquiry, got transaction ID";

# Batch settle
$out = htx::cc::batch_settle($htx);
ok defined $out,                            "Batch settle, got a response";
diag "Got $out->{ResponseCode} ($htx::cc::CC_CODES{$out->{ResponseCode}}), '$out->{ResponseDescription}'" if defined $out;
is $out->{ResponseCode}, q{003},            "Batch settle, response code ok";
like $out->{BatchAmount}, qr/^\d+\.\d\d$/,  "Batch settle, got batch amount";
like $out->{BatchCount}, qr/^\d+$/,         "Batch settle, got batch count";
like $out->{BatchNum}, qr/^\d+$/,           "Batch settle, got batch number";
is $out->{BatchNum}, $batchnum,             "Batch settle, batch number is expected number $batchnum";
like $out->{TransactionID}, qr/^\d+$/,      "Batch settle, got transaction ID";
