#=============================================================================
#
# Hauntix Point of Sale GUI - Receipt printing class
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

package htx::pos_rcpt;
  use Date::Manip;
  use htx;
  use htx::transaction;
  use POSIX qw(strftime);


#
# Make a new receipt object
#
sub new {
    my ($class, $htx, $trn) = @_;
    my $this = {htx       => $htx,
                trn       => $trn,
                err       => q{},
                pickuptix => 0,
               };

    # Load the appropriate driver
    my $cfg = $htx->{cfg};
    my $drvnam = $cfg->{pos}->{receipt_print_driver} || "drv_epson_tm88";
    my $drvpth = "htx/$drvnam.pm";
    require $drvpth;
    my $drvmod = "htx::$drvnam";
    $this->{drv} = $drvmod->new;

    # Set the queue
    my $queue = $cfg->{pos}->{receipt_print_queue};
    $this->{drv}->queue($queue);

    # Finish the class
    bless($this, $class);
    return $this;
}

#
# Print the receipt.  Here are the parts:
#       Header:
#           (printed receipt only) Logo image
#           Transaction number
#           Station (terminal) ID
#           Cashier info
#       Items:
#           Products
#           Upgrades
#           Discounts
#           Apply-to-all comps
#       Totals:
#           Divider
#           Subtotal
#           Taxes
#           Divider
#           Total
#       Payments/Change:
#           Divider
#           Paid Cash
#           Paid Check(s)...
#           Paid CC(s)...
#           Change Given/Still Owed...
#       Footer:
#           (printed receipt only) Barcode of transaction #
#           Transaction number again
#           Date & time
#           Product Counts
#
sub print_receipt {
    my $this = shift;
    my $htx = $this->{htx};
    my $cfg = $htx->{cfg};

    # Printing enabled?
    my $enabled = $cfg->{pos}->{receipt_print_enabled};
    return if !$enabled;

    $this->print_header();
    $this->print_sales();
    $this->print_totals();
    $this->print_payments();
    $this->print_footer();

    my $drv  = $this->{drv};
    $drv->submit;
    return $this;
}

sub print_header {
    my $this = shift;
    my $drv  = $this->{drv};
    my $htx  = $this->{htx};
    my $trn  = $this->{trn};    # Not from $htx but from $this
    my $cfg  = $htx->{cfg};

    my $intro   = $cfg->{haunt}->{intro}   || q{};
    my $name    = $cfg->{haunt}->{name}    || 'Haunted House';
    my $slogan  = $cfg->{haunt}->{slogan}  || q{};
    my $site    = $cfg->{haunt}->{site}    || q{};
    my $addr1   = $cfg->{haunt}->{addr1}   || q{};
    my $addr2   = $cfg->{haunt}->{addr2}   || q{};
    my $website = $cfg->{haunt}->{website} || q{};
    my $phone   = $cfg->{haunt}->{phone}   || q{};

    # Reset the printer
    $drv->reset;

    # Event & Haunt Info
    # TODO: Include logo
    $drv->say(_nl($intro),   'tiny,center') if $intro;
    $drv->say(_nl($name),    'tall,wide,center');
    $drv->say(_nl($slogan),  'wide,tiny,bold,center') if $slogan;
    $drv->say(_nl($site),    'center') if $site;
    $drv->say(_nl($addr1),   'center') if $addr1;
    $drv->say(_nl($addr2),   'center') if $addr2;
    $drv->say(_nl($website), 'center') if $website;
    $drv->say(_nl($phone),   'center') if $phone;
    $drv->say;

    # Transaction, date, cashier, mgr, station, revtot
    my $trnid = sprintf("%12.12d",$trn->{trnId});
    my $date = strftime("%a %d-%b-%Y %H:%M:%S %Z", localtime(time()));  # TODO: Use transaction date
    my $user = $ENV{USER};
    my $mod  = q{Cathy};    ### TODO:  MOD or override supervisor if ovr
    my $station = $cfg->{pos}->{station_id};
    my $revtot = reverse $trn->total;
    my $test_mode   = $cfg->{system}->{testmode}? q{T} : q{ };
    $drv->say("$trnid$test_mode $date");
    $drv->say("Cashier $user  MOD $mod  STN $station RT $revtot");
    $drv->say;

    # Transaction header
    $drv->say("Transaction #$trn->{trnId}", 'under,center');
}

sub print_sales {
    my $this = shift;
    my $htx  = $this->{htx};
    my $trn  = $this->{trn};    # Not from $htx but from $this

    # Show ticket products first
    $this->{pickuptix} = 0;
    foreach my $sale ($trn->sales()) {
        next unless $sale->{salType} eq 'prd';
        next unless $sale->{salIsTicket};
        $this->{pickuptix}++ if !$sale->{show};
        $this->print_sale_line($sale);
    }

    # Show non-ticket products
    foreach my $sale ($trn->sales()) {
        next unless $sale->{salType} eq 'prd';
        next if $sale->{salIsTicket};
        $this->print_sale_line($sale);
    }

    # Then show upgrades
    foreach my $sale ($trn->sales()) {
        next unless $sale->{salType} eq 'upg';
        $this->print_sale_line($sale);
    }

    # Lastly, show discounts
    foreach my $sale ($trn->sales()) {
        next unless $sale->{salType} eq 'dsc';
        $this->print_sale_line($sale);
    }

    ### TODO: apply-to-all comps
}

sub print_sale_line {
    my ($this, $sale) = @_;
    my $drv = $this->{drv};
    my $htx = $this->{htx};

    # TODO if $qty > 999 || length($tot) > 8 || override
    #   ... use TWO-LINE format
    # One-line format
    my $qty   = $sale->{salQuantity};
    my $nam   = substr($sale->{salName}, 0, 18);
    my $per   = dollar($sale->{salPaid});
    my $tot   = dollar($sale->{salPaid} * $sale->{salQuantity});
    my $istax = $sale->{salIsTaxable} ? q{ T} : q{  };

    if ($sale->{show}) {
        my $show = $sale->{show}; 
        my $nite = substr($show->{shoTime}, 5, 5); # MM-DD
        $nam .= ": $nite";
    }

    $drv->say(sprintf('%3d %-18s %7s %9s%2s', $qty, $nam, $per, $tot, $istax),
              'right');

    # Price override line
    if (($sale->{salType} ne 'dsc') ### TODO: constant
     && ($sale->{salCost} != $sale->{salPaid})) {
        my $ovr = "       Price Override: Was " . dollar($sale->{salCost}) . " each";
        $drv->say($ovr,'tiny,bold')
    }

    # Showtime line if needed
    if (($sale->{salType} ne 'dsc') ### TODO: constant
     && $sale->{salIsTimed}) {      ### TODO: merge this logic with daily tickets
        my $show_info = "       FlexTix: Choose Showtime Later";
        if ($sale->{show}) {
            my $time = UnixDate($sale->{show}->{shoTime}, q{%I:%M%p %a %d %b %Y});
            $time =~ s/^0//;
            $show_info = "       Showtime: $time";
        }
        $drv->say($show_info,'tiny')
    }
}

sub print_totals {
    my $this = shift;
    my $drv  = $this->{drv};
    my $htx  = $this->{htx};
    my $trn  = $this->{trn};    # Not from $htx but from $this

    # Divider line
    $drv->say((qq{-}x19).q{  }, 'right');

    # Subtotal
    $drv->say(sprintf('Subtotal %10s  ', dollar($trn->subtotal())), 'right');

    # Tax
    $drv->say(sprintf('%4.2f%% Tax %10s T',
                      $trn->taxrate(), 
                      dollar($trn->tax())),
              'right');

    # Total
    $drv->put("Total ", 'right');
    $drv->say(dollar($trn->total()).q{ }, 'right,fat');
}

sub print_payments {
    my $this = shift;
    my $drv  = $this->{drv};
    my $htx  = $this->{htx};
    my $trn  = $this->{trn};    # Not from $htx but from $this

    # Any money given yet?
    return
        if !$trn->cash && !$trn->check && !$trn->cc;

    # Divider line
    $drv->say((qq{-}x19).'  ', 'right');

    # Cash
    if ($trn->cash()) {
        $drv->say(sprintf('Paid Cash %10s  ',
                          dollar($trn->cash())), 'right');
    }

    # Check
    if ($trn->check()) {
        my $ckinfo = $trn->checkinfo() || q{};
        $drv->say(sprintf('%s Paid Check %10s  ',
                          $ckinfo,
                          dollar($trn->check())), 'right');
    }

    # CC
    foreach my $chg ($trn->charges) {
	next if $chg->rcode ne "000";
        # Masked CC and amount
        my $ccmasked = $chg->{chgMaskedAcctNum};
        $drv->say(sprintf('%s %s CC %10s  ',
                          $chg->{chgMaskedAcctNum},
                          $chg->{chgType},
                          dollar($chg->amount_charged)), 'right');
        # Approval Code, Batch#, Gateway Processor's Trans ID
        $drv->put(sprintf("APV%6s B%6s TC%12s", 
			  $chg->acode, 
			  $chg->{chgBatchNum},
			  $chg->{chgTransactionID}),
                  'tiny,right');
        $drv->say(q{ }x13, 'right');
    }

    # Show the balance due or change
    if ($trn->change() >= 0) {
        # Change due
        $drv->say(sprintf('Change %10s  ', 
                          dollar($trn->change())), 'right');
    }
    else {
        $drv->say(sprintf('Balance Owed %10s  ', 
                          dollar($trn->owed())), 'bold,right');
    }
}

sub print_footer {
    my $this = shift;
    my $drv  = $this->{drv};
    my $htx  = $this->{htx};
    my $trn  = $this->{trn};    # Not from $htx but from $this
    my $cfg  = $htx->{cfg};
    my $sig  = $cfg->{haunt}->{sig} || q{Thank you!};
    my $website = $cfg->{haunt}->{website} || q{};

    # Summary line
    my $prdcount = $trn->{prdcount};    ### TODO: accessors
    my $upgcount = $trn->{upgcount};
    my $dsccount = $trn->{dsccount};
    $drv->say;
    $drv->say("$prdcount Items Sold * $upgcount Upgrades * $dsccount Discounts",
              "tiny,center");

    # Transaction bar code & repeat date
    my $bc12 = sprintf("%12.12d",$trn->{trnId});
    my $date = strftime("%a %d-%b-%Y %H:%M:%S %Z", localtime(time()));  # TODO: Use transaction date
    $drv->say($date,'tiny,center');
    $drv->barcode($bc12, 'center');

    # Refund policy
    my $policy = $cfg->{haunt}->{refund_policy};
    if ($policy) {
        $drv->say(q{-} x length($policy), 'wide,center');
        $drv->say($policy, 'wide,center');
        $drv->say(q{-} x length($policy), 'wide,center');
    }

    # Salutation
    $drv->say;
    $drv->say(_nl($sig), 'center');
    $drv->say("THIS IS YOUR RECEIPT", 'wide,center');
    $drv->say("$HTX_NAME $HTX_VERSION", 'tiny,center');

    # Pickup Code?
    if ($this->{pickuptix}) {
        $drv->say;
        $drv->say;
        $drv->say(q{-} x 40, 'center');
        $drv->say;
        $drv->say;
        $drv->say("You have purchased one or more FlexTix", 'center');
        $drv->say("for later printing at home via our web", 'center');
        $drv->say("site $website", 'center');
        $drv->say("To do this, you need this code:", 'center');
        $drv->say;
        my $pcode = $trn->fmtpickup();
        $drv->say("Pickup Code", 'wide,center');
        $drv->say($pcode, 'wide,tall,center');
        $drv->say;
        $drv->say("Protect this code; treat it like cash!", 'center');
        $drv->say;
    }

    # Page cut
    $drv->feed_and_cut;
}

1;
