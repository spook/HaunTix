#=============================================================================
#
# Hauntix Point of Sale - An event show
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

package htx::show;
use htx;
use htx::ticket;
use Term::Emit qw/:all/;
my @COLS = qw/shoTime shoSellUntil shoClass shoCost shoName/;
my $DEBUG = $ENV{'HTX_DEBUG'} || 0;
our $ERR = q{};

# Get a list of all shows
sub all_shows {
    emit __PACKAGE__ . "::all_shows()" if $DEBUG;
    my $htx = shift;
    my $db  = $htx->{db};
    my $sql = "SELECT shoId," . join(q{,}, @COLS) . " FROM shows;";
    emit_text "SQL = $sql" if $DEBUG;
    my $recs = $db->select($sql);
    if ($db->error) {
        $ERR = "Error fetching show list: " . $db->error;
        emit_error {-reason => $ERR} if $DEBUG;
        return ();
    }
    my @shows = ();
    foreach my $rec (@$recs) {
        push @shows, htx::show->new(-htx => $htx, %$rec);
    }
    $ERR = q{};
    return @shows;
}

# Class-function: Gets list of all shows with counts of available tickets.
#  Returns an array ref of show objects, including {count} in each object.
#  htx::show::availables(-htx=>$htx, -shoClass=>$sc, -tixPool=>$tp);
sub availables {
    emit __PACKAGE__ . "::availables()" if $DEBUG;
    my %cargs    = _c(@_);
    my $htx      = $cargs{htx};                           # Required
    my $shoClass = $cargs{shoclass} || "REG";             ### TODO: constants for this
    my $tixPool  = $cargs{tixpool} || $TIX_POOL_BOOTH;
    my $tixState = $cargs{tixstate} || $TIX_STATE_IDLE;
    my $db       = $htx->{db};

    my $sql
        = "SELECT o.shoId,count(t.shoId) as count,"
        . join(q{,}, map {"o.$_"} @COLS)
        . "  FROM shows o"
        . "  LEFT OUTER JOIN tickets t"
        . "    ON t.shoid = o.shoid"
        . "   AND t.tixState = "
        . $db->quote($tixState)
        . "   AND t.tixPool  = "
        . $db->quote($tixPool)
        . " WHERE o.shoClass = "
        . $db->quote($shoClass)
        . " GROUP BY o.shoId ORDER BY o.shoTime;";
    emit_text "SQL = $sql" if $DEBUG;
    my $recs = $db->select($sql);

    if ($db->error) {
        $ERR = "Error fetching available show counts list: " . $db->error;
        emit_error {-reason => $ERR} if $DEBUG;
        return [];
    }
    my $shows = [];
    foreach my $rec (@$recs) {
        push @$shows, htx::show->new(-htx => $htx, %$rec);
    }
    $ERR = q{};
    return $shows;
}

# Class-function:
# Return tally of available (for sale, i.e. Idle) tickets, and total loaded tickets,
#   by show, for all pools or only the given pool.  Disregards shoClass.
#   Returns a list of records (arrayref -> hashrefs), NOT a list of show objects.
#   In each hash are also {avail} and {total} that give the number available
#   for sale and the total number of tickets loaded for that show.
#   Note: avail count could be NULL if no tickets exist at all for that show.
sub ticket_tally {
    emit __PACKAGE__ . "::tixtally()" if $DEBUG;
    my %cargs = _c(@_);
    my $htx   = $cargs{htx};              # Required
    my $pool  = $cargs{tixpool} || q{};
    my $db    = $htx->{db};

    my $availsql = $pool ? " AND t.tixPool=" . $db->quote($pool)      : q{};
    my $totalsql = $pool ? "SUM(t.tixPool=" . $db->quote($pool) . ")" : "COUNT(t.shoId)";
    my $sql
        = "SELECT o.shoId,"
        . " SUM(t.tixstate='Idle'$availsql) AS avail,"
        . " $totalsql AS total,"
        . join(q{,}, map {"o.$_"} @COLS)
        . "  FROM shows o"
        . "  LEFT OUTER JOIN tickets t"
        . "    ON t.shoid = o.shoid"
        . " GROUP BY o.shoId ORDER BY o.shoTime;";
    emit_text "SQL = $sql" if $DEBUG;
    my $recs = $db->select($sql);

    if ($db->error) {
        $ERR = "Error fetching ticket tally: " . $db->error;
        emit_error {-reason => $ERR} if $DEBUG;
        return [];
    }
    return $recs;
}

# A show - creates new record in d/b, with a new shoId.
# If shoId is provided, then just creates the object without the database part.
#  $o = new::show->new(htx => $htx, ...)
#  if ($o->error) ...
sub new {
    emit __PACKAGE__ . "::new()" if $DEBUG;
    my $class = shift;
    my %cargs = _c(@_);
    my $this  = {
        err          => q{},
        htx          => $cargs{htx},
        count        => $cargs{count} || 0,     #NOT IN D/B: count of available tickets for the show
        shoId        => $cargs{shoid} || 0,     #int not null unique auto_increment primary key,
        shoTime      => $cargs{shotime} || q{}, #timestamp default 0 comment "When show starts",
        shoSellUntil => $cargs{shoselluntil}
            || q{}
        , #time default "0:20:00" comment "Allowed duration past start of show, before sales close",
        shoClass => $cargs{shoclass} || q{},    #varchar(8) comment "Class of show: REG, VIP, etc",
        shoCost => $cargs{shocost}
            || 0
        , #int not null default 0 comment "unit: cents; Normal cost of this class of show on this date & time",
        shoName => $cargs{shoname} || q{},    #varchar(32) comment "Name of this show"
    };
    bless($this, $class);
    return $this if $this->{shoId};

    my $htx = $this->{htx};
    my $db  = $htx->{db};
    my $sql = "INSERT INTO shows SET "
        . join(q{,}, map {"$_ = " . $db->quote($this->{$_})} @COLS) . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $err = $db->insert($sql);
    if ($db->error) {
        $this->{err} = "Error creating new show record: " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }

    # Get back the show ID
    $this->{shoId} = $db->last_id;
    $this->{err} = "Error getting show ID: " . $db->error if $db->error;
    emit_error {-reason => $this->{err}} if $DEBUG && $this->{err};
    return $this;
}

# Object constructor: Creates new show object, loading info from the database.
#  Sets the error string if the record does not exist:
#    $s = htx::show->load(htx->$htx, shoId => $shoId);
#    if ($s->error) ...
sub load {
    emit __PACKAGE__ . "::load()" if $DEBUG;
    my $class = shift;
    my %cargs = _c(@_);
    my $this  = {
        err   => q{},
        htx   => $cargs{htx},
        shoId => $cargs{shoid} || 0,
    };
    bless($this, $class);

    # Look for the record
    my $htx = $this->{htx};
    my $db  = $htx->{db};
    my $sql
        = "SELECT "
        . join(q{,}, @COLS)
        . " FROM shows WHERE shoId = "
        . $db->quote($this->{shoId}) . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $recs = $db->select($sql);
    if ($db->error) {
        $this->{err} = "Error loading existing show record: " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    if (@$recs != 1) {
        $this->{err} = "Not one show record found for show ID $this->{shoId}";
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    foreach my $k (@COLS) {
        $this->{$k} = $recs->[0]->{$k} || q{};
    }
    return $this;
}

# Save the object out to the database
sub save {
    emit __PACKAGE__ . "::save()" if $DEBUG;
    my $this = shift;
    my $htx  = $this->{htx};
    my $db   = $htx->{db};
    my $sql
        = "UPDATE shows SET "
        . join(q{,}, map {"$_ = " . $db->quote($this->{$_})} @COLS)
        . " WHERE shoId = "
        . $db->quote($this->{shoId}) . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $rec = $db->update($sql);
    if ($db->error) {
        $this->{err} = "Error updating existing sale record: " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    $this->{err} = q{};
    return $this;
}

# Return current error status
sub error {
    my $this = shift;
    return $this->{err};
}

1;
