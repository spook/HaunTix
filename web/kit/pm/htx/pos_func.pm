#=============================================================================
#
# Hauntix Point of Sale GUI - Function buttons
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use Tk;
use htx::frame;

package htx::pos_func;
  our @ISA    = qw(Exporter htx::frame);
  use htx;
  use htx::pop_badge;
  use htx::pop_error;
  use htx::pop_find_trn;
  use htx::pop_full_comp;
  use htx::pop_void_tix;
  use htx::pop_xcel;
  use htx::pos_rcpt;
  use htx::pos_style;
  use htx::ticket;
  use htx::transaction;
  use POSIX qw/strftime/;

  my $FW   = 660;
  my $FH   = 110;  #was 160

#
# Make a new functions button panel
#
sub new {
    my ($class, $parent_frame, $htx) = @_;
    my $this = $parent_frame->Frame(
        -borderwidth => 3,
        -relief      => 'ridge',
        -background  => $COLOR_DIM,
        -width       => $FW,
        -height      => $FH,
    );
    $this->{wantsize} = [-width => $FW, -height => $FH];
    $this->{htx} = $htx;
    $this->{auto_new_sale_timer} = undef;
    bless($this, $class);
    return $this;
}

#
# Populate this frame
#
sub fill {
    my $this = shift;
    my $htx  = $this->{htx};

# Refund mode ?
# Open cash drawer
# Reload Station
# Lock Station
# Cash Drop
# Cash Payout
# Cashier History (put under reports?)
# Cashier Closeout

### TODO: table driven, fill the funcs in a loop, index a..z for key bindings
### TODO:  use handy mnemonics for function key bindings, like Full Comp is alt-f-c?

    $this->{"btn_full_comp"} = 
    $this->Button(-text    => "Full\nComp",
                  -font    => $FONT_MD,
                  -command => sub {$this->do_full_comp},
                  -state   => 'disabled',
                 )->grid(-row => 0, -column => 0, -sticky => 'nsew');
    $htx->{mw}->bind('<Alt-Key-f><Key-a>' => sub {$this->do_full_comp});

    $this->{"btn_lookup_tix"} = 
    $this->Button(-text    => "Lookup\nTicket",
                  -font => $FONT_MD,
                  -command => sub {$this->do_lookup_tix},
                  -state   => 'disabled',
                 )->grid(-row => 0, -column => 1, -sticky => 'nsew');
    $this->{"btn_show_last_trn"} = 
    $this->Button(-text    => "Show\nLast Sale",
                  -font => $FONT_MD,
                  -command => sub {$this->do_show_last_trn},
                  -state   => 'disabled',
                 )->grid(-row => 0, -column => 2, -sticky => 'nsew');
    $this->{"btn_show_avail_tix"} =
    $this->Button(-text    => "Show Avail\nTickets",
                  -font => $FONT_MD,
                  -command => sub {$this->do_show_avail_tix},
                  -state   => 'disabled',
                 )->grid(-row => 0, -column => 3, -sticky => 'nsew');
    $this->{"btn_cancel_sale"} = 
    $this->Button(-text => "Cancel Sale",
                  -font => $FONT_MD,
                  -command => sub {$this->do_cancel_sale},
                  -state   => 'disabled',
                 )->grid(-row => 0, -column => 4, -sticky => 'nsew');
    $htx->{mw}->bind('<Alt-Key-f><Key-e>' => sub {$this->do_cancel_sale});

#    $this->{"btn_reports"} = 
#    $this->Button(-text    => "Reports",
#                  -font => $FONT_MD,
#                  -command => sub {$this->do_reports},
#                  -state   => 'disabled',
#                 )->grid(-row => 0, -column => 5, -sticky => 'nsew');
    $this->{"btn_badge"} = 
    $this->Button(-text    => "Badge\nUse",
                  -font => $FONT_MD,
                  -command => sub {$this->do_badge},
                  -state   => 'normal',
                 )->grid(-row => 0, -column => 5, -sticky => 'nsew');
    $this->{"btn_lookup_trn"} = 
    $this->Button(-text    => "Lookup\nSale",
                  -font => $FONT_MD,
                  -command => sub {$this->do_lookup_trn},
                  -state   => 'disabled',
                 )->grid(-row => 1, -column => 0, -sticky => 'nsew');
    $this->{"btn_void_tix"} = 
    $this->Button(-text    => "Do\nVoids",
                  -font => $FONT_MD,
                  -command => sub {$this->do_voids},
                  -state   => 'normal',
                 )->grid(-row => 1, -column => 1, -sticky => 'nsew');
#    $this->{"btn_revoke_tix"} = 
#    $this->Button(-text    => "Revoke\nTicket",
#                  -font => $FONT_MD,
#                  -command => sub {$this->do_revoke_tix},
#                  -state   => 'disabled',
#                 )->grid(-row => 1, -column => 1, -sticky => 'nsew');
    $this->{"btn_reprint_last_rct"} =
    $this->Button(-text    => "Reprint\nLast Receipt",
                  -font => $FONT_MD,
                  -command => sub {$this->do_reprint_last_rct},
                  -state   => 'disabled',
                 )->grid(-row => 1, -column => 2, -sticky => 'nsew');
    $this->{"btn_reprint_last_tix"} =
    $this->Button(-text    => "Reprint\nLast Tickets",
                  -font => $FONT_MD,
                  -command => sub {$this->do_reprint_last_tix},
                  -state   => 'disabled',
                 )->grid(-row => 1, -column => 3, -sticky => 'nsew');
    $this->{"btn_new_sale"} = 
    $this->Button(-text => "New Sale",
                  -font => $FONT_MD,
                  -command => sub {$this->do_new_sale},
                  -state   => 'disabled',
                 )->grid(-row => 1, -column => 4, -sticky => 'nsew');
    $this->{"btn_quit"} = 
    $this->Button(-text    => "Quit",
                  -font => $FONT_MD,
                  -command => sub {$this->do_quit},
                 )->grid(-row => 1, -column => 5, -sticky => 'nsew');
    $htx->{mw}->bind('<Alt-Key-f><Key-q>' => sub {$this->do_quit});

    return $this;
}

sub dim_by_phase {
    my $this  = shift;
    my $htx   = $this->{htx};
    my $cfg   = $htx->{cfg};
    my $trn   = $htx->{trn};
    my $bill  = $htx->{bill};
    my $nums  = $htx->{nums};
    my $itms  = $htx->{itms};
    my $pays  = $htx->{pays};
    my $phase = $trn->phase;

    if ($phase eq $TRN_PHASE_NEW) {
        $nums->lit;
        $itms->lit;
        $pays->dim;
        $this->{"btn_cancel_sale"}->configure(-state => 'disabled');
        $this->{"btn_new_sale"}->configure(-state => 'disabled');
        $this->{"btn_full_comp"}->configure(-state => 'disabled');
        $this->{"btn_lookup_trn"}->configure(-state => 'normal');
    }
    elsif ($phase eq $TRN_PHASE_OPN) {
        $pays->lit;
        $this->{"btn_cancel_sale"}->configure(-state => 'normal');
        $this->{"btn_new_sale"}->configure(-state => 'disabled');
        $this->{"btn_full_comp"}->configure(-state => 'normal')
            if $cfg->{pos}->{full_comp_allowed};
        $this->{"btn_lookup_trn"}->configure(-state => 'disabled');
    }
    elsif ($phase eq $TRN_PHASE_PAY) {
        $this->{"btn_cancel_sale"}->configure(-state => 'normal');
        $this->{"btn_new_sale"}->configure(-state => 'disabled');
        $this->{"btn_full_comp"}->configure(-state => 'disabled');
        $this->{"btn_lookup_trn"}->configure(-state => 'disabled');
    }
    elsif ($phase eq $TRN_PHASE_XCL) {
        $nums->dim;
        $itms->dim;
        $pays->dim;
        $this->{"btn_cancel_sale"}->configure(-state => 'disabled');
        $this->{"btn_new_sale"}->configure(-state => 'normal');
        $this->{"btn_full_comp"}->configure(-state => 'disabled');
        # Start timer for auto new-sale  ### TODO:  Should only be done on *change* to this phase
        if ($cfg->{pos}->{auto_new_sale_enabled}) {
            my $delay = $cfg->{pos}->{auto_new_sale_delay} || 5000;
            $this->{auto_new_sale_timer} = $this->after($delay,
                                                  sub{$this->do_new_sale});
        }
    }
    elsif ($phase eq $TRN_PHASE_FIN) {
        $nums->dim;
        $itms->dim;
        $pays->dim;
        $this->{"btn_cancel_sale"}->configure(-state => 'disabled');
        $this->{"btn_new_sale"}->configure(-state => 'normal');
        $this->{"btn_full_comp"}->configure(-state => 'disabled');
        # Start timer for auto new-sale  ### TODO:  Should only be done on *change* to this phase
        if ($cfg->{pos}->{auto_new_sale_enabled}) {
            my $delay = $cfg->{pos}->{auto_new_sale_delay} || 5000;
            $this->{auto_new_sale_timer} = $this->after($delay,
                                                  sub{$this->do_new_sale});
        }
    }

#    $this->{"btn_show_last_trn"}->configure(-state => $htx->{last_trn}? 'normal' : 'disabled');
    $this->{"btn_reprint_last_rct"}->configure(-state => 
        $cfg->{pos}->{receipt_print_enabled} && $htx->{last_trn}? 'normal' : 'disabled');
    $this->{"btn_reprint_last_tix"}->configure(-state => 
        $cfg->{pos}->{ticket_print_enabled}  
        && $htx->{last_trn}
        && $htx->{last_trn}->tickets? 'normal' : 'disabled');
}

sub do_badge {
    my $this = shift;
    my $htx = $this->{htx};
    my $mw = $htx->{mw};

    htx::pop_badge->new($mw, $htx)->fill()->show();
}

sub do_cancel_sale {
    my $this = shift;
    my $htx = $this->{htx};
    my $mw = $htx->{mw};

    my $popup = htx::pop_xcel->new($mw, $htx)->fill();
    my $btn = $popup->show;
    $this->do_new_sale;
}

sub do_full_comp {
    my $this = shift;
    my $htx = $this->{htx};
    my $mw = $htx->{mw};
    my $trn = $htx->{trn};
    my $nums = $htx->{nums};
    my $bill = $htx->{bill};
    my $pays = $htx->{pays};

    my $popup = htx::pop_full_comp->new($mw, $htx)->fill();
    my $btn = $popup->show;
    return if $btn ne "OK";
    my $authby  = $popup->{e_authby}->get();
    my $reason  = $popup->{e_comment}->get();
    my $tixnote = $popup->{e_tixnote}->get();

    # add a 100% discount item to the transaction
    my $item = {
                itmName           => "100% Discount",
                itmMethod         => "Percent",     # FixedAmount, Percent, ...
                itmCost           => -10000,        # hundredths of percent off
                itmType           => "dsc",
               };
    if (my $err = $trn->add_item($item, 1)) {
        htx::pop_error::show($htx, $err);
        $nums->set_amt(0);
        return 0;
    }
    $trn->{trnNote} = "Full Comp User:$ENV{USER} Authby:$authby Reason:$reason";
    $trn->fullcomp(1);
    $trn->retally;
    if ($tixnote) {
        foreach my $tix ($trn->tickets()) {
            $tix->{tixNote} = $tixnote;
            $tix->save;
        }
    }
    $trn->phase_check;
    $this->dim_by_phase;
    $nums->set_tot($trn->total() / 100.0);
    $bill->selected(0); # clear selection if any
    $bill->update();
    $pays->lit();

    $this->do_new_sale if $trn->owed() <= 0;
}

sub do_lookup_trn {
    my $this = shift;
    my $htx = $this->{htx};
    my $mw = $htx->{mw};
    my $trn = $htx->{trn};
    my $nums = $htx->{nums};
    my $bill = $htx->{bill};
    my $pays = $htx->{pays};

    my $popup = htx::pop_find_trn->new($mw, $htx)->fill();
    my $btn = $popup->show;
}

sub do_new_sale {
    my $this = shift;
    my $htx = $this->{htx};
    my $trn = $htx->{trn};
    my $nums = $htx->{nums};
    my $bill = $htx->{bill};
    my $info = $htx->{info};
    my $phase = $trn->phase;

    # Timer still active?  Cancel it...
    $this->afterCancel($this->{auto_new_sale_timer})
        if $this->{auto_new_sale_timer};
    $this->{auto_new_sale_timer} = undef;

    # If the transaction is not complete, we must cancel it first
    if ($phase ne $TRN_PHASE_FIN
     && $phase ne $TRN_PHASE_XCL
     && $phase ne $TRN_PHASE_NEW) {
        $this->do_cancel_sale;
    }

    # Save the old transaction (if final), start a new one
    $htx->{last_trn} = $trn
        if $trn->{trnPhase} eq $htx::transaction::TRN_PHASE_FIN;

    $htx->{trn} = htx::transaction->new(-htx => $htx);
    if ($htx->{trn}->error) {
        die "*** Transaction new() error: " . $htx->{trn}->error . "\n";
    }
    if (!$htx->{trn}->{trnId}) {
        die "*** Zero transaction ID\n";
    }

    # Refresh a few things
    $nums->set_amt(0);
    $bill->update();
    $info->update();
### TODO: Should this be on the new transaction?  or are these just unnecessary
    $trn->retally;  # put this and the next three into a transaction::refresh() function
    $trn->phase_check;
    $this->dim_by_phase;
}

sub do_quit {
    my $this = shift;
    my $htx = $this->{htx};
    my $trn = $htx->{trn};
    my $phase = $trn->phase;

    # If in the middle of a transaction, verify the quit
    if ($phase ne $TRN_PHASE_FIN
     && $phase ne $TRN_PHASE_XCL
     && $phase ne $TRN_PHASE_NEW) {
        # TODO: popup - "you have an active transaction...
        #   Can't exit now...
        #   [Cancel Transaction]     [Nevermind]
        # return 0 if $pressed eq "Nevermind";

        ### TODO: run cancellation processing
    }

    exit;
}

# Re-print the receipt from the last completed transaction
sub do_reprint_last_rct {
    my $this = shift;
    my $htx = $this->{htx};

    return htx::pop_error::show($htx, "No prior transaction to reprint")
        if !$htx->{last_trn};

    my $rct = new htx::pos_rcpt($htx, $htx->{last_trn});
    $rct->print_receipt;
}

# Re-print the tickets from the last complete transaction, if any
sub do_reprint_last_tix {
    my $this = shift;
    my $htx = $this->{htx};

    return htx::pop_error::show($htx, "No prior transaction to re-issue")
        if !$htx->{last_trn};
    return htx::pop_error::show($htx, "No tickets in last transaction")
        if !$htx->{last_trn}->tickets;

    # Print the ticket(s)
    foreach my $tic ($htx->{last_trn}->tickets) {
        $tic->print_ticket;
    }
}

sub do_voids {
    my $this = shift;
    my $htx = $this->{htx};
    my $mw = $htx->{mw};

    htx::pop_void_tix->new($mw, $htx)->fill()->show();
}

1;
