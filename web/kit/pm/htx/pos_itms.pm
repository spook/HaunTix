#=============================================================================
#
# Hauntix Point of Sale GUI - Items button array
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use Tk;
use htx::frame;

package htx::pos_itms;
require Exporter;
our @ISA    = qw(Exporter htx::frame);
our @EXPORT = qw();
use htx::pop_error;
use htx::pop_show;
use htx::pop_warn;
use htx::pos_nums;
use htx::pos_style;

my $FW   = 410;
my $FH   = 530;
my $COLS = 3;
my $ROWS = 9;

my @SHOWS;    # List of show objects
my @KEYS = ('a' .. 'z', 'Z');    # for key bindings, Alt-i-letter

my $TESTMODE = ($ENV{HTX_TEST} || q{}) =~ m/i/;
my $TESTFILE = 'htx-pos-itms.t.out';

#
# Make a new items button panel
#
sub new {
    my ($class, $parent_frame, $htx) = @_;
    my $this = $parent_frame->Frame(
        -borderwidth => 3,
        -relief      => 'ridge',
        -background  => $COLOR_NOP,
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
    my $htx  = $this->{htx};

    # Test output
    open(F, '>', $TESTFILE) if $TESTMODE;
    print F "[Items]\n" if $TESTMODE;

    # Display the buttons
    my $colwid = int(100 / $COLS);
    my $rowhgt = int(100 / $ROWS);
    for my $i (0 .. ($ROWS * $COLS - 1)) {
        my $btntext     = q{};
        my $state       = 'disabled';
        my $background  = $COLOR_BTN_NOP;
        my $borderwidth = 1;
        my @btncmd      = ();
        my @binding     = ();
        my $btntype     = q{};
        my $item        = $htx->{items}->[$i];
        if ($item) {
            $btntext = $item->{itmName};
            $btntext .= " \x{231A}"  if !$item->{itmIsNextAvail} && $item->{itmIsTimed};
            $btntext .= " \x{1D344}" if !$item->{itmIsNextAvail} && $item->{itmIsDaily};
            $btntype     = $item->{itmType};
            $btntype     = 'tix' if ($btntype eq 'prd') && $item->{itmIsTicket};
            $state       = 'normal';
            $borderwidth = 3;
            @btncmd      = (-command => sub {$this->process_item($item);});
            $background
                = $btntype eq 'tix' ? $COLOR_BTN_TIX
                : $btntype eq 'prd' ? $COLOR_BTN_MCH
                : $btntype eq 'upg' ? $COLOR_BTN_UPG
                : $btntype eq 'dsc' ? $COLOR_BTN_DSC
                :                     $COLOR_BTN_NOP;
            @binding = ("<Alt-Key-i><Key-$KEYS[$i]>", $btncmd[1]);
        }
        my $wantrow = int($i / $COLS);
        my $wantcol = $i % $COLS;
        my ($l, $r) = ($wantcol * $colwid, ($wantcol + 1) * $colwid - 1);
        my ($t, $b) = ($wantrow * $rowhgt, ($wantrow + 1) * $rowhgt - 1);
        $this->{"btn$i.wst"} = $state;          # Normal state (to restore when we undim)
        $this->{"btn$i.wbg"} = $background;     # Normal bg color (to restore when we undim)
        $this->{"btn$i"}     = $this->Button(
            -text        => $btntext,
            -font        => $FONT_MD,
            -state       => $state,
            -background  => $background,
            -borderwidth => $borderwidth,
            -wraplength  => 110,
            @btncmd
            )->form(
            -left   => ["%" . $l, 2],
            -right  => ["%" . $r, 2],
            -top    => ["%" . $t, 9],
            -bottom => ["%" . $b, 9]
            );
        $htx->{mw}->bind(@binding) if @binding;

        if ($TESTMODE) {
            print F "ButtonText: $btntext\n";
            print F "ButtonType: $btntype\n";
            print F "ButtonState: $state\n";
            print F "ButtonHotKey: " . ($binding[0] || q{}) . "\n";
            print F "Button-$KEYS[$i]: $btntext\n";
            print F "Name $btntext: $state\n";
            print F "Code $btntext: $KEYS[$i]\n";
        }
    }
    close F if $TESTMODE;

    return $this;
}

#
# Dim and disable all buttons
#
sub dim {
    my $this = shift;
    for my $i (0 .. ($ROWS * $COLS - 1)) {
        $this->{"btn$i"}->configure(
            -state      => 'disabled',
            -background => $COLOR_NOP
        ) if $this->{"btn$i"};
    }
    return $this;
}

#
# Put all buttons back to normal (undo a dim())
#
sub lit {
    my $this = shift;
    for my $i (0 .. ($ROWS * $COLS - 1)) {
        $this->{"btn$i"}->configure(
            -state      => $this->{"btn$i.wst"},
            -background => $this->{"btn$i.wbg"}
        ) if $this->{"btn$i"};
    }
    return $this;
}

sub reload {
    my $this = shift;

    # Nuke existing buttons
    for my $i (0 .. ($ROWS * $COLS - 1)) {
        $this->{"btn$i"}->destroy()
            if $this->{"btn$i"} && Tk::Exists($this->{"btn$i"});
        delete $this->{"btn$i"};
        delete $this->{"btn$i.wst"};
        delete $this->{"btn$i.wbg"};
    }

    # Re-fill the panel
    return $this->fill();
}

#
# Builds up the transaction and sales records,
#  as items (products, discounts, upgrades) are rung-up.
#
sub process_item {
    my ($this, $item) = @_;
    my $htx  = $this->{htx};
    my $mw   = $htx->{mw};
    my $trn  = $htx->{trn};
    my $nums = $htx->{nums};
    my $pays = $htx->{pays};
    my $bill = $htx->{bill};
    my $func = $htx->{func};

    # Get quantity multiplier
    my $qty = $nums->get_amt() || 1;
    if ($qty !~ m/^\d+$/) {
        $nums->set_msg("Bad quantity: $qty");    # Probably has a decimal in it
        $mw->bell();
        return 0;
    }
    $qty = int($qty);                            # Sometimes we get a leading zero; this cleans it

    # Get the item object reference
    if (!$item) {
        $nums->set_msg("No item for this button");
        $mw->bell;
        return 0;
    }

    # Big quantity - verify it
    my $cfg = $htx->{cfg};
    my $thr = $cfg->{pos}->{warn_amount} || 100;
    if ($qty >= $thr) {
        my $ans = htx::pop_warn::show($htx,"Really?\nYou want $qty?\n".('-' x 47));
        if ($ans ne "OK") {
            my $nums = $htx->{nums};
            $nums->set_amt(0);
            return 0;
        }
    }

    # Timed Ticket - Autopick
    if ($item->{itmIsTimed} && $item->{itmIsNextAvail}) {
        htx::pop_error::show($htx,"Timed Tickets Autopick TBD");
        $item->{show} = undef;
        return 0;
    }

    # Timed Ticket - Manual Show Selection
    elsif ($item->{itmIsTimed}) {
        my $popup = htx::pop_show->new($mw, $htx)->fill(
            -shoName  => $item->{itmName},
            -shoClass => $item->{itmClass},
            -qty      => $qty
        );
        my $btn = $popup->show;
        $item->{show} = $popup->selected_show;
        return 0 if !$item->{show} && $btn eq "Cancel";

        # If the show has a specific cost, use that cost
        $item->{itmCost} = $item->{show}->{shoCost} || $item->{itmCost}
            if $item->{show};
    }

    # Daily Ticket - Autopick
    elsif ($item->{itmIsDaily} && $item->{itmIsNextAvail}) {

        $item->{show} = undef;

        if (!@SHOWS) {
            @SHOWS = htx::show::all_shows($htx);
            if ($htx::shows::ERR) {
                htx::pop_error::show($htx,"Error loading shows: $htx::shows::ERR");
                $item->{show} = undef;
                return 0;
            }
            if (!@SHOWS) {
                htx::pop_error::show($htx,"No shows defined!");
                $item->{show} = undef;
                return 0;
            }
        }
        my $today = _today();
        foreach my $s (sort {$a->{shoTime} cmp $b->{shoTime}} @SHOWS) {
            next unless uc($s->{shoClass}) eq uc($item->{itmClass});
            ###print "Show $s->{shoId} at $s->{shoTime}\n";
            if ($s->{shoTime} ge $today) {
                $item->{show} = $s;
                last;
            }
        }

        if (!$item->{show}) {
            htx::pop_error::show($htx,"No upcoming show!");
            $item->{show} = undef;
            return 0;
        }

        # If the show has a specific cost, use that cost
        $item->{itmCost} = $item->{show}->{shoCost} || $item->{itmCost};
    }

    # Daily Ticket - Manual Show Selection
    elsif ($item->{itmIsDaily}) {
        my $popup = htx::pop_show->new($mw, $htx)->fill(
            -shoName  => $item->{itmName},
            -shoClass => $item->{itmClass},
            -qty      => $qty
        );
        my $btn = $popup->show;
        $item->{show} = $popup->selected_show;
        return 0 if !$item->{show} && $btn eq "Cancel";

        # If the show has a specific cost, use that cost
        $item->{itmCost} = $item->{show}->{shoCost} || $item->{itmCost}
            if $item->{show};
    }

    # Anyday ticket
    elsif ($item->{itmIsTicket}) {

        # Find the show matching the item's show name and class
        if (!@SHOWS) {
            @SHOWS = htx::show::all_shows($htx);
            if ($htx::shows::ERR) {
                htx::pop_error::show($htx,"Error loading shows: $htx::shows::ERR");
                $item->{show} = undef;
                return 0;
            }
            if (!@SHOWS) {
                htx::pop_error::show($htx,"No shows defined!");
                $item->{show} = undef;
                return 0;
            }
        }
        foreach my $show (@SHOWS) {
            if (   (lc($show->{shoName}) eq lc($item->{itmName}))
                && (lc($show->{shoClass}) eq lc($item->{itmClass})))
            {

                # This is the show
                $item->{show} = $show;
                last;
            }
        }
        if (!$item->{show}) {
            htx::pop_error::show($htx,"Could not find non-timed show for"
                . " item class=$item->{itmClass}"
                . " and name=$item->{itmName}"
            );
            $item->{show} = undef;
            return 0;
        }
    }

    # Add this item to the transaction
    if (my $err = $trn->add_item($item, $qty)) {
        $func->dim_by_phase;
        if ($err =~ m/unable to get.+?(\d+)\savailable/i) {
            my $avail = $1;
            $err = $avail? "\nNOT ENOUGH LEFT\n\n$err" : "\nSOLD OUT\n\n$err";
        }
        $nums->set_amt(0);
        htx::pop_error::show($htx,$err);
        return 0;
    }

    # Update related display elements
    $func->dim_by_phase;
    $nums->set_tot($trn->total() / 100.0);
    $bill->selected(0);    # clear selection if any
    $bill->update();
    $pays->lit();

    return 1;
}

# Return today's date in ISO8601 format YYYY-MM-DD
sub _today {
    my (undef, undef, undef, $mday, $mon, $year) = localtime(time());
    return sprintf "%4.4d-%2.2d-%2.2d\n", 1900 + $year, 1 + $mon, $mday;
}

1;
