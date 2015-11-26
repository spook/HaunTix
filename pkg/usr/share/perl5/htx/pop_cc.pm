#=============================================================================
#
# Hauntix Point of Sale GUI - Credit Card Popup Panel
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use FindBin;
use Tk;
use Tk::Dialog;
use Tk::FmtEntry;
use Tk::FullKeypad;
use Tk::NumKeypad;
use htx::frame;

package htx::pop_cc;
  require Exporter;
  our @ISA    = qw(Exporter Tk::DialogBox);
  our @EXPORT = qw();
  use htx;
  use htx::pos_style;
  use htx::transaction;

  my $FW    = 400;
  my $FH    = 300;

#
# Make a new Credit Card Entry popup window
#
sub new {
    my ($class, $parent, $htx) = @_;
    my $this = $parent->DialogBox(
        -title          => "Payment by Credit Card",
        -default_button => "OK",
        -buttons        => ["Cancel", "OK", "Full Amount"]
    );
    $this->Subwidget("B_Cancel")->configure(-font => $FONT_LG);
    $this->Subwidget("B_Full Amount")->configure(-font => $FONT_LG);
    $this->Subwidget("B_OK")->configure(-font => $FONT_LG);
    $this->{wantsize} = [-width => $FW, -height => $FH];
    $this->{htx} = $htx;
    $this->{max_amount} = 0;    # max amount (cents), 0=no limit
    $this->{Amount}   = q{};
    $this->{AcctNum}  = q{};
    $this->{CardCode} = q{};
    $this->{ExpDate}  = q{};
    $this->{Comment} = q{};
    $this->{allow_dup} = 0;

    bless($this, $class);
    return $this;
}

sub fill {
    my $this = shift;

    my $l = $this->add('Frame')
        ->grid(-row => 0, -column => 0, -sticky => 'nsew');

    # Amount
    my $row = 0;
    $l->Label(-font => $FONT_LG, -text => "Amount to Charge:")
        ->grid(-row => $row, -column => 0, -sticky => 'nse');
    my $e_amt = $l->FmtEntry(
        -delay => 74,
        -fcmd => \&fmt_cash,
        -font            => $FONT_LG,
        -highlightcolor  => 'yellow',
        -textvariable    => \$this->{Amount},
        )
        ->grid(-row => $row, -column => 1, -sticky => 'nsew');
    $e_amt->bind('<FocusIn>' => sub {$this->{nkp}->configure(-entry => $e_amt)});
    $e_amt->bind('<Key>'     => sub {$this->test_fields;});  ### TODO bind to a change/edit/vcmd event so keypad triggers it too
    $e_amt->{_pop} = $this;

    # Note on max amount to charge
    ++$row;
    my $maxtxt
        = $this->{max_amount}
        ? "Maximum charge amount is " . dollars($this->{max_amount})
        : q{};
    $this->{lbl_max} = $l->Label(-font => $FONT_MD, -text => $maxtxt)
        ->grid(-row => $row, -column => 0, -columnspan => 2, -sticky => 'nsew');

    # Account Number
    ++$row;
    $l->Label(-font => $FONT_LG, -text => "Credit Card Number:")
        ->grid(-row => $row, -column => 0, -sticky => 'nse');
    my $e_acctnum = $l->FmtEntry(
        -delay          => 74,
        -fcmd           => \&fmt_cc,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{AcctNum},
    )->grid(-row => $row, -column => 1, -sticky => 'nsew');
    $e_acctnum->bind('<FocusIn>' => sub {$this->{nkp}->configure(-entry => $e_acctnum)});
    $e_acctnum->bind('<Key>'     => sub {$this->test_fields;});
    $e_acctnum->{_pop} = $this;

    # Expiration Date
    ++$row;
    $l->Label(-font => $FONT_LG, -text => "Expiration Date:")
        ->grid(-row => $row, -column => 0, -sticky => 'nse');
    my $e_exp = $l->FmtEntry(
        -delay => 74,
        -fcmd => \&fmt_expdate,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{ExpDate},
    )->grid(-row => $row, -column => 1, -sticky => 'nsew');
    $e_exp->bind('<FocusIn>' => sub {$this->{nkp}->configure(-entry => $e_exp)});
    $e_exp->bind('<Key>' => sub {$this->test_fields;});
    $e_exp->{_pop} = $this;

    # CCV Field
    ++$row;
    $l->Label(-font => $FONT_LG, -text => "CCV Number:")
        ->grid(-row => $row, -column => 0, -sticky => 'nse');
    my $e_ccv = $l->FmtEntry(
        -delay => 74,
        -fcmd => \&fmt_ccv,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{CardCode},
    )->grid(-row => $row, -column => 1, -sticky => 'nsew');
    $e_ccv->bind('<FocusIn>' => sub {$this->{nkp}->configure(-entry => $e_ccv)});
    $e_ccv->bind('<Key>'     => sub {$this->test_fields;});
    $e_ccv->{_pop} = $this;

    # Comment field
    ++$row;
    $l->Label(-font => $FONT_LG, -text => "Comment:")
        ->grid(-row => $row, -column => 0, -sticky => 'nse');
    my $e_comment = $l->FmtEntry(
        -delay => 74,
        -fcmd => \&fmt_comment,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{Comment},
    );
    $e_comment->bind('<FocusIn>'  => sub {$this->{nkp}->configure(-entry => $e_comment);
                                          $this->{akp}->configure(-state => 'normal');});
    $e_comment->bind('<FocusOut>' => sub {$this->{akp}->configure(-state => 'disabled');});
    $e_comment->grid(-row => $row, -column => 1, -sticky => 'nsew');
    $e_comment->{_pop} = $this;

    # Processing Options
    ++$row;
    $l->Label(-font => $FONT_LG, -text => "Options:")
        ->grid(-row => $row, -column => 0, -sticky => 'nse');
    $l->Checkbutton(-text => "Allow duplicate charge",
                    -font => $FONT_BG,
                    -variable => \$this->{allow_dup}
    )->grid(-row => $row, -column => 1, -sticky => 'nsew');

    # Warning messages
    ++$row;
    $this->{lbl_msg} = $l->Label(
        -font       => $FONT_MD,
        -foreground => $COLOR_RED,
        -text       => q{}
    )->grid(-row => $row, -column => 0, -columnspan => 2, -sticky => 'nsew');

    # Numeric keypad
    $this->{nkp} = $this->NumKeypad(-font => $FONT_XL, -entry => $e_acctnum)
        ->grid(-row => 0, -column => 1, -sticky => 'nsew');

    # Alpha keypad
    $this->{akp} = $this->FullKeypad(-font => $FONT_MD,
                                     -entry => $e_comment,
                                     -state => 'disabled')
        ->grid(-row => 1, -column => 0, -columnspan => 2, -sticky => 'nsew');

    # Initial field check
    $this->test_fields;

    # Set focus to the card number field
    $e_acctnum->focus;
    return $this;
}

sub fmt_cash {
    my ($old, $i, $w) = @_;

    # Did we get swipe-track data mixed-in this field?
    if ($old =~ s/(;\d{13,19}=\d{7,21}\?)//) {
        $w->{_pop}->parse_track($1);
        $i = length($old);
    }

    # Make the new string
    my $new = $old;
    $new =~ s/[^\d\.]//g;             # remove all but digits and decimal
    if ($new eq q{.}) {$old = $new = "0."; ++$i;}   # special for dp-only
    $new =~ s/(\.\d{0,2}).*$/$1/;                   # max two past dp
    my $lzc = $new =~ m/^(0+)/? -length($1) : 0;    # leading zero correction 1
    $new = sprintf '$%4.2f', $new if $new ne q{};   # if blank, leave blank
    $lzc += $new =~ m/^\$(0+)/? length($1) : 0;     # leading zero correction 2

    # Add commas
    $new = reverse $new;
    $new =~ s/(\d{3})(?=\d)(?!\d*\.)/$1,/g;
    $new = reverse $new;

    # Make a marked string
    my $mrk
        = substr($old, 0, $i) . q{*} . substr($old, $i, length($old) - $i);
    $mrk =~ s/[^\d\.\*]//g;    # remove all but digits, decimal, and marker

    # Find new insert point
    my $j = $lzc;
    my $k = 0;
    foreach my $c (split //, $new) {
        if ($c eq q{$} || $c eq q{,}) {
            $j++;
            next;
        }
        last if substr($mrk, $k++, 1) eq q{*};    # found the marker
        $j++;
    }

    # Test fields - are we complete?
    $w->afterIdle(sub{$w->{_pop}->test_fields;});

    return ($new, $j);
}

sub fmt_cc {
    my ($old, $i, $w) = @_;

    # Did we get swipe-track data mixed-in this field?
    if ($old =~ s/(;\d{13,19}=\d{7,21}\?)//) {
        $w->{_pop}->parse_track($1);
        $old = $w->{_pop}->{AcctNum};
        $i = length($old);
    }

    # To figure the new insert cursor position, 
    #  format just the left half and see where it lands.
    my $lf = substr($old, 0, $i);
    $lf =~ s/[^\d]//g;              # remove all but digits
    $lf = substr($lf, 0, 19);                  # max 19 digits
    while ($lf =~ s/(\d{4})(\d)/$1-$2/) { };   # group to fours
    my $j = length($lf);                       # get new position

    # Now format again the whole thing
    my $new = $old;
    $new =~ s/[^\d]//g;                        # nuke all but digits
    $new = substr($new, 0, 19);                # max 19 digits
    while ($new =~ s/(\d{4})(\d)/$1-$2/) { };  # group to fours

    # Test fields - are we complete?
    $w->afterIdle(sub{$w->{_pop}->test_fields;});

    return ($new, $j);
}

sub fmt_ccv {
    my ($old, $i, $w) = @_;

    # Did we get swipe-track data mixed-in this field?
    if ($old =~ s/(;\d{13,19}=\d{7,21}\?)//) {
        $w->{_pop}->parse_track($1);
        $i = length($old);
    }

    # format it
    my $new = $old;
    $new =~ s/[^\d]//g;
    $new = substr($new, 0, 4);    # max 4 digits

    # find cursor position
    my $left = substr($old,0,$i);
    $left =~ s/[^\d]//g;
    my $j = length($left);

    # Test fields - are we complete?
    $w->afterIdle(sub{$w->{_pop}->test_fields;});

    return ($new, $j);
}

sub fmt_expdate {
    my ($old, $i, $w) = @_;

    # Did we get swipe-track data mixed-in this field?
    if ($old =~ s/(;\d{13,19}=\d{7,21}\?)//) {
        $w->{_pop}->parse_track($1);
        $old = $w->{_pop}->{ExpDate};
        $i = length($old);
    }

    # To figure the new insert cursor position, 
    #  format just the left half and see where it lands.
    my $lf = substr($old, 0, $i);
    $lf =~ s/[^\d]//g;              # remove all but digits
    $lf = substr($lf, 0, 4);                   # max 4 digits
    while ($lf =~ s:(\d{2})(\d):$1/$2:) { };   # group to fours
    my $j = length($lf);                       # get new position

    # Now format again the whole thing
    my $new = $old;
    $new =~ s/[^\d]//g;                        # nuke all but digits
    $new = substr($new, 0, 4);                 # max 4 digits
    while ($new =~ s:(\d{2})(\d):$1/$2:) { };  # group to fours

    # Test fields - are we complete?
    $w->afterIdle(sub{$w->{_pop}->test_fields;});

    return ($new, $j);
}

sub fmt_comment {
    my ($old, $i, $w) = @_;

    # Did we get swipe-track data mixed-in this field?
    if ($old =~ s/(;\d{13,19}=\d{7,21}\?)//) {
        $w->{_pop}->parse_track($1);
        $i = length($old);
    }

    # Test fields - are we complete?
    $w->afterIdle(sub{$w->{_pop}->test_fields;});

    # No other formatting
    return ($old, $i);
}

sub get_acct {
    my $this = shift;
    return $this->{AcctNum};
}

sub get_amt {   #cents
    my $this = shift;
    return cents($this->{Amount});
}

sub get_ccv {
    my $this = shift;
    return $this->{CardCode};
}

sub get_dup {
    my $this = shift;
    return $this->{allow_dup};
}

sub get_expdate {
    my $this = shift;
    return $this->{ExpDate};
}

sub get_info {
    my $this = shift;
    return $this->{Comment};
}

sub get_track {
    my $this = shift;
    return $this->{Track};
}

sub parse_track {
    my ($this, $track) = @_;
    $this->{Track} = $track;
    if ($track =~ m/;           # Start Sentinel
                    (\d{13,19}) # Primary account number
                    =           # Separator
                    (\d\d)      # ExpDate YY
                    (\d\d)      # ExpDate MM
                    (\d\d\d)    # Service code
                    \d*         # Discretionary data
                    \?          # End sentinel
                   /x) {
        $this->{AcctNum} = $1;
        $this->{ExpDate} = "$3/$2";
        $this->{CardCode} = q{};
    }
    $this->Exit; #close the dialogbox, as-if OK was pressed
}

sub set_amt {   # cents
    my ($this, $cents) = @_;
    $this->{Amount} = dollars($cents);
    return $cents;
}

sub set_info {
    my ($this, $info) = @_;
    return $this->{Comment} = $info;
}

sub set_max {
    my ($this, $cents) = @_;
    $this->{max_amount} = $cents;
    my $maxtxt
        = $this->{max_amount}
        ? "Maximum charge amount is " . dollars($this->{max_amount})
        : q{};
    $this->{lbl_max}->configure(-text => $maxtxt);
    return $this->{max_amount};
}

# Display this popup
sub show {
    my ($this, $amt, $info) = @_;
    if (defined $amt) {
        $this->set_amt($amt);
        $this->test_fields;
    }
    $this->set_info($info) if defined $info;
    return $this->Show();
}

sub test_fields {
    my $this = shift;

    # Cleanup fields
    my $amount = cents($this->{Amount});
    my $acctnum = $this->{AcctNum};
    $acctnum  =~ s/[^\d]//g;
    my $cardcode = $this->{CardCode};
    $cardcode =~ s/[^\d]//g;
    my $expdate = $this->{ExpDate};
    $expdate =~ s/[^\d]//g;

    # Is there an amount?
    if (!$amount) {
        $this->{lbl_msg}->configure(-text => "Enter the amount to charge");
        $this->Subwidget("B_OK")->configure(-state => 'disabled');
        return 0;
    }

    # Have we exceeded the max amount?
    if ($this->{max_amount} && ($amount > $this->{max_amount})) {
        my $msg
            = "The charge amount must be no more than "
            . dollars($this->{max_amount})
            . ". Please enter a lower amount.";
        $this->{lbl_msg}->configure(-text => $msg);
        $this->Subwidget("B_OK")->configure(-state => 'disabled');
        return 0;
    }

    # Do we have valid CC info?
    if (!$this->{Track} && (!$acctnum || !$cardcode || !$expdate)) {
        $this->{lbl_msg}->configure(-text => "Enter card info or swipe card.");
        $this->Subwidget("B_OK")->configure(-state => 'disabled');
        $this->Subwidget("B_Full Amount")->configure(-state => 'disabled');
        return 0;
    }
    my $msg = q{};
    $msg .= "Invalid Credit Card Number. "
        if !$this->{Track} && $acctnum !~ m/^\d{13,19}$/;
    $msg .= "Invalid CCV Number. "
        if !$this->{Track} && $cardcode !~ m/^\d{3,4}$/;
    $msg .= "Invalid Expiration Date."
        if !$this->{Track} && $expdate  !~ m/^(0[1-9]|1[0-2])\d\d$/;
    if ($msg) {
        $this->{lbl_msg}->configure(-text => $msg);
        $this->Subwidget("B_OK")->configure(-state => 'disabled');
        $this->Subwidget("B_Full Amount")->configure(-state => 'disabled');
        return 0;
    }

    # Good to go
    $this->{lbl_msg}->configure(-text => q{});
    $this->Subwidget("B_OK")->configure(-state => 'normal');
    $this->Subwidget("B_Full Amount")->configure(-state => 'normal');
    return 1;
}

1;
