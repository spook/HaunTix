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
our @EXPORT_OK = qw(%CC_CODES);

# X-Charge gateway response codes
our %CC_CODES = (
    '000' => 'Approval',
    '001' => 'Decline',
    '002' => 'Call',
    '003' => 'Success',
    '004' => 'Inquiry',
    '005' => 'Alias Success',
    '800' => 'Parsing Error',
    '801' => 'Maximum Request Data Exceeded Error',
    '802' => 'Duplicate Field Error',
    '803' => 'Improper DLL Error',
    '804' => 'Specification Version Error',
    '805' => 'Authentication Error',
    '806' => 'Production Merchant Set Up Error',
    '807' => 'Test Merchant Set Up Error',
    '808' => 'Development Merchant Set Up Error',
    '809' => 'Required Field Not Sent Error',
    '810' => 'Inconsistent Conditional Field Error',
    '811' => 'Improper Field Data Error',
    '812' => 'Unrecognized Name / Tag Error',
    '813' => 'Duplicate Transaction Error',
    '814' => 'Invalid Reference Error',
    '815' => 'Transaction Already Voided',
    '816' => 'Transaction Already Captured',
    '817' => 'Empty Batch',
    '818' => 'Merchant Locked For Settlement',
    '819' => 'Merchant Locked for Maintenance',
    '820' => 'Temporary Service Outage - Retry Transaction',
    '821' => 'Processing Host Unavailable',
    '822' => 'Maximum Batch Size Exceeded',
    '823' => 'Invalid Account Data',
    '824' => 'Industry Mismatch Error',
    '825' => 'Rejected',
    '900' => 'TSYS Error',
);

# TODO:  Combine charge_keyed(), charge_swiped(), charge_moto() - they're essentially all the same
# TODO:  Then refund_keyed() becomes refund() cuz it'll handle swiped, and moto too

#
# Submit a charge from a card (present) that was keyed in.
# Required args:  $htx, then...
#        AcctNum  => "5454545454545454",
#        ExpDate  => "1210",
#        CardCode => "998",
#        Amount   => "1.01"
# You may also override any of the other args by passing them like ther required args.
#
# Returns a hashref containing response values, else undef.
# Important keys in the hashref are:
#   ResponseCode => "000" is good, otherwise a problem occurred
#       Note "820" means Temporary Service Outage - Retry Transaction
#            "813" means Duplicate Transaction Error
#   ResponseDescription => text as to what happened
#   TransactionID
#   ApprovalCode
#
sub charge_keyed {
    my ($htx, %ccdat) = @_;
    my $ac = delete $ccdat{UseWeb}? q{ccw} : q{ccr};  # Merchant account
    return _cc_post_and_parse(
        $htx, $ac,
        {   SpecVersion => $htx->{cfg}->{$ac}->{SpecVersion}
                || "XWeb3.0",
            XWebID  => $htx->{cfg}->{$ac}->{XWebID},
            POSType => $htx->{cfg}->{$ac}->{POSType}
                || "PC",
            AuthKey         => $htx->{cfg}->{$ac}->{AuthKey},
            Mode            => $htx->{cfg}->{$ac}->{Mode},
            Industry        => $htx->{cfg}->{$ac}->{Industry},
            TerminalID      => $htx->{cfg}->{$ac}->{TerminalID},
            PinCapabilities => $htx->{cfg}->{$ac}->{PinCapabilities}
                || "FALSE",
            TrackCapabilities => $htx->{cfg}->{$ac}->{TrackCapabilities}
                || "NONE",

            #        TrackingID      => $htx->{cfg}->{$ac}->{TrackingID},
            TransactionType => "CreditSaleTransaction",
            DuplicateMode   => "CHECKING_OFF",
            CustomerPresent => "TRUE",
            CardPresent     => "TRUE",
            ECI             => "7",
            %ccdat
        }
    );
}

#
# Submit a charge from a swiped card.  Defaults to Track2 data.
# Required args:  $htx, then...
#        Track  => "....",
#        Amount   => "1.01"
#
# Sample card swipe data:
#   ;4777788899900025=1203101100001936?
#   ;4777788899900007=12041012531134412?
# Remove trailing newlines (chomp) the track data before passing to here.

sub charge_swiped {
    my ($htx, %ccdat) = @_;
    my $ac = delete $ccdat{UseWeb}? q{ccw} : q{ccr};  # Merchant account

    # Instead of AcctNum and ExpDate, send "Track" data.
    #   Set TrackCapabilities to "TRACK1", "TRACK2", or "BOTH"
    return _cc_post_and_parse(
        $htx, $ac,
        {   SpecVersion => $htx->{cfg}->{$ac}->{SpecVersion}
                || "XWeb3.0",
            XWebID  => $htx->{cfg}->{$ac}->{XWebID},
            POSType => $htx->{cfg}->{$ac}->{POSType}
                || "PC",
            AuthKey         => $htx->{cfg}->{$ac}->{AuthKey},
            Mode            => $htx->{cfg}->{$ac}->{Mode},
            Industry        => $htx->{cfg}->{$ac}->{Industry},
            TerminalID      => $htx->{cfg}->{$ac}->{TerminalID},
            PinCapabilities => $htx->{cfg}->{$ac}->{PinCapabilities}
                || "FALSE",
            TrackCapabilities => $htx->{cfg}->{$ac}->{TrackCapabilities}
                || "TRACK2",

            #        TrackingID      => $htx->{cfg}->{$ac}->{TrackingID},
            TransactionType => "CreditSaleTransaction",
            DuplicateMode   => "CHECKING_OFF",
            CustomerPresent => "TRUE",
            CardPresent     => "TRUE",
            ECI             => "7",
            %ccdat,

            #           Track           => $track_to_send,
        }
    );
}

#
# Submit a charge from a non-present card (MOTO)
#
sub charge_moto {
}

#
# Submit a refund request - card present
#
sub refund_keyed {
    my ($htx, %ccdat) = @_;
    my $ac = delete $ccdat{UseWeb}? q{ccw} : q{ccr};  # Merchant account
    return _cc_post_and_parse(
        $htx, $ac,
        {   SpecVersion => $htx->{cfg}->{$ac}->{SpecVersion}
                || "XWeb3.0",
            XWebID  => $htx->{cfg}->{$ac}->{XWebID},
            POSType => $htx->{cfg}->{$ac}->{POSType}
                || "PC",
            AuthKey         => $htx->{cfg}->{$ac}->{AuthKey},
            Mode            => $htx->{cfg}->{$ac}->{Mode},
            Industry        => $htx->{cfg}->{$ac}->{Industry},
            TerminalID      => $htx->{cfg}->{$ac}->{TerminalID},
            PinCapabilities => $htx->{cfg}->{$ac}->{PinCapabilities}
                || "FALSE",
            TrackCapabilities => $htx->{cfg}->{$ac}->{TrackCapabilities}
                || "NONE",

            #        TrackingID      => $htx->{cfg}->{$ac}->{TrackingID},
            #        TrackingID      => "Watch this 123",
            TransactionType => "CreditReturnTransaction",
            DuplicateMode   => "CHECKING_OFF",
            CustomerPresent => "TRUE",
            CardPresent     => "TRUE",
            %ccdat
        }
    );
}

sub refund_swiped {
    my ($htx, %ccdat) = @_;
    my $ac = delete $ccdat{UseWeb}? q{ccw} : q{ccr};  # Merchant account
    return _cc_post_and_parse(
        $htx, $ac,
        {   SpecVersion => $htx->{cfg}->{$ac}->{SpecVersion}
                || "XWeb3.0",
            XWebID  => $htx->{cfg}->{$ac}->{XWebID},
            POSType => $htx->{cfg}->{$ac}->{POSType}
                || "PC",
            AuthKey         => $htx->{cfg}->{$ac}->{AuthKey},
            Mode            => $htx->{cfg}->{$ac}->{Mode},
            Industry        => $htx->{cfg}->{$ac}->{Industry},
            TerminalID      => $htx->{cfg}->{$ac}->{TerminalID},
            PinCapabilities => $htx->{cfg}->{$ac}->{PinCapabilities}
                || "FALSE",
            TrackCapabilities => $htx->{cfg}->{$ac}->{TrackCapabilities}
                || "TRACK2",

            #        TrackingID      => $htx->{cfg}->{$ac}->{TrackingID},
            #        TrackingID      => "Watch this 123",
            TransactionType => "CreditReturnTransaction",
            DuplicateMode   => "CHECKING_OFF",
            CustomerPresent => "TRUE",
            CardPresent     => "TRUE",
            %ccdat
        }
    );
}


#
# Inquire about the batch amount.
#   Batchnum is six digits, ex: "000007"
#
sub batch_inquiry {
    my ($htx, $batchnum, $useweb) = @_;
    my $ac = $useweb? q{ccw} : q{ccr};  # Merchant account
    return _cc_post_and_parse(
        $htx, $ac,
        {   SpecVersion => $htx->{cfg}->{$ac}->{SpecVersion}
                || "XWeb3.0",
            XWebID  => $htx->{cfg}->{$ac}->{XWebID},
            POSType => $htx->{cfg}->{$ac}->{POSType}
                || "PC",
            AuthKey         => $htx->{cfg}->{$ac}->{AuthKey},
            Mode            => $htx->{cfg}->{$ac}->{Mode},
            Industry        => $htx->{cfg}->{$ac}->{Industry},
            TerminalID      => $htx->{cfg}->{$ac}->{TerminalID},
            PinCapabilities => $htx->{cfg}->{$ac}->{PinCapabilities}
                || "FALSE",
            TrackCapabilities => $htx->{cfg}->{$ac}->{TrackCapabilities}
                || "NONE",

            #        TrackingID      => $htx->{cfg}->{$ac}->{TrackingID},
            #        TrackingID      => "Watch this 123",
            TransactionType      => "BatchRequestTransaction",
            BatchTransactionType => "INQUIRY",
            BatchNum             => $batchnum,
        }
    );
}

#
# Settle the batch amount now.
#
sub batch_settle {
    my ($htx, $useweb) = @_;
    my $ac = $useweb? q{ccw} : q{ccr};  # Merchant account
    return _cc_post_and_parse(
        $htx, $ac,
        {   SpecVersion => $htx->{cfg}->{$ac}->{SpecVersion}
                || "XWeb3.0",
            XWebID  => $htx->{cfg}->{$ac}->{XWebID},
            POSType => $htx->{cfg}->{$ac}->{POSType}
                || "PC",
            AuthKey         => $htx->{cfg}->{$ac}->{AuthKey},
            Mode            => $htx->{cfg}->{$ac}->{Mode},
            Industry        => $htx->{cfg}->{$ac}->{Industry},
            TerminalID      => $htx->{cfg}->{$ac}->{TerminalID},
            PinCapabilities => $htx->{cfg}->{$ac}->{PinCapabilities}
                || "FALSE",
            TrackCapabilities => $htx->{cfg}->{$ac}->{TrackCapabilities}
                || "NONE",

            #        TrackingID      => $htx->{cfg}->{$ac}->{TrackingID},
            #        TrackingID      => "Watch this 123",
            TransactionType      => "BatchRequestTransaction",
            BatchTransactionType => "SETTLEMENT",
        }
    );
}

#
# Common function to post and parse the response
#
sub _cc_post_and_parse {
    my ($htx, $ac, $subdat) = @_;
    my $url = URI->new($htx->{cfg}->{$ac}->{url});
    $url->query_form(%$subdat);

    my $rstr = LWP::Simple::get "$url";
    return undef if !defined $rstr;

    # Response is a URI encoded string.  Decode it.
    my $ruri = URI->new();
    $ruri->query($rstr);
    my %rhash = $ruri->query_form();
    return \%rhash;
}

1;
