#=============================================================================
#
# Hauntix Credit Card processing functions
#   This is a package of functions, not an OO package.
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

#use htx;
use LWP::Simple;
use URI;

package htx::cc;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(%AVS_CODES %CVV_CODES);
my $RDELIM = q{|};

our %AVS_CODES = (
    'A' => 'Address (Street) matches, ZIP does not',
    'B' => 'Address information not provided for AVS check',
    'E' => 'AVS error',
    'G' => 'Non-U.S. Card Issuing Bank',
    'N' => 'No Match on Address (Street) or ZIP',
    'P' => 'AVS not applicable for this transaction',
    'R' => 'Retry – System unavailable or timed out',
    'S' => 'Service not supported by issuer',
    'U' => 'Address information is unavailable',
    'W' => '9 digit ZIP matches, Address (Street) does not',
    'X' => 'Address (Street) and 9 digit ZIP match',
    'Y' => 'Address (Street) and 5 digit ZIP match',
    'Z' => '5 digit ZIP matches, Address (Street) does not',
);

our %CVV_CODES = (
    'M' => 'Card Code matched',
    'N' => 'Card Code does not match',
    'P' => 'Card Code was not processed',
    'S' => 'Card Code should be on card but was not indicated',
    'U' => 'Issuer was not certified for Card Code',
);

# field positions
my $pos = {
    CP => {
        ResponseSubCode     => 2 - 1,
        ReasonSubCode       => 3 - 1,
        ResponseDescription => 4 - 1,
        ApprovalCode        => 5 - 1,
        AVSCode             => 6 - 1,
        CVVCode             => 7 - 1,
        TransactionId       => 8 - 1,
        MD5Hash             => 9 - 1,
        MaskedAcctNum       => 21 - 1,    # as xxxx1234
        CardType            => 22 - 1,
    },
    CNP => {
        ResponseSubCode     => 1 - 1,
        ReasonSubCode       => 3 - 1,
        ResponseDescription => 4 - 1,
        ApprovalCode        => 5 - 1,
        AVSCode             => 6 - 1,
        CVVCode             => 39 - 1,
        TransactionId       => 7 - 1,
        MD5Hash             => 38 - 1,
        MaskedAcctNum       => 51 - 1,    # as xxxx1234
        CardType            => 52 - 1,
    },
};

#
# Submit a charge from a card that was keyed or swiped in.
# Required args:  $htx, then...
#        Amount   => "1.01"
#      then
#        AcctNum  => "5454545454545454",
#        ExpDate  => "1210",
#        CardCode => "998",
#      or
#        Track    => "..."
# Returns a hashref containing response values, else undef.
# Important keys in the hashref are:
#   ResponseCode => "000" is good, otherwise a problem occurred
#       Note "820" means Temporary Service Outage - Retry Transaction
#            "813" means Duplicate Transaction Error
#   ResponseDescription => text as to what happened
#   TransactionID
#   ApprovalCode
#

# TODO: add
#        Address
#        ZipCode

sub charge {
    my ($htx, %ccdat) = @_;
    my $section = $ccdat{UseWeb} ? "ccw" : "ccr";
    return _cc_post_and_parse(
        $htx, $section,
        {   (   $ccdat{UseWeb}
                ? (

                    # CNP only fields
                    x_version        => "3.1",
                    x_relay_response => "FALSE",
                    x_delim_data     => "TRUE",
                    )
                : (

                    # CP-only fields
                    x_cpversion   => "1.0",
                    x_market_type => 2,                                              # 2=retail
                    x_device_type => $htx->{cfg}->{$section}->{device_type} || 4,    # 4=ECR, 8=web
                    x_response_format => 1,    # 0=xml, 1=delimited
                )
            ),

            # Common fields
            x_type         => "AUTH_CAPTURE",
            x_login        => $htx->{cfg}->{$section}->{login},
            x_tran_key     => $htx->{cfg}->{$section}->{tran_key},
            x_test_request => $htx->{cfg}->{$section}->{test_request} || q{no},    # yes / no
            x_delim_char   => $RDELIM,
            x_amount       => $ccdat{Amount},
            (   $ccdat{Track}
                ? (x_track2 => $ccdat{Track})    # Track for CP only
                : ( x_card_num  => $ccdat{AcctNum},
                    x_exp_date  => $ccdat{ExpDate},
                    x_card_code => $ccdat{CardCode}
                )
            ),
            ($ccdat{CheckDups} ? () : (x_duplicate_window => 0)),
            ($ccdat{Company}   ? (x_company    => $ccdat{Company})   : ()),
            ($ccdat{FirstName} ? (x_first_name => $ccdat{FirstName}) : ()),
            ($ccdat{LastName}  ? (x_last_name  => $ccdat{LastName})  : ()),
            ($ccdat{Address}   ? (x_address    => $ccdat{Address})   : ()),
            ($ccdat{City}      ? (x_city       => $ccdat{City})      : ()),
            ($ccdat{State}     ? (x_state      => $ccdat{State})     : ()),
            ($ccdat{ZipCode}   ? (x_zip        => $ccdat{ZipCode})   : ()),
            ($ccdat{Country}   ? (x_country    => $ccdat{Country})   : ()),
            ($ccdat{Phone}     ? (x_phone      => $ccdat{Phone})     : ()),
            ($ccdat{CustID}    ? (x_cust_id    => $ccdat{CustID})    : ()),
            x_description => $ccdat{Description} || q{},    # 0-255 chars
            x_invoice_num => $ccdat{Invoice}     || q{},    # 0-20 chars
            x_user_ref    => $ccdat{URef}        || q{},    # 0-255 chars (not a field for CNP)
        }
    );
}

#
# Submit a refund request
#
sub refund {
    my ($htx, %ccdat) = @_;
    my $section = $ccdat{UseWeb} ? "ccw" : "ccr";
    return _cc_post_and_parse(
        $htx, $section,
        {   (   $ccdat{UseWeb}
                ? (

                    # CNP only fields
                    x_version        => "3.1",
                    x_relay_response => "FALSE",
                    x_delim_data     => "TRUE",
                    )
                : (

                    # CP-only fields
                    x_cpversion   => "1.0",
                    x_market_type => 2,                                              # 2=retail
                    x_device_type => $htx->{cfg}->{$section}->{device_type} || 4,    # 4=ECR, 8=web
                    x_response_format => 1,    # 0=xml, 1=delimited
                )
            ),

            # Common fields
            x_type         => "CREDIT",
            x_login        => $htx->{cfg}->{$section}->{login},
            x_tran_key     => $htx->{cfg}->{$section}->{tran_key},
            x_test_request => $htx->{cfg}->{$section}->{test_request} || q{no},    # yes / no
            x_delim_char   => $RDELIM,
            x_amount       => $ccdat{Amount},
            (   $ccdat{Track}    # Track for CP only
                ? (x_track2 => $ccdat{Track})
                : ( x_card_num  => $ccdat{AcctNum},
                    x_exp_date  => $ccdat{ExpDate},
                    x_card_code => $ccdat{CardCode}
                )
            ),
            ($ccdat{CheckDups} ? () : (x_duplicate_window => 0)),
            x_description => $ccdat{Description} || q{},    # 0-255 chars
            x_invoice_num => $ccdat{Invoice}     || q{},    # 0-20 chars
            x_user_ref    => $ccdat{URef}        || q{},    # 0-255 chars
        }
    );
}

#
# Void an unsettled transaction
#
sub void {
    my ($htx, %ccdat) = @_;
    my $section = $ccdat{UseWeb} ? "ccw" : "ccr";
    return _cc_post_and_parse(
        $htx, $section,
        {                                                   # CNP only fields
            (   $ccdat{UseWeb}
                ? (

                    # CNP only fields
                    x_version        => "3.1",
                    x_relay_response => "FALSE",
                    x_delim_data     => "TRUE",
                    )
                : (

                    # CP-only fields
                    x_cpversion   => "1.0",
                    x_market_type => 2,                                              # 2=retail
                    x_device_type => $htx->{cfg}->{$section}->{device_type} || 4,    # 4=ECR, 8=web
                    x_response_format => 1,    # 0=xml, 1=delimited
                )
            ),

            # Common fields
            x_type         => "VOID",
            x_login        => $htx->{cfg}->{$section}->{login},
            x_tran_key     => $htx->{cfg}->{$section}->{tran_key},
            x_test_request => $htx->{cfg}->{$section}->{test_request} || q{no},    # yes / no
            x_delim_char   => $RDELIM,
            x_description  => $ccdat{Description} || q{},                          # 0-255 chars
            x_invoice_num  => $ccdat{Invoice} || q{},                              # 0-20 chars
            x_user_ref     => $ccdat{URef} || q{},                                 # 0-255 chars
        }
    );
}

#
# Common function to post and parse the response
#
sub _cc_post_and_parse {
    my ($htx, $section, $subdat) = @_;
    my $url = URI->new($htx->{cfg}->{$section}->{url});
    $url->query_form(%$subdat);
    my $rstr = LWP::Simple::get "$url";
    return undef if !defined $rstr;

    # Convert authorize.net responses to xweb type
    #   ResponseCode => "000" is good, otherwise a problem occurred
    #       Note "820" means Temporary Service Outage - Retry Transaction *** 3-25 or 3-26
    #            "813" means Duplicate Transaction Error
    #   ResponseDescription => text as to what happened
    #   TransactionID
    #   ApprovalCode
    my %ahash;
    $ahash{url} = $htx->{cfg}->{$section}->{url};
    my @fields = split("\\$RDELIM", $rstr);
    if (@fields < 9) {
        $ahash{ResponseCode}        = "999";
        $ahash{ResponseDescription} = $rstr;
        return \%ahash;
    }
    my $p = $section eq 'ccw' ? 'CNP' : 'CP';

    # Derive the overall response code
    $ahash{ResponseCode}
        = $fields[$pos->{$p}->{ResponseSubCode}] == 1
        ? "000"
        : sprintf("%d-%d",
        $fields[$pos->{$p}->{ResponseSubCode}],
        $fields[$pos->{$p}->{ReasonSubCode}]);

    # Load in common fields
    foreach my $k (keys %{$pos->{$p}}) {
        $ahash{$k} = $fields[$pos->{$p}->{$k}];
    }

    # echo these from the input dat
    $ahash{Amount}  = $subdat->{x_amount}   || "0.00";
    $ahash{ExpDate} = $subdat->{x_exp_date} || "00/00";
    $ahash{ProcessorResponse} = $rstr;

    # Do we need these?
    #        AcctNumSource
    return \%ahash;
}

1;
