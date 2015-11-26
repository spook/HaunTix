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
  my $FH    = 420;

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
    $this->{htx}      = $htx;
    $this->{dcode}    = q{};
    $this->{org}      = q{};
    $this->{who}      = q{};
    $this->{reason}   = q{};
    $this->{authby}   = q{};
    $this->{tixnote}  = q{};
    bless($this, $class);
    return $this;
}

sub fill {
    my $this = shift;
    my $l = $this->add('Frame')
        ->grid(-row => 0, -column => 0, -sticky => 'nsew');

    # Title
    $l->Label(-font => $FONT_XL, -text => "Full Comp Entire Transaction", -foreground => $COLOR_DKGRN)
        ->grid(-row => 0, -column => 0, -sticky => 'n', -columnspan => 3);
    $l->Label(-font => $FONT_BG, -text => "Information *MUST* be traceable in IRS Audits!", -foreground => $COLOR_RED)
        ->grid(-row => 1, -column => 0, -sticky => 'n', -columnspan => 3);

    # Discount Code
    my $d = $l->Frame()
        ->grid(-row => 1, -column => 0, -rowspan => 4, -sticky => 'nsew');
    my $r = 0;
    $d->Label(-font => $FONT_LG, -text => "Tax Code:")
        ->grid(-row=>$r++, -column=>0, -sticky=>'nw');
    foreach my $txt (("Charity", "Marketing 1:1", "Service 1:1", "Staff Comp", "Cust Sat")) {
        my @words = split(/\s+/, $txt);
        my $val = $words[0];
        $d->Radiobutton(-variable=>\$this->{dcode},-value=>$val,-font => $FONT_BG,-text => $txt)
            ->grid(-row=>$r++, -column=>0, -sticky => 'w');
    }

    # Organization
    $l->Label(-font => $FONT_LG, -text => "Company / TIN#")
        ->grid(-row => 1, -column => 1, -sticky => 'e');
    my $e_org = $l->FmtEntry(
        -fcmd           => \&fmt_comment,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{org},
    );
    $e_org->bind('<FocusIn>'  => sub {$this->{akp}->configure(-entry => $e_org);});
    $e_org->grid(-row => 1, -column => 2, -sticky => 'nsew');
    $e_org->{_pop} = $this;
    $this->{e_org} = $e_org;

    # Who
    $l->Label(-font => $FONT_LG, -text => "Who Gets?")
        ->grid(-row => 2, -column => 1, -sticky => 'e');
    my $e_who = $l->FmtEntry(
        -fcmd           => \&fmt_comment,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{who},
    );
    $e_who->bind('<FocusIn>'  => sub {$this->{akp}->configure(-entry => $e_who);});
    $e_who->grid(-row => 2, -column => 2, -sticky => 'nsew');
    $e_who->{_pop} = $this;
    $this->{e_who} = $e_who;

    # Reason
    $l->Label(-font => $FONT_LG, -text => "Reason:")
        ->grid(-row => 3, -column => 1, -sticky => 'e');
    my $e_comment = $l->FmtEntry(
        -fcmd           => \&fmt_comment,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{reason},
    );
    $e_comment->bind('<FocusIn>'  => sub {$this->{akp}->configure(-entry => $e_comment);});
    $e_comment->grid(-row => 3, -column => 2, -sticky => 'nsew');
    $e_comment->{_pop} = $this;
    $this->{e_comment} = $e_comment;

    # Authorization
    $l->Label(-font => $FONT_LG, -text => "Authorized By:")
        ->grid(-row => 4, -column => 1, -sticky => 'e');
    my $e_authby = $l->FmtEntry(
        -fcmd            => \&fmt_comment,
        -font            => $FONT_LG,
        -highlightcolor  => 'yellow',
        -textvariable    => \$this->{authby},
        );
    $e_authby->grid(-row => 4, -column => 2, -sticky => 'nsew');
    $e_authby->bind('<FocusIn>' => sub {$this->{akp}->configure(-entry => $e_authby)});
    $e_authby->{_pop} = $this;
    $this->{e_authby} = $e_authby;

    # Ticket note
    $l->Label(-font => $FONT_LG, -text => "Note on Ticket:")
        ->grid(-row => 5, -column => 0, -sticky => 'nsew');
    my $e_tixnote = $l->FmtEntry(
        -fcmd           => \&fmt_comment,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{tixnote},
    );
    $e_tixnote->bind('<FocusIn>'  => sub {$this->{akp}->configure(-entry => $e_tixnote);});
    $e_tixnote->grid(-row => 5, -column => 1, -columnspan => 2, -sticky => 'nsew');
    $e_tixnote->{_pop} = $this;
    $this->{e_tixnote} = $e_tixnote;

    # Message
    $this->{lbl_msg} = $l->Label(
        -font       => $FONT_BG,
        -foreground => $COLOR_FG,
        -text       => qq{ }
    )->grid(-row => 6, -column => 0, -columnspan => 3, -sticky => 'nsew');


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
    $this->{e_org}->focus;
    return $this->Show();
}

sub test_fields {
    my $this = shift;

    if (!$this->{dcode}) {
        $this->{lbl_msg}->configure(-text => "Must select tax code",
                                    -foreground => $COLOR_RED,);
        $this->Subwidget("B_OK")->configure(-state => 'disabled');
        return 0;
    }
    if (!$this->{org}) {
        $this->{lbl_msg}->configure(-text => "Enter Company or Tax ID#",
                                    -foreground => $COLOR_RED,);
        $this->Subwidget("B_OK")->configure(-state => 'disabled');
        return 0;
    }
    if (!$this->{who}) {
        $this->{lbl_msg}->configure(-text => "Enter Name of Who Gets These Tickets or Merchandise",
                                    -foreground => $COLOR_RED,);
        $this->Subwidget("B_OK")->configure(-state => 'disabled');
        return 0;
    }
    if (!$this->{reason}) {
        $this->{lbl_msg}->configure(-text => "Enter Reason for Comp",
                                    -foreground => $COLOR_RED,);
        $this->Subwidget("B_OK")->configure(-state => 'disabled');
        return 0;
    }
    if (!$this->{authby}) {
        $this->{lbl_msg}->configure(-text => "Enter Name of Authorizer",
                                    -foreground => $COLOR_RED,);
        $this->Subwidget("B_OK")->configure(-state => 'disabled');
        return 0;
    }

    # Good to go
    $this->{lbl_msg}->configure(-text => qq{ });
    $this->Subwidget("B_OK")->configure(-state => 'normal');
    return 1;
}

1;
