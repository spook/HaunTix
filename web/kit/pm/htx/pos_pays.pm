#=============================================================================
#
# Hauntix Point of Sale GUI - Payments Panel
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use FindBin;
use Tk;
use Tk::Dialog;
use Tk::DoCommand;
use Tk::ProgressBar;
use htx::frame;

package htx::pos_pays;
  require Exporter;
  our @ISA    = qw(Exporter htx::frame);
  our @EXPORT = qw();
  use htx;
  use htx::cc;
  use htx::charge;
  use htx::pop_cc;
  use htx::pop_check;
  use htx::pos_style;
  use htx::transaction;

  my $FW = 365;
  my $FH = 160;

#
# Make a new payments  panel
#
sub new {
    my ($class, $parent_frame, $htx) = @_;
    my $this = $parent_frame->Frame(
        -borderwidth => 3,
        -relief      => 'ridge',
        -width       => $FW,
        -height      => $FH,
    );
    $this->{wantsize} = [-width => $FW, -height => $FH];
    $this->{htx} = $htx;
    bless($this, $class);
    return $this;
}

#
# Populate this frame
#
sub fill {
    my $this = shift;
    my $htx = $this->{htx};

    $this->Label(
        -text => "Enter amount tended and press payment type.\n"
            . "For exact amount, just press payment type.",
##-wraplength => 190,
        -font => $FONT_SM
    )->grid(-row => 0, -column => 0, -columnspan => 3, -sticky => 'nsew');
    $this->{"btn_cash"} = $this->Button(
        -text    => 'Cash',
        -font    => $FONT_BG,
        -command => sub {$this->process_cash();}
    )->grid(-row => 1, -column => 0, -sticky => 'nsew');
    $htx->{mw}->bind('<Alt-Key-c><Key-a>' => sub {$this->process_cash});

    $this->{"btn_check"} = $this->Button(
        -text    => 'Check',
        -font    => $FONT_BG,
        -command => sub {$this->process_check();}
    )->grid(-row => 1, -column => 1, -sticky => 'nsew');
    $htx->{mw}->bind('<Alt-Key-c><Key-h>' => sub {$this->process_check});
    $this->{"btn_cash"} = $this->Button(
        -text    => 'CC',
        -font    => $FONT_BG,
        -command => sub {$this->process_cc();}
    )->grid(-row => 1, -column => 2, -sticky => 'nsew');
    $htx->{mw}->bind('<Alt-Key-c><Key-c>' => sub {$this->process_cc});
    $this->Button(
        -text    => '$20',
        -font    => $FONT_BG,
        -command => sub {$this->process_cash(2000);}
    )->grid(-row => 2, -column => 0, -sticky => 'nsew');
    $htx->{mw}->bind('<Alt-Key-c><Key-2>' => sub {$this->process_cash(2000)});
    $this->Button(
        -text    => '$50',
        -font    => $FONT_BG,
        -command => sub {$this->process_cash(5000);}
    )->grid(-row => 2, -column => 1, -sticky => 'nsew');
    $htx->{mw}->bind('<Alt-Key-c><Key-5>' => sub {$this->process_cash(5000)});
    $this->Button(
        -text    => '$100',
        -font    => $FONT_BG,
        -command => sub {$this->process_cash(10000);}
    )->grid(-row => 2, -column => 2, -sticky => 'nsew');
    $htx->{mw}->bind('<Alt-Key-c><Key-1>' => sub {$this->process_cash(10000)});

    # Bind just Alt-Key-C so it doesn't trigger a non-modified <Key-C> handler
    $htx->{mw}->bind('<Alt-Key-c>' => sub {});

    return $this;
}

#
# Accept cash - sale is completed when balance goes to zero (or change must be given)
#
sub process_cash {
    my ($this, $amt) = @_;    # Amount is an int, unit:cents
    my $htx  = $this->{htx};
    my $trn  = $htx->{trn};
    my $bill = $htx->{bill};
    my $nums = $htx->{nums};
    my $func = $htx->{func};

    # Get & verify amount - order: amt given, amt in numbar, total, -change
    $amt ||= cent($nums->get_amt)
            || cent($nums->get_tot)
            || ($nums->get_chg() < 0 ? cent(-$nums->get_chg): 0);
    return $nums->set_msg("Bad Amount: $amt", 3000)
        if $amt !~ m/^\d+$/;

    # Update with cash given
    $trn->cash($amt);
    $func->dim_by_phase;
    $bill->update();
    $nums->set_chg($trn->change() / 100.0);
}

#
# Process Credit Cards
#
sub process_cc {
    my ($this, $amt) = @_;    # Amount is an int, unit:cents
    my $htx  = $this->{htx};
    my $trn  = $htx->{trn};
    my $bill = $htx->{bill};
    my $nums = $htx->{nums};
    my $mw   = $htx->{mw};

    # Amount to show - order: amt given, amt in numbar, total, -change
    $amt 
        ||= cent($nums->get_amt)
        || ($nums->get_chg() < 0 ? cent(-$nums->get_chg) : 0)
        || cent($nums->get_tot());
    return $nums->set_msg("Bad Amount: $amt", 5000)
        if $amt !~ m/^\d+$/;

    # Max amount allowed
    my $maxamt = $trn->owed > 0 ? $trn->owed : 0;

    # Create and show popup
    my $popup = htx::pop_cc->new($mw, $htx)->fill();
    $popup->set_max($maxamt);
    my $pressed = $popup->show($amt, q{});

    # Process charge
    if ($pressed eq "Full Amount") {
        $popup->set_amt($maxamt);
    }
    if (   $pressed eq "OK"
        || $pressed eq "Full Amount")
    {

        # Popup window to show progress
        my $ccproc = $mw->Toplevel;
        $ccproc->title("Processing Credit Card");
        $ccproc->geometry("700x275+300+200");
        $ccproc->deiconify;
        $ccproc->raise;
        $ccproc->{_canned}  = 0;
        $ccproc->{_chg} = new htx::charge(htx => $htx);
        $ccproc->{_chg}->comment($popup->get_info);
        $ccproc->{_chg}->amount_requested($popup->get_amt);
        $ccproc->{_chg}->dup_mode($popup->get_dup);
        $ccproc->{_chg}->track($popup->get_track);
        $ccproc->{_chg}->acct($popup->get_acct);
        $ccproc->{_chg}->ccv($popup->get_ccv);
        $ccproc->{_chg}->expdate($popup->get_expdate);
        $ccproc->{_stat} = $ccproc->Label(
            -text => "Processing "
                . dollars($popup->get_amt)
                . " charge...",
            -font => $FONT_BG
        )->pack;

        # Progress bar
        $ccproc->{_prog} = $ccproc->ProgressBar(
            -gap    => 0,
            -length => 600,
            -colors => [0, 'green', 50, 'yellow', 80, 'red']
        )->pack;
        $ccproc->{_prog}->value(0);

        # Process the card
        $ccproc->Label(
            -text => "Result details: ",
            -font => $FONT_MD
        )->pack;
        my $dup = $popup->get_dup? q{} : "-d ";
        my $amt = dol($popup->get_amt);
        my $cmd
            = $popup->get_track
            ? "htx-ccproc charge $dup -t '" . $popup->get_track . "' $amt"
            : "htx-ccproc charge $dup -a '"
            . $popup->get_acct
            . "' -c '"
            . $popup->get_ccv
            . "' -e '"
            . $popup->get_expdate
            . "' $amt";
        $ccproc->{_dc} = $ccproc->DoCommand(
            -height  => 5,
            -width   => 74,
            -command => $cmd
        )->pack;

        $ccproc->{_b_cancel} = $ccproc->Button(
            -text    => 'Cancel',
            -font    => $FONT_LG,
            -command => sub {
                $ccproc->{_canned} = 1;
                $ccproc->{_dc}->kill_command;
            }
        )->pack(-side => 'left', -padx => 50);
        $ccproc->{_b_ok} = $ccproc->Button(
            -state   => 'disabled',
            -text    => 'OK',
            -font    => $FONT_LG,
            -command => sub {
                $ccproc->withdraw;
             ##   $ccproc->destroy;
            }
        )->pack(-side => 'right', -padx => 50);
        $ccproc->{_b_retry} = $ccproc->Button(
            -state   => 'disabled',
            -text    => 'Try Again',
            -font    => $FONT_LG,
            -command => sub {$ccproc->{_prog}->value(0);
                             $ccproc->{_dc}->start_command;
                             $this->after(210, sub {$this->_watch_ccproc($ccproc)});
                            }
        )->pack(-side => 'right', -padx => 50);

        # Go...
        $ccproc->{_dc}->start_command;
        $this->after(210, sub {$this->_watch_ccproc($ccproc)});

    }
    else {
        $nums->set_msg("CC Cancelled", 1000);
        return 0;
    }

}

sub _watch_ccproc {
    my ($this, $ccproc) = @_;
    my $htx  = $this->{htx};
    my $cfg  = $htx->{cfg};
    my $trn  = $htx->{trn};
    my $bill = $htx->{bill};
    my $nums = $htx->{nums};
    my $func = $htx->{func};
    my $chg = $ccproc->{_chg};

    # Update progress bar
    my $pb  = $ccproc->{_prog};
    my $val = $pb->value;
    $val++;
    $val = 100 if $val > 100;
    $pb->value($val);

    # Done?
    my $dc = $ccproc->{_dc};
    if (!$dc->is_done) {
        # queue-up for later
        $this->after(210, sub {$this->_watch_ccproc($ccproc)});
        return;
    }
    $ccproc->{_b_ok}->configure(-state => 'normal');
    $ccproc->{_b_retry}->configure(-state => 'disabled');
    $ccproc->{_b_cancel}->configure(-state => 'disabled');

    # Success or failure? Parse the output
    $chg->parse_proc($dc->get_output);
    my $code = $chg->rcode;
    my $desc = $chg->rdesc;
    if ($code eq "000") {       ### TODO: URGENT *** is it 0 or "000" - get consistent!
                                ### from parse, it's "000", but in d/b it's an int,
                                ### so it gets stored as an int 0.

        # Approved
        $pb->value(0);  # Set progress bar back down
        my $apvc = $chg->acode;
        my $aamt = dollars($chg->amount_charged);
        $ccproc->{_stat}->configure(    # show response and approval code
            -text => "$aamt $desc \#$apvc",
            -fg   => $COLOR_DKGRN,
            -bg   => $COLOR_LTGRN
        );

        # Save to the database
        $chg->trnid($trn->trnid);
        $chg->save;
    ### TODO:  what to do on $chg->error ? ********
        print STDERR $chg->error . "\n"
            if $chg->error;

        # Update the transaction
        $trn->cc($chg);

        # Show the new bill and change amounts
        $func->dim_by_phase;
        $bill->update();
        $nums->set_chg($trn->change() / 100.0);

        # Auto-close timer
        $this->after(5000, sub {$ccproc->withdraw;
                              ###  $ccproc->destroy;
                               });

        # Sound
        system("aplay -q $cfg->{sound}->{cc_approve} &")
            if $cfg->{sound}->{enabled} 
            && -r $cfg->{sound}->{cc_approve};
    }
    elsif ($code =~ m/^\d+$/) {

        # Denied - Save to the database
        $chg->trnid($trn->trnid);
        $chg->save;
    ### TODO:  what to do on $chg->error ? ********
        print STDERR $chg->error . "\n"
            if $chg->error;
        
        # Update display state
        $ccproc->{_stat}->configure(
            -text => "$desc\nCode $code",
            -fg   => $COLOR_RED,
            -bg   => $COLOR_LTRED
        );
        $ccproc->{_b_retry}->configure(-state => 'normal');

        # Sound
        system("aplay -q $cfg->{sound}->{cc_deny} &")
            if $cfg->{sound}->{enabled} 
            && -r $cfg->{sound}->{cc_deny};
    }
    else {
        # Unknown response - Save charge to the database
        $chg->trnid($trn->trnid);
        $chg->save;
    ### TODO:  what to do on $chg->error ? ********
        print STDERR $chg->error . "\n"
            if $chg->error;
        
        # Configure popup color etc
        if ($ccproc->{_canned}) {
            $ccproc->{_stat}->configure(
                -text =>
                    "CANCELLED\nNote: The transaction may have gone thru.",
                -fg => $COLOR_BG,
                -bg => $COLOR_LIT
            );

        # Sound
        system("aplay -q $cfg->{sound}->{cc_cancel} &")
            if $cfg->{sound}->{enabled} 
            && -r $cfg->{sound}->{cc_cancel};
        }
        elsif ($dc->get_output() =~ m{no response}i) {

            # Net down
            $ccproc->{_stat}->configure(
                -text => "Ugh! Is the net down?",
                -fg   => $COLOR_VIO,
                -bg   => $COLOR_GOLD
            );
            $ccproc->{_b_retry}->configure(-state => 'normal');

            # Sound
            system("aplay -q $cfg->{sound}->{net_down} &")
                if $cfg->{sound}->{enabled} 
                && -r $cfg->{sound}->{net_down};
        }
        else {

            # Internal error
            $ccproc->{_stat}->configure(
                -text => "Yikes! We had an internal error",
                -fg   => $COLOR_VIO,
                -bg   => $COLOR_GOLD
            );
            $ccproc->{_b_retry}->configure(-state => 'normal');

            # Sound
            system("aplay -q $cfg->{sound}->{cc_error} &")
                if $cfg->{sound}->{enabled} 
                && -r $cfg->{sound}->{cc_error};
        }
    }
}

#
# Accept a check - sale is completed when balance goes to zero (or change must be given)
#
sub process_check {
    my ($this, $amt) = @_;    # Amount is an int, unit:cents
    my $htx  = $this->{htx};
    my $trn  = $htx->{trn};
    my $bill = $htx->{bill};
    my $nums = $htx->{nums};
    my $func = $htx->{func};
    my $mw   = $htx->{mw};

    # Amount to show - order: amt given, amt in numbar, total, -change
    $amt 
        ||= cent($nums->get_amt)
        || ($nums->get_chg() < 0 ? cent(-$nums->get_chg) : 0)
        || cent($nums->get_tot);
    return $nums->set_msg("Bad Amount: $amt", 5000)
        if $amt !~ m/^\d+$/;

    # Max amount allowed
    my $maxamt = $trn->owed > 0 ? $trn->owed : 0;
    $amt = $maxamt if $amt > $maxamt;

    # Create and show popup
    my $popup = htx::pop_check->new($mw, $htx)->fill();
    $popup->set_max($maxamt);
    my $pressed = $popup->show($amt, q{});
    if ($pressed eq "Full Amount") {
        $trn->check($maxamt);
        $trn->checkinfo($popup->get_info());
        $func->dim_by_phase;
    }
    elsif ($pressed eq "OK") {
        $trn->check($popup->get_amt());
        $trn->checkinfo($popup->get_info());
        $func->dim_by_phase;
    }
    else {
        $nums->set_msg("Check Cancelled", 1000);
        return 0;
    }

    # Show the new bill and change amounts
    $bill->update();
    $nums->set_chg($trn->change() / 100.0);
}

1;
