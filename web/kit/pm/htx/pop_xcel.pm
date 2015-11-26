#=============================================================================
#
# Hauntix Point of Sale GUI - Transaction Cancellation Popup
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use FindBin;
use Tk;
use Tk::Dialog;
use htx::frame;

package htx::pop_xcel;
  our @ISA    = qw(Tk::DialogBox);
  use htx;
  use htx::charge;
  use htx::pos_style;
  use htx::transaction;

  my $FW    = 300;
  my $FH    = 300;

#
# Make a new cancellation popup
#
sub new {
    my ($class, $parent, $htx) = @_;
    my $this = $parent->DialogBox(
        -title          => "Cancelling Transaction",
        -default_button => "OK",
        -buttons        => ["OK"]
    );
    $this->Subwidget("B_OK")->configure(-font => $FONT_LG);
    $this->{wantsize} = [-width => $FW, -height => $FH];
    $this->{htx} = $htx;
    $this->{si}  = 0;   # Sale index
    $this->{ci}  = 0;   # Charge index
    $this->{keep} = 0;  # Keep open when done
    bless($this, $class);
    return $this;
}

sub fill {
    my $this = shift;
    my $f = $this->{f} = $this->add('Frame')
        ->grid(-row => 0, -column => 0, -sticky => 'nsew');

    $f->Label(-text=>"Cancel Transaction",
              -font => $FONT_LG)->pack;

    return $this;
}

sub show {
    my $this = shift;
    my $f = $this->{f};
    $this->afterIdle(sub{$this->step_aa});
    return $this->Show();
}

# First step
sub step_aa {
    my $this = shift;
    my $f = $this->{f};
    my $htx = $this->{htx};
    my $trn = $htx->{trn};
    my $tid = $trn->trnid;
    $f->Label(-text=>"Cancelling transaction $tid...", -font=>$FONT_MD)->pack;
    $trn->phase($TRN_PHASE_XCL);
    $this->afterIdle(sub{$this->step_rt});
}

# Go thru sale items, releasing tickets as they're found
sub step_rt {
    my $this = shift;
    my $htx = $this->{htx};
    my $trn = $htx->{trn};
    return $this->afterIdle(sub{$this->step_vc})    # Done here, move to next step
        if $this->{si} > $#{$trn->{charges}};

    my $sale = $trn->{sales}->[$this->{si}++];
    return $this->afterIdle(sub{$this->step_rt})
        if !$sale->{salIsTicket} || !$sale->{show};

    # It's a ticket - release 'em
    my $qty  = $sale->{salQuantity};
    my $nam  = $sale->{salName};
    my $f = $this->{f};
    $f->Label(-text=>"  Releasing $qty $nam ticket(s)...", -font=>$FONT_MD)->pack;
    my $err = htx::ticket::release_tickets($htx, $sale->{salId});
    $f->Label(-text=>$err, -font=>$FONT_XS, -fg=>$COLOR_RED)->pack if $err;
    return $this->afterIdle(sub{$this->step_rt});
}

# Void Charges
sub step_vc {
    my $this = shift;
    my $htx = $this->{htx};
    my $trn = $htx->{trn};
    return $this->afterIdle(sub{$this->step_zz})    # Done here, move to next step
        if $this->{ci} > $#{$trn->{charges}};

    my $crg = $trn->{charges}->[$this->{ci}++];
    return $this->afterIdle(sub{$this->step_vc})
        if $crg->type ne "Charge";  ### TODO:  Use exported constant
    return $this->afterIdle(sub{$this->step_vc})
        if $crg->rcode != 0;

    my $f = $this->{f};
    my $amt = dollar($crg->amount_charged);
    my $typ = $crg->type;
    $f->Label(-text=>"Refunding $amt $typ $crg->{chgMaskedAcctNum}...",
              -font=>$FONT_MD)->pack;
    return $this->afterIdle(sub{$this->step_vd($crg)});
}

# Void done
sub step_vd {
    my $this = shift;
    my $crg = shift;
    my $f   = $this->{f};
    my $htx = $this->{htx};
    my $trn = $htx->{trn};
    my $rfd = htx::charge->new($htx);    # Refund object
    $rfd->trnid($trn->trnid);
    $rfd->type("Refund");
    $rfd->track($crg->track);
    $rfd->acct($crg->acct);
    $rfd->ccv($crg->ccv);
    $rfd->expdate($crg->expdate);
    $rfd->comment("Cancel transaction $trn->{trnId}");
    $rfd->amount_requested($crg->amount_charged);

    my $amt = dol($crg->amount_charged);    # In simple dollar format 1.23
    my $cmd
        = $crg->track
        ? "htx-ccproc refund -t '" . $crg->track . "' $amt"
        : "htx-ccproc refund -a '" . $crg->acct
                    . "' -c '" . $crg->ccv
                    . "' -e '" . $crg->expdate
                    . "' $amt";
    my $out = qx($cmd 2>&1);    # This will pause
### TEST:    print "\nRefund says:\n$out\n";
    $rfd->parse_proc($out);
    my $err = $rfd->save;
    $f->Label(-text=>"Unable to save record of refund: $err",
            -font=>$FONT_SM,
            -fg => $COLOR_RED)->pack
        if $err;
    my $ctid = $rfd->{chgTransactionID};
    my $rcode = $rfd->rcode;
    my $rdesc = $rfd->rdesc;
    if ($rcode eq "000") {
        $f->Label(-text=>"Refund $rdesc \#$ctid",
                -font=>$FONT_MD,
                -fg => $COLOR_DKGRN)->pack;
        return $this->afterIdle(sub{$this->step_vc});
    }
    $this->{keep} = 1;
    $f->Label(-text=>"Refund Failed! $rcode $rdesc",
            -font=>$FONT_MD,
            -fg => $COLOR_RED)->pack;
    return $this->afterIdle(sub{$this->step_vc});
}

# Final steps
sub step_zz {
    my $this = shift;
    my $htx = $this->{htx};
    my $trn = $htx->{trn};
    my $f = $this->{f};
    # Save final state of transaction
    $trn->save;
    if ($trn->error) {
        ### TODO: ???
    }
    $f->Label(-text=>"Done.", -font=>$FONT_MD)->pack;
    $this->after(3000, sub{$this->Exit})
        if !$this->{keep};
}

1;
