#=============================================================================
#
# Hauntix Point of Sale GUI - Price Adjust Popup
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

package htx::pop_adj;
  our @ISA    = qw(Tk::DialogBox);
  use htx;
  use htx::pos_style;
  use htx::sale;
  use htx::transaction;

  my $FW    = 300;
  my $FH    = 300;

#
# Make a new popup
#
sub new {
    my ($class, $parent, $htx, $sale) = @_;
    my $this = $parent->DialogBox(
        -title          => "Price Adjust",
        -default_button => "OK",
        -buttons        => ["Cancel", "OK"]
    );
    $this->Subwidget("B_Cancel")->configure(-font => $FONT_LG);
    $this->Subwidget("B_OK")->configure(-font => $FONT_LG);
    $this->{wantsize} = [-width => $FW, -height => $FH];
    $this->{htx}  = $htx;
    $this->{sale} = $sale;   # Sale we're adjusting
    $this->{paid} = 0;       # revised amount paid, in cents
    $this->{note} = q{};     # reason
    bless($this, $class);
    return $this;
}

sub fill {
    my $this = shift;
    my $sale = $this->{sale};
    my $l = $this->add('Frame')
        ->grid(-row => 0, -column => 0, -sticky => 'nsew');

    # Title block
    $l->Label(-font => $FONT_XL, 
              -fg   => $COLOR_DKGRN,
              -text => "Price Adjust")
        ->grid(-row => 0, -column => 0, -columnspan => 2, -sticky => 'nsew');
    $l->Label(-font => $FONT_LG, -text => "$sale->{salQuantity} $sale->{salName}")
        ->grid(-row => 1, -column => 0, -columnspan => 2, -sticky => 'nsew');

    # Original amount
    $l->Label(-font => $FONT_LG, -text => "Original Price:")
        ->grid(-row => 2, -column => 0, -sticky => 'nsew');
    $l->Label(-font => $FONT_LG, -text => dollars($sale->{salCost}))
        ->grid(-row => 2, -column => 1, -sticky => 'w');

    # Revised amount
    $l->Label(-font => $FONT_LG, -text => "Revised Price:")
        ->grid(-row => 3, -column => 0, -sticky => 'nsew');
    my $e_amt = $l->FmtEntry(
        -fcmd            => \&fmt_cash,
        -font            => $FONT_LG,
        -highlightcolor  => 'yellow',
        -textvariable    => \$this->{paid},
        );
    $e_amt->grid(-row => 3, -column => 1, -sticky => 'nsew');
    $e_amt->bind('<FocusIn>' => sub {$this->{nkp}->configure(-entry => $e_amt)});
    $e_amt->{_pop} = $this;

    # Reason Note
    $l->Label(-font => $FONT_LG, -text => "Reason:")
        ->grid(-row => 4, -column => 0, -sticky => 'nsew');
    my $e_comment = $l->FmtEntry(
        -fcmd           => \&fmt_comment,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{Comment},
    );
    $e_comment->bind('<FocusIn>'  => sub {$this->{nkp}->configure(-entry => $e_comment);
                                          $this->{akp}->configure(-state => 'normal');});
    $e_comment->bind('<FocusOut>' => sub {$this->{akp}->configure(-state => 'disabled');});
    $e_comment->grid(-row => 4, -column => 1, -sticky => 'nsew');
    $e_comment->{_pop} = $this;

    # Warning messages
    $this->{lbl_msg} = $l->Label(
        -font       => $FONT_MD,
        -foreground => $COLOR_RED,
        -text       => qq{\n}
    )->grid(-row => 5, -column => 0, -columnspan => 2, -sticky => 'nsew');

    # Numeric keypad
    $this->{nkp} = $this->NumKeypad(-font => $FONT_XL, -entry => $e_amt)
        ->grid(-row => 0, -column => 1, -sticky => 'nsew');

    # Alpha keypad
    $this->{akp} = $this->FullKeypad(-font => $FONT_MD,
                                     -entry => $e_comment,
                                     -state => 'disabled')
        ->grid(-row => 1, -column => 0, -columnspan => 2, -sticky => 'nsew');

    return $this;
}

sub fmt_cash {
    my ($old, $i, $w) = @_;

    # Make the new string
    my $new = $old;
    $new =~ s/[^\d\.]//g;             # remove all but digits and decimal
    if ($new eq q{.}) {$old = $new = "0."; ++$i;}   # special for dp-only
    $new =~ s/(\.\d{0,2}).*$/$1/;                   # max two past dp
    $new = sprintf '$%4.2f', $new if $new ne q{};   # if blank, leave blank

    # Add commas
    $new = reverse $new;
    $new =~ s/(\d{3})(?=\d)(?!\d*\.)/$1,/g;
    $new = reverse $new;

    # Make a marked string
    my $mrk
        = substr($old, 0, $i) . q{*} . substr($old, $i, length($old) - $i);
    $mrk =~ s/[^\d\.\*]//g;    # remove all but digits, decimal, and marker

    # Find new insert point
    my $j = 0;
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

sub fmt_comment {
    my ($old, $i, $w) = @_;

    # Test fields - are we complete?
    $w->afterIdle(sub{$w->{_pop}->test_fields;});

    # No other formatting
    return ($old, $i);
}

sub get_amt {   # cents
    my $this = shift;
    return cents($this->{paid});
}

sub get_note {
    my $this = shift;
    return $this->{note};
}

sub set_amt {   # cents
    my ($this, $cents) = @_;
    $this->{paid} = dollars($cents);
    return $cents;
}

sub set_note {
    my ($this, $info) = @_;
    return $this->{note} = $info;
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

sub test_fields {
    my $this = shift;

    # Is there an amount?
    my $amount = cents($this->{paid});
    if (!$amount) {
        $this->{lbl_msg}->configure(-text => "Enter the revised amount.\n");
        $this->Subwidget("B_OK")->configure(-state => 'disabled');
        return 0;
    }

    # Good to go
    $this->{lbl_msg}->configure(-text => qq{\n});
    $this->Subwidget("B_OK")->configure(-state => 'normal');
    return 1;
}

1;

