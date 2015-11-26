#=============================================================================
#
# Hauntix Point of Sale GUI - Show Selector Popup Panel
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use Tk;
use Tk::DialogBox;
use Tk::Pane;

package htx::pop_show;
  our @ISA    = qw(Tk::DialogBox);
  use Date::Manip;
  use htx;
  use htx::pos_style;
  use htx::show;
  use htx::ticket;

  my $FW    = 640;
  my $FH    = 550;

#
# A popup to select a particular show
#
sub new {
    my ($class, $parent, $htx) = @_;
    my $this = $parent->DialogBox(
        -title          => "Choose Showtime",
        -default_button => "Cancel",
        -buttons        => ["Cancel"]
    );
    $this->geometry($FW . "x" . $FH);
    $this->Subwidget("B_Cancel")->configure(-font => $FONT_LG);
    $this->{wantsize} = [-width => $FW, -height => $FH];
    $this->{the_show} = undef;
    $this->{firt_day} = q{};
    $this->{view_day} = q{};
    $this->{last_day} = q{};
    $this->{htx}      = $htx;
    bless($this, $class);
    return $this;
}

sub fill {
    my $this = shift;
	my $htx = $this->{htx};

    my %cargs = _c(@_);
	$this->{qty}      = $cargs{qty}      || 1; 
	$this->{shoName}  = $cargs{shoname}  || "My Show"; 
	$this->{shoClass} = $cargs{shoclass} || "REG"; 
	$this->{tixPool}  = $cargs{tixpool}  || $TIX_POOL_BOOTH;

    # Header
    my $f = $this->add('Frame')->pack(-expand => 1, -fill => 'both');
    $f->Label(-text => "Want $this->{qty} of $this->{shoName}",
              -font => $FONT_BG)->pack();


    # Lookup available shows
    $this->{shows} ||= htx::show::availables(-htx        => $this->{htx},
                                             -shoClass   => $this->{shoClass},
                                             -tixPool    => $this->{tixPool});
    if ($htx::show::ERR) {
        $f->Label(-text => "Error encountered",
                  -font => $FONT_MD)->pack;
        $f->Label(-text => $htx::show::ERR)->pack();
        return $this;
    }

    # Make the list of shows
    my $flist = $f->Scrolled('Pane', Name => 'Shows', -scrollbars => 'e')->pack(-expand => 1, -fill => 'both');
    $flist->Subwidget("yscrollbar")->configure(-width => 40);
    my $first  = undef;
    foreach my $show (@{$this->{shows}}) {
        my $tix_avail = $show->{count};
        my $qty_ok = $tix_avail >= $this->{qty};
        my $day_ok = Date_Cmp($show->{shoSellUntil}, "now") > 0;
        my $cost = dollars($show->{shoCost});
        my $stat = !$day_ok    ? "CLOSED"
                 : !$tix_avail ? "SOLD OUT"
                 : !$qty_ok    ? "Only Have $tix_avail"
                 :               "$tix_avail Avail $cost"
                 ;
        my $date = UnixDate($show->{shoTime}, '%a %b %d, %Y');
        my $time = UnixDate($show->{shoTime}, '%I:%M %p');
        $time =~ s/^0//;
        my $bg  = $qty_ok && $day_ok? $COLOR_BTN_TIX : $COLOR_NOP;
        my $btn = $flist->Button(-text    => "$date $time -- $stat",
                                 -font    => $FONT_BG,
                                 -background => $bg,
                                 -state   => $qty_ok && $day_ok? 'normal' : 'disabled',
                                 -command => sub {$this->{the_show} = $show;
                                                  $this->Exit;
                                                 })->pack(-fill=>'x');
        $first = $btn if !$first && $qty_ok && $day_ok;
    }

    # Scroll to the first available show
#    $flist->see($first) if $first;     # No workee - seems the Pane isn't ready yet
    if ($first) {
#        $this->afterIdle(sub{$flist->see($first);});
        $this->afterIdle(sub{$flist->yview($first);});
    }

    return $this;
}

# returns the selected show ID; undef means none (cancelled)
sub selected_show {
    my $this = shift;
    return $this->{the_show};
}

# Display the popup (confusing name - not related to an event's show)
sub show {
    my ($this) = @_;
    return $this->Show();
}

1;

