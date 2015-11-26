#=============================================================================
#
# Hauntix Point of Sale GUI - Void Ticket Popup
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

package htx::pop_void_tix;
require Exporter;
our @ISA = qw(Tk::DialogBox);
use htx;
use htx::pos_style;
use htx::ticket;

my $FW = 400;
my $FH = 300;

#
# Make a new popup
#
sub new {
    my ($class, $parent, $htx) = @_;
    my $this = $parent->DialogBox(
        -title          => "Void Transaction and Tickets",
        -default_button => "Ignore This Error", #"Close",
        -buttons        => ["Close"]
    );
    $this->Subwidget("B_Close")->configure(-font => $FONT_LG);
    $this->{wantsize} = [-width => $FW, -height => $FH];
    $this->{htx}      = $htx;
    $this->{trnid}    = q{};
    $this->{tixno}    = q{};
    $this->{alltix}   = 0;
    $this->{reason}   = q{};
    $this->{prior}    = q{};

    bless($this, $class);
    return $this;
}

sub do_void {
    my $this   = shift;
    my $htx    = $this->{htx};
    my $trnId  = $this->{trnid};
    my $tixno  = $this->{tixno};
    my $alltix = $this->{alltix};
    my $reason = $this->{reason};
    $reason =~ s/\"//gm;
    $this->{prior} = q{};

    return unless $trnId || $tixno;

    my $cmd = "htx-void -v -v ";
    $cmd .= qq{-r "$reason" };
    $cmd .= "-a " if $alltix;
    $cmd .= $trnId ? "-T $trnId " : "-t $tixno ";

    my $out = qx($cmd 2>&1);
    if ($?) {

        # Failed
        $this->{lbl_msg}->configure(-text => "Failed, please try again",
                                    -foreground => $COLOR_RED);
        $trnId ? $this->{e_trnid}->focus : $this->{e_tixno}->focus;
        htx::pop_error::show({mw => $this}, "Void Failed:\n" . $out);
        $this->{trnid} = q{};
        $this->{tixno} = q{};
        return 1;
    }

    # Success
    $this->{prior}
        = "Void of "
        . ($trnId ? "Transaction $trnId" : "ticket $tixno")
        . " Successful.\n"
        . "Enter next ticket or transaction";
    $this->{trnid} = q{};
    $this->{tixno} = q{};
    $this->{lbl_msg}->configure(-text => "Void Successful");
    $trnId ? $this->{e_trnid}->focus : $this->{e_tixno}->focus;
    return 1;
}

sub fill {
    my $this = shift;
    my $l = $this->add('Frame')->grid(-row => 0, -column => 0, -sticky => 'nsew');

    # Title
    $l->Label(-font => $FONT_LG, -text => "Void Transaction or Tickets")
        ->grid(-row => 0, -column => 0, -sticky => 'n', -columnspan => 2);

    # Numbers
    $this->{lbl_trnid} = $l->Label(-font => $FONT_LG, -text => "Transaction Number:")
        ->grid(-row => 1, -column => 0, -sticky => 'nsew');
    my $e_trnid = $l->FmtEntry(
        -fcmd           => \&fmt_int,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{trnid},
    );
    $e_trnid->grid(-row => 1, -column => 1, -sticky => 'nsew');
    $e_trnid->bind('<FocusIn>' => sub {$this->{nkp}->configure(-entry => $e_trnid)});
    $e_trnid->{_pop} = $this;
    $this->{e_trnid} = $e_trnid;

    $this->{lbl_tixno} = $l->Label(-font => $FONT_LG, -text => "Ticket Number:")
        ->grid(-row => 2, -column => 0, -sticky => 'nsew');
    my $e_tixno = $l->FmtEntry(
        -fcmd           => \&fmt_int,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{tixno},
    );
    $e_tixno->grid(-row => 2, -column => 1, -sticky => 'nsew');
    $e_tixno->bind('<FocusIn>' => sub {$this->{nkp}->configure(-entry => $e_tixno)});
    $e_tixno->{_pop} = $this;
    $this->{e_tixno} = $e_tixno;

    # Reason
    $l->Label(-font => $FONT_LG, -text => "Reason:")
        ->grid(-row => 3, -column => 0, -sticky => 'nsew');
    my $e_comment = $l->FmtEntry(
        -fcmd           => \&fmt_comment,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{reason},
    );
    $e_comment->bind(
        '<FocusIn>' => sub {
            $this->{nkp}->configure(-entry => $e_comment);
            $this->{akp}->configure(-state => 'normal');
        }
    );
    $e_comment->bind('<FocusOut>' => sub {$this->{akp}->configure(-state => 'disabled');});
    $e_comment->grid(-row => 3, -column => 1, -sticky => 'nsew');
    $e_comment->{_pop} = $this;

    # Action buttons
    $this->{chk_alltix} = $l->Checkbutton(
        -text     => "Include all related tickets",
        -font     => $FONT_MD,
        -variable => \$this->{alltix}
    )->grid(-row => 4, -column => 0, -sticky => 'nsew');

    $this->{btn_doit} = $l->Button(
        -text    => "Void It",
        -font    => $FONT_LG,
        -command => sub {$this->do_void}
    )->grid(-row => 4, -column => 1, -sticky => 'ns');

    # Result Text
    $this->{lbl_msg} = $l->Label(
        -font       => $FONT_MD,
        -foreground => $COLOR_RED,
        -text       => qq{Enter Transaction or Ticket Number}
    )->grid(-row => 5, -column => 0, -columnspan => 2, -sticky => 'nsew');

    # Numeric keypad
    $this->{nkp} = $this->NumKeypad(
        -font   => $FONT_XL,
        -entry  => $e_tixno,
        -keysub => {'.' => "\x{21d0}"},
        -keyval => {'.' => 'BACKSPACE'},
    )->grid(-row => 0, -column => 1, -sticky => 'nsew');

    # Alpha keypad
    $this->{akp} = $this->FullKeypad(
        -font  => $FONT_MD,
        -entry => $e_comment,
        -state => 'disabled'
    )->grid(-row => 1, -column => 0, -columnspan => 2, -sticky => 'nsew');

    # Action bindings
    $this->bind('<cr>' => sub {$this->do_void});
    $this->bind('<Return>' => sub {$this->do_void});
    $this->bind('<KP_Enter>' => sub {$this->do_void});

    return $this;
}

sub fmt_int {
    my ($old, $i, $w) = @_;

    # Make the new string
    my $new = $old;
    $new =~ s/[^\d]//g;    # remove all but digits
    $new = int($new || 0);
    $new = q{} if $new == 0;
    my $j = $i;
    $j = length($new) if $j > length($new);

    # Test fields - are we complete?
    $w->afterIdle(sub {$w->{_pop}->test_fields;});

    return ($new, $j);
}

sub fmt_comment {
    my ($old, $i, $w) = @_;

    # Test fields - are we complete?
    $w->afterIdle(sub {$w->{_pop}->test_fields;});

    # No other formatting
    return ($old, $i);
}

sub show {
    my $this = shift;
    $this->{e_trnid}->focus;
    return $this->Show();
}

sub test_fields {
    my $this = shift;

    # Is there a transaction or ticket number?
    if ($this->{trnid}) {
        $this->{lbl_tixno}->configure(-foreground => $COLOR_DIM);
        $this->{e_tixno}->configure(-state => 'disabled');
        $this->{chk_alltix}->configure(-state => 'disabled');
        $this->{btn_doit}->configure(-state => 'normal');
        $this->{lbl_msg}->configure(-text => q{});
    }
    elsif ($this->{tixno}) {
        $this->{lbl_trnid}->configure(-foreground => $COLOR_DIM);
        $this->{e_trnid}->configure(-state => 'disabled');
        $this->{btn_doit}->configure(-state => 'normal');
        $this->{chk_alltix}->configure(-state => 'normal');
        $this->{lbl_msg}->configure(-text => q{});
    }
    else {
        $this->{lbl_trnid}->configure(-foreground => $COLOR_FG);
        $this->{e_trnid}->configure(-state => 'normal');
        $this->{lbl_tixno}->configure(-foreground => $COLOR_FG);
        $this->{e_tixno}->configure(-state => 'normal');
        $this->{lbl_msg}->configure(
            -text       => $this->{prior} || "Enter Transaction or Ticket Number",
            -foreground => $this->{prior}? $COLOR_BLUE : $COLOR_RED
        );
        $this->{btn_doit}->configure(-state => 'disabled');
        $this->{chk_alltix}->configure(-state => 'normal');
        return 0;
    }

    # Good to go
    #    $this->{lbl_msg}->configure(-text => qq{ });
    #    $this->Subwidget("B_OK")->configure(-state => 'normal');
    return 1;
}

1;
