#=============================================================================
#
# Hauntix Point of Sale GUI - Bill Tally (receipt-like display)
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use Tk;
use htx::frame;

my $TESTMODE = ($ENV{HTX_TEST}||q{}) =~ m/b/;
my $TESTFILE = 'htx-pos-bill.t.out';

package htx::pos_bill;
  require Exporter;
  our @ISA    = qw(Exporter htx::frame);
  our @EXPORT = qw();
  use Date::Manip;
  use htx;
  use htx::pop_adj;
  use htx::pos_style;
  use htx::transaction;

my $FW = 365;
my $FH = 480;

#
# Make a new bill (receipt) tally panel
#
sub new {
    my ($class, $parent_frame, $htx) = @_;
    my $this = $parent_frame->Frame(
        -borderwidth => 3,
        -relief      => 'ridge',
       # -background  => $COLOR_NOP,
        -width       => $FW,
        -height      => $FH,
    );
    $this->{wantsize} = [-width => $FW, -height => $FH];
    $this->{htx} = $htx;
    $this->{icnt} = 0;      # item count
    $this->{isel} = 0;      # selected item (for delete/adjust) 0 = none, as displayed on-screen (not {sales} index)
    $this->{si}   = 0;      # actual sale item index in {sales}, but 1-based
    $this->{pickuptix} = 0; # count of pickup-later tickets
    bless($this, $class);
    return $this;
}

# Adjust price or quantity
sub do_adj {
    my $this  = shift;
    my $htx   = $this->{htx};
    my $mw    = $htx->{mw};
    my $trn   = $htx->{trn};
    my $nums  = $htx->{nums};
    my $sales = $trn->{sales};

    return if !$this->{isel};
    my $si = $this->{si};
    my $sale = $sales->[$si-1];
    my $popup = htx::pop_adj->new($mw, $htx, $sale)->fill();
    $popup->set_amt($sale->{salPaid});
    my $btn = $popup->show;
    if ($btn eq "OK") {
### TODO: pop adjust
        $sale->{salPaid} = $popup->get_amt;
        $trn->retally();
        $nums->set_tot($trn->total() / 100.0);
        ###TODO:  $popup->get_note;
        $this->update;
    }
}


# Remove an item from the sale
sub do_del {
    my $this = shift;
    my $htx  = $this->{htx};
    my $trn  = $htx->{trn};
    my $func = $htx->{func};

    return if !$this->{isel};
    $trn->remove_item($this->{si}); # Use si, not isel
    $this->{isel} = @{$trn->{sales}} if $this->{isel} > @{$trn->{sales}};
    $this->update;
    $func->dim_by_phase;
}

# Move the selection marker up
sub do_sel_up {
    my $this = shift;
    my $htx  = $this->{htx};
    my $trn  = $htx->{trn};
    $this->{isel}-- if $this->{isel};
    $this->update;
}

# Move the selection marker down
sub do_sel_dn {
    my $this = shift;
    my $htx  = $this->{htx};
    my $trn  = $htx->{trn};
    $this->{isel}++ if $this->{isel} < @{$trn->{sales}};
    $this->update;
}

#
# Populate the bill (receipt) panel.  Here are the parts:
#       Header:
#           (printed receipt only) Logo image
#           Transaction number
#           Station (terminal) ID
#           Cashier info
#       Sale Items:
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
#           (printed receipt only) 
#               Barcode of transaction #
#               Transaction number again
#               Date & time
#               Product Counts
#               Pickup Code if needed
#           (on-screen only:)
#               One-line sales summary - item counts...
#               Up/Down and delete buttons
#               Pickup Code if needed
#
sub fill {
    my $this = shift;
    my $htx  = $this->{htx};
    my $trn  = $htx->{trn};

    # Test mode
    open ($this->{F}, '>', $TESTFILE) if $TESTMODE;
    my $F = $this->{F};
    print $F "[Bill]\n" if $TESTMODE;
    print $F "Timestamp: ".time()."\n" if $TESTMODE;

    # Empty header if nothing rung up yet
    if (@{$trn->{sales}} == 0) {
        $this->Label(-text => "")->pack(-side => 'top');
        $this->Label(-text => "----------------------------------------")
            ->pack(-side => 'top');
        $this->Label(-text => "Ready for Sale", -font => $FONT_MD)
            ->pack(-side => 'top');
        $this->Label(-text => "----------------------------------------")
            ->pack(-side => 'top');

        if ($TESTMODE) {
            print $F "ReadyForSale: 1\n";
            close $F;
        }
        return $this;
    }

    # Fill in the aprts
    $this->fill_header();
    $this->fill_sales();
    $this->fill_totals();
    $this->fill_payments();
    $this->fill_footer();

    close $F if $TESTMODE;
    return $this;
}

sub fill_header {
    my $this = shift;
    my $htx  = $this->{htx};
    my $trn  = $htx->{trn};
    my $F = $this->{F};

    $this->Label(
        -text => "Transaction #$trn->{trnId}",
        -font => $FONT_SM
    )->pack(-anchor => 'center');

    print $F "Transaction: $trn->{trnId}\n" if $TESTMODE;
}

sub fill_sales {
    my $this = shift;
    my $htx  = $this->{htx};
    my $trn  = $htx->{trn};
    my $si;
    $this->{icnt} = 0;  # for selection, works with {isel}

    # Show ticket products first
    $si = 0;
    $this->{pickuptix} = 0;
    foreach my $sale ($trn->sales()) {
        $si++;
        next unless $sale->{salType} eq 'prd';
        next unless $sale->{salIsTicket};
        $this->{pickuptix}++ if !$sale->{show};
        $this->{icnt}++;
        $this->{si} = $si if $this->{isel} == $this->{icnt};
        $this->fill_sale_line($sale);
    }

    # Show non-ticket products
    $si = 0;
    foreach my $sale ($trn->sales()) {
        $si++;
        next unless $sale->{salType} eq 'prd';
        next if $sale->{salIsTicket};
        $this->{icnt}++;
        $this->{si} = $si if $this->{isel} == $this->{icnt};
        $this->fill_sale_line($sale);
    }

    # Then show upgrades
    $si = 0;
    foreach my $sale ($trn->sales()) {
        $si++;
        next unless $sale->{salType} eq 'upg';
        $this->{icnt}++;
        $this->{si} = $si if $this->{isel} == $this->{icnt};
        $this->fill_sale_line($sale);
    }

    # Lastly, show discounts
    $si = 0;
    foreach my $sale ($trn->sales()) {
        $si++;
        next unless $sale->{salType} eq 'dsc';
        $this->{icnt}++;
        $this->{si} = $si if $this->{isel} == $this->{icnt};
        $this->fill_sale_line($sale);
    }

    ### TODO: apply-to-all comps
}

sub fill_sale_line {
    my ($this, $sale) = @_;
    my $htx = $this->{htx};
    my $trn = $htx->{trn};
    my $F = $this->{F};

    my $fg
        = ($sale->{salType} eq 'prd')
            && $sale->{salIsTicket} ? $COLOR_TXT_TIX
        : ($sale->{salType} eq 'prd')
            && !$sale->{salIsTicket}  ? $COLOR_TXT_MCH
        : $sale->{salType} eq 'upg'   ? $COLOR_TXT_UPG
        : $sale->{salType} eq 'dsc'   ? $COLOR_TXT_DSC
        :                               $COLOR_TXT_NOP;
    my @bg = ();
    @bg = (-background => $COLOR_YELLOW) if $this->{isel} == $this->{icnt};

    my $qty    = $sale->{salQuantity};
    my $nam    = $sale->{salName};
    my $per    = $sale->{salPaid};
    my $tot    = $per * $qty;
    my $taxstr = $sale->{salIsTaxable} ? q{TX} : q{};

    if ($sale->{show}) {
        my $show = $sale->{show}; 
        my $nite = substr($show->{shoTime}, 5, 5); # MM-DD
        $nam .= ": $nite";
    }

    # TODO if $qty > 99 || length($totstr) > 9 ... use TWO-LINE format
    # One-line format
    my $iline = $this->Frame(-height => 25, @bg)->pack(-fill => 'x');
    $iline->Label(
        -text       => $qty + 0,
        -font       => $FONT_SM,
        -anchor     => 'e',
        -foreground => $fg, @bg
        )->form(
        -left   => '%0',
        -right  => '%7',
        -top    => '%0',
        -bottom => '%100'
        );

    $iline->Label(
        -text       => $nam,
        -font       => $FONT_SM,
        -anchor     => 'w',
        -foreground => $fg, @bg
        )->form(
        -left   => '%7',
        -right  => '%51',
        -top    => '%0',
        -bottom => '%100'
        );

    my $ovr = $sale->{salCost} != $sale->{salPaid};
    my $pfg = $ovr? $COLOR_YELLOW : $fg;   # Override?
    my @pbg = $ovr? (-bg => $COLOR_BG) : @bg;
    $iline->Label(
        -text       => dollars($per),
        -font       => $FONT_SM,
        -anchor     => 'e',
        -foreground => $pfg, @pbg
        )->form(
        -left   => '%51',
        -right  => '%71',
        -top    => '%0',
        -bottom => '%100'
        );

    $iline->Label(
        -text       => dollars($tot),
        -font       => $FONT_SM,
        -anchor     => 'e',
        -foreground => $fg, @bg
        )->form(
        -left   => '%72',
        -right  => '%94',
        -top    => '%0',
        -bottom => '%100'
        );

    $iline->Label(
        -text       => $taxstr,
        -font       => $FONT_SM,
        -anchor     => 'e',
        -foreground => $fg, @bg
        )->form(
        -left   => '%94',
        -right  => '%100',
        -top    => '%0',
        -bottom => '%100'
        );

    # Test output
    if ($TESTMODE) {
        my $sel = ($this->{isel} == $this->{icnt})? q{*} : q{.};
        my $type = $sale->{salType};
        $type = 'tix' if ($sale->{salType} eq 'prd') && $sale->{salIsTicket};
        my $bang = $ovr? q{!} : q{>};
        print $F "Item: $sel $type $qty '$nam' ".dollars($per)." $bang " . dollars($tot) . " $taxstr\n";
    }


    # Second line if needed
    my $show_info = q{};
    if ($sale->{salIsTimed}) {
        my $jline = $this->Frame(-height => 21, @bg)->pack(-fill => 'x');
        $show_info = "-- FlexTix --";
        if ($sale->{show}) {
            my $time = UnixDate($sale->{show}->{shoTime}, q{%I:%M%p %a %d %b %Y})
                    || $sale->{show}->{shoTime}
                    || qq{$sale->{show} ???};
            $time =~ s/^0//;
            $show_info = "Showtime: $time";
        }
        $jline->Label(
            -text       => $show_info,
            -font       => $FONT_SM,
            -anchor     => 'w',
            -foreground => $fg, @bg
            )->form(
            -left   => '%9',
            -right  => '%99',
            -top    => '%0',
            -bottom => '%100'
            );

    }
    print $F "Info: $show_info\n" if $TESTMODE;
}

sub fill_totals {
    my $this = shift;
    my $htx  = $this->{htx};
    my $trn  = $htx->{trn};
    my $F = $this->{F};

    # Divider line
    my $dline = $this->Frame(-height => 28)->pack(-fill => 'x');
    $dline->Label(-text => q{-} x 40, -font => $FONT_SM, -anchor => 'e')
        ->form(
        -left   => '%50',
        -right  => '%100',
        -top    => '%0',
        -bottom => '%100'
        );

    # Subtotal
    my $sline = $this->Frame(-height => 28)->pack(-fill => 'x');
    $sline->Label(-text => "Subtotal", -font => $FONT_SM, -anchor => 'e')
        ->form(
        -left   => '%36',
        -right  => '%66',
        -top    => '%0',
        -bottom => '%100'
        );
    $sline->Label(
        -text   => dollars($trn->subtotal()),
        -font   => $FONT_SM,
        -anchor => 'e'
        )->form(
        -left   => '%67',
        -right  => '%94',
        -top    => '%0',
        -bottom => '%100'
        );
    print $F "Subtotal: ".dollars($trn->subtotal())."\n" if $TESTMODE;

    # Tax
    my $ratestr = sprintf('%4.2f', $trn->taxrate()) . q{%};
    my $xline = $this->Frame(-height => 28)->pack(-fill => 'x');
    $xline->Label(
        -text   => "$ratestr Tax",
        -font   => $FONT_SM,
        -anchor => 'e'
        )->form(
        -left   => '%36',
        -right  => '%66',
        -top    => '%0',
        -bottom => '%100'
        );
    print $F "TaxRate: $ratestr\n" if $TESTMODE;
    $xline->Label(
        -text   => dollars($trn->tax()),
        -font   => $FONT_SM,
        -anchor => 'e'
        )->form(
        -left   => '%67',
        -right  => '%94',
        -top    => '%0',
        -bottom => '%100'
        );
    print $F "Tax: ".dollars($trn->tax())."\n" if $TESTMODE;

    # Total
    my $tline = $this->Frame(-height => 28)->pack(-fill => 'x');
    $tline->Label(
        -text   => "Total",
        -font   => "$FONT_SM bold",
        -anchor => 'e'
        )->form(
        -left   => '%36',
        -right  => '%66',
        -top    => '%0',
        -bottom => '%100'
        );
    $tline->Label(
        -text   => dollars($trn->total()),
        -font   => "$FONT_SM bold",
        -anchor => 'e'
        )->form(
        -left   => '%67',
        -right  => '%94',
        -top    => '%0',
        -bottom => '%100'
        );
    print $F "Total: ".dollars($trn->total())."\n" if $TESTMODE;
}

sub fill_payments {
    my $this = shift;
    my $htx  = $this->{htx};
    my $trn  = $htx->{trn};
    my $F = $this->{F};

    # Any money given yet?
    return
        if !$trn->cash() && !$trn->check() && !$trn->cc();

    # Divider line
    my $dline = $this->Frame(-height => 28)->pack(-fill => 'x');
    $dline->Label(-text => q{-} x 40, -font => $FONT_SM, -anchor => 'e')
        ->form(
        -left   => '%50',
        -right  => '%100',
        -top    => '%0',
        -bottom => '%100'
        );

    # Cash
    if ($trn->cash()) {
        my $line = $this->Frame(-height => 28)->pack(-fill => 'x');
        $line->Label(
            -text   => "Paid Cash",
            -font   => $FONT_SM,
            -anchor => 'e'
            )->form(
            -left   => '%36',
            -right  => '%66',
            -top    => '%0',
            -bottom => '%100'
            );
        $line->Label(
            -text   => dollars($trn->cash()),
            -font   => $FONT_SM,
            -anchor => 'e'
            )->form(
            -left   => '%67',
            -right  => '%94',
            -top    => '%0',
            -bottom => '%100'
            );
        print $F "CashPaid: ".dollars($trn->cash())."\n" if $TESTMODE;
    }

    # Check
    if ($trn->check()) {
        my $line = $this->Frame(-height => 28)->pack(-fill => 'x');
        my $cinfo = $trn->checkinfo() || q{};
        $line->Label(
            -text   => "Paid Check $cinfo",
            -font   => $FONT_SM,
            -anchor => 'e'
            )->form(
            -left   => '%36',
            -right  => '%66',
            -top    => '%0',
            -bottom => '%100'
            );
        $line->Label(
            -text   => dollars($trn->check()),
            -font   => $FONT_SM,
            -anchor => 'e'
            )->form(
            -left   => '%67',
            -right  => '%94',
            -top    => '%0',
            -bottom => '%100'
            );
        print $F "CheckPaid: ".dollars($trn->check())."\n" if $TESTMODE;
        print $F "CheckInfo: $cinfo\n" if $TESTMODE;
    }

    # CC
    foreach my $chg ($trn->charges) {
	    next if $chg->rcode ne "000";
        my $line = $this->Frame(-height => 28)->pack(-fill => 'x');
	    my $masked = $chg->{chgMaskedAcctNum};
	    $masked =~ s/\*+/xx/;
        $line->Label(
            -text   => "$chg->{chgType} $chg->{chgCardType} $masked",
            -font   => $FONT_SM,
            -anchor => 'e'
            )->form(
            -left   => '%13',
            -right  => '%66',
            -top    => '%0',
            -bottom => '%100'
            );
        $line->Label(
            -text   => dollars($chg->amount_charged),
            -font   => $FONT_SM,
            -anchor => 'e'
            )->form(
            -left   => '%67',
            -right  => '%94',
            -top    => '%0',
            -bottom => '%100'
            );
        print $F "CCPaid: ".dollars($chg->amount_charged)."\n" if $TESTMODE;
        print $F "CCType: $chg->{chgType}\n" if $TESTMODE;
        print $F "CCCard: $chg->{chgCardType}\n" if $TESTMODE;
        print $F "CCMask: $masked\n" if $TESTMODE;
    }

    # Show the balance due or change
    my $line = $this->Frame(-height => 28)->pack(-fill => 'x');
    if ($trn->change() >= 0) {

        # Change due
        $line->Label(-text => "Change", -font => $FONT_SM, -anchor => 'e')
            ->form(
            -left   => '%36',
            -right  => '%66',
            -top    => '%0',
            -bottom => '%100'
            );
        $line->Label(
            -text   => dollars($trn->change()),
            -font   => $FONT_SM,
            -anchor => 'e'
            )->form(
            -left   => '%67',
            -right  => '%94',
            -top    => '%0',
            -bottom => '%100'
            );
        print $F "Change: ".dollars($trn->change())."\n" if $TESTMODE;
    }
    else {

        # Balance still owed
        $line->Label(
            -text       => "Balance Owed",
            -font       => $FONT_SM,
            -anchor     => 'e',
            -foreground => $COLOR_RED
            )->form(
            -left   => '%36',
            -right  => '%66',
            -top    => '%0',
            -bottom => '%100'
            );
        $line->Label(
            -text       => dollars(-$trn->change()),
            -font       => $FONT_SM,
            -anchor     => 'e',
            -foreground => $COLOR_RED
            )->form(
            -left   => '%67',
            -right  => '%94',
            -top    => '%0',
            -bottom => '%100'
            );
        print $F "Owe: ".dollars(-$trn->change())."\n" if $TESTMODE;
    }
}

sub fill_footer {
    my $this = shift;
    my $htx  = $this->{htx};
    my $trn  = $htx->{trn};
    my $F = $this->{F};

    # Up/Down and delete buttons
    my $dframe = $this->Frame(-height => 47)
        ->pack(-side => 'bottom', -fill => 'x');
    $this->{_selup_btn} = $dframe->Button
                 (-text    => "\x{2191} Up",
                  -font    => $FONT_MD,
                  -command => sub {$this->do_sel_up},
                  -state => $this->{isel}? 'normal' : 'disabled',
                 )->grid(-row => 1, -column => 0, -sticky => 'nsew');
    $htx->{mw}->bind('<Key-Up>' => sub {$this->do_sel_up});
    $this->{_del_btn} = $dframe->Button
                 (-text    => "\x{2718} Remove",
                  -font => $FONT_MD,
                  -command => sub {$this->do_del},
                  -state => $this->{isel}? 'normal' : 'disabled'
                 )->grid(-row => 1, -column => 1, -sticky => 'nsew');
    $htx->{mw}->bind('<Key-Delete>' => sub {$this->do_del});
    $this->{_adj_btn} = $dframe->Button
                 (-text    => "\x{270d} Adjust",
                  -font => $FONT_MD,
                  -command => sub {$this->do_adj},
                  -state => $this->{isel}? 'normal' : 'disabled'
                 )->grid(-row => 1, -column => 2, -sticky => 'nsew');
    $htx->{mw}->bind('<Key-Insert>' => sub {$this->do_adj});
    $this->{_seldn_btn} = $dframe->Button
                 (-text    => "Down \x{2193}",
                  -font => $FONT_MD,
                  -command => sub {$this->do_sel_dn},
                  -state => $this->{isel} < @{$trn->{sales}}? 'normal' : 'disabled',
                 )->grid(-row => 1, -column => 3, -sticky => 'nsew');
    $htx->{mw}->bind('<Key-Down>' => sub {$this->do_sel_dn});

    # Summary line - at bottom
    my $prdcount = $trn->{prdcount};    ### TODO: accessors
    my $upgcount = $trn->{upgcount};
    my $dsccount = $trn->{dsccount};
    my $cline
        = $this->Frame(-height => 28)->pack(-side => 'bottom', -fill => 'x');
    my $sumtxt = "$prdcount Items Sold * $upgcount Upgrades * $dsccount Discounts Given";
    $cline->Label(
        -text => $sumtxt,
        -font   => $FONT_SM,
        -anchor => 's'
        )->form(
        -left   => '%1',
        -right  => '%99',
        -top    => '%0',
        -bottom => '%100'
        );
    print $F "Summary: $sumtxt\n" if $TESTMODE;

    # Pickup Code?
    if ($this->{pickuptix}) {
        my $pline
            = $this->Frame(-height => 35)->pack(-side => 'bottom', -fill => 'x');
        $pline->Label(
            -text   => "Pickup Code " . $trn->fmtpickup(),
            -font   => $FONT_MD,
            -fg     => $COLOR_RED,
            -bg     => $COLOR_YELLOW,
            -anchor => 's'
            )->form(
            -left   => '%1',
            -right  => '%99',
            -top    => '%0',
            -bottom => '%100'
            );
        print $F "PickupCode: ".$trn->fmtpickup()."\n" if $TESTMODE;
    }

    # Sale complete?
    if ($trn->phase() eq $TRN_PHASE_FIN) {
        $this->Label(-text => "*************", -font => $FONT_MD)
            ->pack(-side => 'bottom');
        $this->Label(-text => "Sale Complete", -font => $FONT_MD)
            ->pack(-side => 'bottom');
        $this->Label(-text => "*************", -font => $FONT_MD)
            ->pack(-side => 'bottom');
        print $F "SaleComplete: 1\n" if $TESTMODE;
    }

}

#
# Get/set the selected index
#
sub selected {
    my ($this, $isel) = @_;
    $this->{isel} = $isel if defined $isel;
    return $this->{isel};
}

#
# Update the bill (receipt) panel
#
sub update {
    my $this = shift;

    # Delete existing items in the bill
    foreach my $kid ($this->children()) {
        $kid->destroy() if Tk::Exists $kid;
    }

    # Then refill it
    return $this->fill();
}

1;
