#=============================================================================
#
# Hauntix Point of Sale GUI - Transaction lookup panel
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use FindBin;
use Tk;
use Tk::Dialog;
use Tk::NumKeypad;
use Tk::FullKeypad;
use Tk::FmtEntry;
use htx::frame;
use htx::pop_error;

package htx::pop_find_trn;
require Exporter;
our @ISA = qw(Tk::DialogBox);
use htx;
use htx::pos_style;
use htx::transaction;

my $FW = 400;
my $FH = 300;

my $TRNINFO = [
    trnId         => [0, 0, 1, "Transaction ID"],
    trnPickupCode => [1, 0, 1, "Pickup Code Suffix"],
    trnTimestamp  => [2, 0, 1, "Date & Time"],
    trnPhase      => [3, 0, 1, "Phase"],
    trnUser       => [4, 0, 1, "Cashier"],
    trnStation    => [5, 0, 1, "Station ID"],
    trnRemoteAddr => [6, 0, 1, "IP Address (Web)"],
    trnEmail      => [7, 0, 1, "Email Address"],
    tixcount      => [8, 0, 1, "Tickets"],

    subtotal         => [0, 1, 1, "Subtotal"],
    trnTaxAmount     => [1, 1, 1, "Sales Tax"],
    trnTaxRate       => [2, 1, 1, "Tax rate"],
    trnServiceCharge => [3, 1, 1, "Service Charge"],
    total            => [4, 1, 1, "Total"],
    trnCashAmount    => [5, 1, 1, "Cash Tendered"],
    trnCheckAmount   => [6, 1, 1, "Check Amount"],
    cc_tally         => [7, 1, 1, "Charge Amount"],
    change           => [8, 1, 1, "Change Given"],

    trnCheckInfo => [9,  0, 3, "Check Note"],
    trnNote      => [10, 0, 3, "Transaction Note"],
];

#
# Make a new panel
#
sub new {
    my ($class, $parent, $htx) = @_;
    my $this = $parent->DialogBox(
        -title          => "Lookup a Sales Transaction",
        -default_button => "Close",
        -buttons        => ["Close"]
    );
    $this->Subwidget("B_Close")->configure(-font => $FONT_LG);
    $this->{wantsize} = [-width => $FW, -height => $FH];
    $this->{htx}      = $htx;
    $this->{trnId}    = q{};
    bless($this, $class);
    return $this;
}

sub fill {
    my $this = shift;

    # Transaction entry and info - Upper section Left
    my $l = $this->add('Frame')->grid(-row => 0, -column => 0, -sticky => 'nsew');

    # Transaction ID
    $l->Label(-font => $FONT_MD, -text => "Transaction ID:")
        ->grid(-row => 0, -column => 0, -sticky => 'nsew');

    my $e_id = $l->Entry(
        -font           => $FONT_MD,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{trnId},
    );
    $e_id->grid(-row => 0, -column => 1, -sticky => 'nsew');
    $e_id->bind('<FocusIn>' => sub {$this->{nkp}->configure(-entry => $e_id)});
    $e_id->{_pop} = $this;

    $l->Button(-font => $FONT_MD, -text => "Find", -command => sub {$this->lookup_trn()})
        ->grid(-row => 0, -column => 2, -sticky => 'nsew');

    # Warning messages
    $this->{lbl_msg} = $l->Label(
        -font       => $FONT_MD,
        -foreground => $COLOR_RED,
        -text       => qq{\n}
    )->grid(-row => 1, -column => 0, -columnspan => 2, -sticky => 'nsew');

    # Transaction Info panel
    $this->{info} = $l->Frame->grid(-row => 2, -column => 0, -columnspan => 3, -sticky => 'nsew');
    $this->fill_info();

    # Numeric keypad  & ticket/receipt buttons - Right Side
    my $m = $this->add('Frame')->grid(-row => 0, -column => 1, -sticky => 'nsew');
    $this->{nkp} = $m->NumKeypad(
        -font   => $FONT_XL,
        -entry  => $e_id,
        -keysub => {'.' => "\x{21d0}"},
        -keyval => {'.' => 'BACKSPACE'},
    )->pack;
    $this->{btn_rct} = $m->Button(
        -text    => "Reprint Receipt",
        -font    => $FONT_MD,
        -command => sub {$this->reprint_rct},
        -state   => 'disabled',
    )->pack;
    $this->{btn_tix} = $m->Button(
        -text    => "Reprint Tickets",
        -font    => $FONT_MD,
        -command => sub {$this->reprint_tix},
        -state   => 'disabled',
    )->pack;

    # Alpha keypad - lower section
    #    $this->{akp} = $this->FullKeypad(
    #        -font  => $FONT_MD,
    #        -entry => $e_id,
    #        -state => 'disabled'
    #    )->grid(-row => 1, -column => 0, -columnspan => 3, -sticky => 'nsew');

    return $this;
}

sub fill_info {
    my $this  = shift;
    my $panel = $this->{info};
    my $trn   = $this->{curtrn};

    # Delete existing items in the panel
    foreach my $kid ($panel->children()) {
        $kid->destroy() if Tk::Exists $kid;
    }

    # Figure out ticket states & shows, if any
    my $tixstates = q{None};
    if ($trn && $trn->tickets) {
        my %ts = ();
        foreach my $tix ($trn->tickets) {
            $ts{$tix->{tixState} . " for #" . $tix->{shoId}}++;
        }
        $tixstates = join("\n", map {"$ts{$_} $_"} sort keys %ts);
    }

    # Display the info
    my $n = 0;
    my $field;
    while ($field = $TRNINFO->[2 * $n],
        my $row   = $TRNINFO->[2 * $n + 1]->[0],
        my $col   = $TRNINFO->[2 * $n + 1]->[1],
        my $cspan = $TRNINFO->[2 * $n + 1]->[2],
        my $label = $TRNINFO->[2 * $n + 1]->[3], ++$n, $field)
    {
        my $color
            = !$trn ? $COLOR_DIM
            : $trn->phase eq $TRN_PHASE_FIN ? $COLOR_BLUE
            : $trn->phase eq $TRN_PHASE_XCL ? $COLOR_RED
            : $trn->phase eq $TRN_PHASE_VYD ? $COLOR_RED
            :                                 $COLOR_DKGRN;
        $panel->Label(
            -font       => $FONT_MD,
            -foreground => $color,
            -text       => "$label : ",
        )->grid(-row => $row, -column => $col * 2, -sticky => 'nse');
        my $value
            = !$trn ? q{---}
            : $field eq "trnPhase"         ? $trn->phase_name
            : $field eq "trnCashAmount"    ? dollars($trn->{$field} || 0)
            : $field eq "trnCheckAmount"   ? dollars($trn->{$field} || 0)
            : $field eq "trnServiceCharge" ? dollars($trn->{$field} || 0)
            : $field eq "trnTaxAmount"     ? dollars($trn->{$field} || 0)
            : $field eq "trnTaxRate"       ? sprintf("%5.2f%%", $trn->{$field} * 100 || 0)
            : $field eq "cc_tally" ? dollars($trn->{$field} || 0)
            : $field eq "subtotal" ? dollars($trn->{$field} || 0)
            : $field eq "total"    ? dollars($trn->{$field} || 0)
            : $field eq "change"   ? dollars($trn->{$field} || 0)
            : $field eq "tixcount" ? $tixstates
            : !defined $trn->{$field} ? "--undef--"
            :                           $trn->{$field};

        #new, open, pay, final or x-cancelled, void
        $panel->Label(
            -font       => $FONT_MD,
            -foreground => $color,
            -text       => $value,
            )->grid(
            -row        => $row,
            -column     => $col * 2 + 1,
            -sticky     => $col ? 'nse' : 'nsw',
            -columnspan => $cspan
            );
    }

    # Display ticket states
    #    my @tix = $trn? $trn->tickets : ();
    #    if (@tix) {
    #        $panel->Label(
    #            -font       => $FONT_MD,
    #            -foreground => $COLOR_BLUE,
    #            -text       => "Tickets",
    #        )->grid(-row => $row,
    #                -column => $col * 2 + 1,
    #                -sticky => $col? 'nse' : 'nsw',
    #                -columnspan => $cspan);
    #    }
}

sub lookup_trn {
    my $this  = shift;
    my $htx   = $this->{htx};
    my $trnId = $this->{trnId};
    $trnId =~ s/^\s*(.+?)\s*$/$1/;
    return unless $trnId;

    my $trn = htx::transaction->load(-htx => $htx, -trnId => $trnId);
    if ($trn->error) {
        htx::pop_error::show({mw => $this}, "Error loading transaction:\n" . $trn->error);

        # Clear current display info
        $this->{curtrn} = undef;
        $this->fill_info();
        $this->{"btn_rct"}->configure(-state => 'disabled');
        $this->{"btn_tix"}->configure(-state => 'disabled');
        return;
    }

    # Fill in info
    $this->{curtrn} = $trn;
    $this->fill_info();

    # Enable buttons
    $this->{"btn_rct"}->configure(-state => $trn->phase eq $TRN_PHASE_FIN ? 'normal' : 'disabled');
    $this->{"btn_tix"}->configure(-state => ($trn->phase eq $TRN_PHASE_FIN)
            && scalar($trn->tickets) ? 'normal' : 'disabled');
}

sub reprint_rct {
    my $this = shift;
    my $htx  = $this->{htx};
    my $trn  = $this->{curtrn};
    return if !$trn;

    my $rct = new htx::pos_rcpt($htx, $trn);
    $rct->print_receipt;
}

sub reprint_tix {
    my $this = shift;
    my $htx  = $this->{htx};
    my $trn  = $this->{curtrn};
    return if !$trn;

    foreach my $tix ($trn->tickets) {
        $tix->print_ticket;
    }
}

sub show {
    my ($this, $amt, $info) = @_;
    if (defined $amt) {
        $this->set_amt($amt);
        $this->test_fields;
    }
    $this->set_info($info) if defined $info;
    return $this->Show();
}

1;
