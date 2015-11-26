#=============================================================================
#
# Hauntix Point of Sale GUI - Do Full Compensation on a transaction
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

package htx::pop_full_comp;
  require Exporter;
  our @ISA    = qw(Tk::DialogBox);
  use htx;
  use htx::pos_style;
  use htx::transaction;

  my $FW    = 400;
  my $FH    = 300;

#
# Make a new popup
#
sub new {
    my ($class, $parent, $htx) = @_;
    my $this = $parent->DialogBox(
        -title          => "Full Comp",
        -default_button => "OK",
        -buttons        => ["Cancel", "OK"]
    );
    $this->Subwidget("B_Cancel")->configure(-font => $FONT_LG);
    $this->Subwidget("B_OK")->configure(-font => $FONT_LG, -state => 'disabled');
    $this->{wantsize} = [-width => $FW, -height => $FH];
    $this->{htx} = $htx;
    $this->{authby} = q{};
    $this->{reason} = q{};
    $this->{tixnote} = q{};
    bless($this, $class);
    return $this;
}

sub fill {
    my $this = shift;
    my $l = $this->add('Frame')
        ->grid(-row => 0, -column => 0, -sticky => 'nsew');

    # Title
    $l->Label(-font => $FONT_LG, -text => "Full Comp Entire Transaction")
        ->grid(-row => 0, -column => 0, -sticky => 'n', -columnspan => 2);

    # Authorizaton
    $l->Label(-font => $FONT_LG, -text => "Authorized By:")
        ->grid(-row => 1, -column => 0, -sticky => 'nsew');
    my $e_authby = $l->FmtEntry(
        -fcmd            => \&fmt_comment,
        -font            => $FONT_LG,
        -highlightcolor  => 'yellow',
        -textvariable    => \$this->{authby},
        );
    $e_authby->grid(-row => 1, -column => 1, -sticky => 'nsew');
    $e_authby->bind('<FocusIn>' => sub {$this->{akp}->configure(-entry => $e_authby)});
    $e_authby->{_pop} = $this;
    $this->{e_authby} = $e_authby;

    # Reason
    $l->Label(-font => $FONT_LG, -text => "Reason:")
        ->grid(-row => 2, -column => 0, -sticky => 'nsew');
    my $e_comment = $l->FmtEntry(
        -fcmd           => \&fmt_comment,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{reason},
    );
    $e_comment->bind('<FocusIn>'  => sub {$this->{akp}->configure(-entry => $e_comment);});
    $e_comment->grid(-row => 2, -column => 1, -sticky => 'nsew');
    $e_comment->{_pop} = $this;
    $this->{e_comment} = $e_comment;

    # Ticket note
    $l->Label(-font => $FONT_LG, -text => "Ticket Note:")
        ->grid(-row => 3, -column => 0, -sticky => 'nsew');
    my $e_tixnote = $l->FmtEntry(
        -fcmd           => \&fmt_comment,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{tixnote},
    );
    $e_tixnote->bind('<FocusIn>'  => sub {$this->{akp}->configure(-entry => $e_tixnote);});
    $e_tixnote->grid(-row => 3, -column => 1, -sticky => 'nsew');
    $e_tixnote->{_pop} = $this;
    $this->{e_tixnote} = $e_tixnote;

    # Message
    $this->{lbl_msg} = $l->Label(
        -font       => $FONT_BG,
        -foreground => $COLOR_FG,
        -text       => qq{ }
    )->grid(-row => 4, -column => 0, -columnspan => 2, -sticky => 'nsew');


    # Alpha keypad
    $this->{akp} = $this->FullKeypad(-font => $FONT_MD,
                                     -entry => $e_authby,
                                     -state => 'normal')
        ->grid(-row => 1, -column => 0, -columnspan => 2, -sticky => 'nsew');

    return $this;
}

sub fmt_comment {
    my ($old, $i, $w) = @_;

    # Test fields - are we complete?
    $w->afterIdle(sub{$w->{_pop}->test_fields;});

    # No other formatting
    return ($old, $i);
}

sub show {
    my $this = shift;
    $this->{e_authby}->focus;
    return $this->Show();
}

sub test_fields {
    my $this = shift;

    # Authorizer provided?
    if (!$this->{authby}) {
        $this->{lbl_msg}->configure(-text => "Enter Who Authorized This",
                                    -foreground => $COLOR_DKGRN,);
        $this->Subwidget("B_OK")->configure(-state => 'disabled');
        return 0;
    }

    # Reason provided?
    if (!$this->{reason}) {
        $this->{lbl_msg}->configure(-text => "Enter Reason for Comp",
                                    -foreground => $COLOR_DKGRN,);
        $this->Subwidget("B_OK")->configure(-state => 'disabled');
        return 0;
    }

    # Good to go
    $this->{lbl_msg}->configure(-text => qq{ });
    $this->Subwidget("B_OK")->configure(-state => 'normal');
    return 1;
}

1;
