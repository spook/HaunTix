#=============================================================================
#
# Hauntix Point of Sale GUI - Info panel
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use Tk;
use htx::frame;

package htx::pos_info;
our @ISA = qw(htx::frame);
use htx::pos_style;
use Term::Emit qw/:all/;

my $FW    = 250;
my $FH    = 130;
my $DEBUG = $ENV{'HTX_DEBUG'} || 0;

my @SHOWS;           # All shows
my @TODAYS_SHOWS;    # Just those today (or next available)
my $NEXT_DATE;       # Date we're showing (probably today)
my %CLASSES;         # Classes of today's shows
my @POOLS = qw/b w/; # Known ticket pools

#
# Make a new info panel
#
sub new {
    my ($class, $parent_frame, $htx) = @_;
    my $this = $parent_frame->Frame(
        -borderwidth => 3,
        -relief      => 'ridge',

        #   -background  => $COLOR_NOP,
        -width  => $FW,
        -height => $FH,
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
    my $db   = $htx->{db};
    emit "Getting ticket counts" if $DEBUG;

    # Load shows if not yet done
    if (!@SHOWS) {
        @SHOWS = htx::show::all_shows($htx);
        if ($htx::shows::ERR) {
            $this->{err} = "Error loading shows: $htx::shows::ERR";
            emit_error {-reason => $this->{err}} if $DEBUG;
            return $this;
        }
        if (!@SHOWS) {
            $this->{err} = "No shows defined!";
            emit_error {-reason => $this->{err}} if $DEBUG;
            return $this;
        }

        # Find just today's shows if not yet done
        my $today = _today();
        foreach my $s (sort {$a->{shoTime} cmp $b->{shoTime}} @SHOWS) {
            next if $s->{shoTime} lt $today;
            $NEXT_DATE = substr($s->{shoTime}, 0, 10) if !$NEXT_DATE;  # Grab the upcoming show date
            push @TODAYS_SHOWS, $s if substr($s->{shoTime}, 0, 10) eq $NEXT_DATE;
            ++$CLASSES{uc $s->{shoClass}};                             # Collect show class names
        }
    }

    $this->Label(-text => "Ticket Counts for $NEXT_DATE", -font => $FONT_SM)
        ->grid(-row => 0, -column => 0, -columnspan => 6);
    if (!@TODAYS_SHOWS) {
        $this->Label(-text => "--No upcoming shows--", -font => $FONT_SM)
            ->grid(-row => 0, -column => 0, -columnspan => 6);
        return $this;
    }

    # Column headers
    $this->Label(-text => "Show #",   -font => $FONT_XS)->grid(-row => 1, -column => 0);
    $this->Label(-text => "Class",    -font => $FONT_XS)->grid(-row => 1, -column => 1);
    $this->Label(-text => "Avail",    -font => $FONT_XS)->grid(-row => 1, -column => 2);
    $this->Label(-text => "per-Pool", -font => $FONT_XS)->grid(-row => 1, -column => 3);
    $this->Label(-text => "Used",     -font => $FONT_XS)->grid(-row => 1, -column => 4);
    $this->Label(-text => "Total",    -font => $FONT_XS)->grid(-row => 1, -column => 5);

#    $this->Label(-text => "------",   -font => $FONT_XS)->grid(-row => 2, -column => 0);
#    $this->Label(-text => "-----",    -font => $FONT_XS)->grid(-row => 2, -column => 1);
#    $this->Label(-text => "-----",    -font => $FONT_XS)->grid(-row => 2, -column => 2);
#    $this->Label(-text => "--------", -font => $FONT_XS)->grid(-row => 2, -column => 3);
#    $this->Label(-text => "----",     -font => $FONT_XS)->grid(-row => 2, -column => 4);
#    $this->Label(-text => "-----",    -font => $FONT_XS)->grid(-row => 2, -column => 5);
    my $r = 2;

    # For each show, lookup ticket counts
    my $all_used = 0;
    my $all_run  = 0;
    my $sql_base = "SELECT ";
    foreach my $pool (@POOLS) {
        $sql_base .= "SUM(tixState='Idle' and tixPool='$pool') AS $pool,";
    }
    $sql_base .= "SUM(tixState='Sold') as Sold,";
    $sql_base .= "SUM(tixState='Used') as Used,";
    $sql_base .= "SUM(tixState IN ('Idle','Held','Sold','Used')) as Total";
    $sql_base .= " FROM tickets WHERE shoID=";
    foreach my $show (@TODAYS_SHOWS) {
        my $sql  = $sql_base . $db->quote($show->{shoId});
        my $recs = $db->select($sql);
        if ($db->error) {
            $this->{err} = "Error getting ticket count : " . $db->error;
            emit_error {-reason => $this->{err}} if $DEBUG;
            return $this;
        }
        if (@$recs != 1) {
            $this->{err} = "Did not get one count record for ticket counts";
            emit_error {-reason => $this->{err}} if $DEBUG;
            return $this;
        }
        my $astr  = q{};
        my $avail = 0;
        my $sold  = $recs->[0]->{Sold}  || 0;
        my $used  = $recs->[0]->{Used}  || 0;
        my $total = $recs->[0]->{Total} || 0;
        foreach my $pool (@POOLS) {
            $avail += ($recs->[0]->{$pool} || 0);
            $astr  .= " / " if $astr;
            $astr  .= ($recs->[0]->{$pool} || 0)  . $pool;
        }
        $all_used += $used;
        $all_run  += $sold + $used;
        $this->Label(-text => $show->{shoId},    -font => $FONT_XS)->grid(-row => $r, -column => 0);
        $this->Label(-text => $show->{shoClass}, -font => $FONT_XS)->grid(-row => $r, -column => 1);
        $this->Label(-text => $avail,            -font => $FONT_XS)->grid(-row => $r, -column => 2);
        $this->Label(-text => $astr,             -font => $FONT_XS)->grid(-row => $r, -column => 3);
        $this->Label(-text => $used,             -font => $FONT_XS)->grid(-row => $r, -column => 4);
        $this->Label(-text => $total,            -font => $FONT_XS)->grid(-row => $r, -column => 5);
        $r++;
    }

    # Some totals
    $this->Label(-text => "All Used / Total Run = $all_used/$all_run", -font => $FONT_SM)
         ->grid(-row => $r++, -column => 0, -columnspan => 6);

    # Last Transaction
    $this->Label(-text => "Last Transaction: " . ($htx->{last_trn}? $htx->{last_trn}->fmtpickup() 
                                                                  : "---"),
                 -font => $FONT_SM, 
                 -background => $COLOR_LTGRN)
         ->grid(-row => $r++, -column => 0, -columnspan => 6);

    return $this;
}

#
# Update the panel
#
sub update {
    my $this = shift;

    # Delete existing items in the panel
    foreach my $kid ($this->children()) {
        $kid->destroy() if Tk::Exists $kid;
    }

    # Then refill it
    return $this->fill();
}

# Return today's date in ISO8601 format YYYY-MM-DD
sub _today {
    my (undef, undef, undef, $mday, $mon, $year) = localtime(time());
    return sprintf "%4.4d-%2.2d-%2.2d\n", 1900 + $year, 1 + $mon, $mday;
}

1;
