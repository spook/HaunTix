#=============================================================================
#
# Hauntix Point of Sale - Ticket Object
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use FindBin;

package htx::ticket;
use Date::Manip;
use htx;
use htx::pos_db;
use POSIX qw/strftime/;
use Term::Emit qw/:all/;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
    $TIX_STATE_IDLE
    $TIX_STATE_HELD
    $TIX_STATE_SOLD
    $TIX_STATE_USED
    $TIX_STATE_SWAP
    $TIX_STATE_VOID
    %TIX_RANK_STATE
    $TIX_POOL_BOOTH
    $TIX_POOL_WEB
);

# Ticket states
# TODO:  Handle case of multi-event tickets
our $TIX_STATE_IDLE = 'Idle';    # new, unused, available ticket
our $TIX_STATE_HELD = 'Held';    # temporarily reserved
our $TIX_STATE_SOLD = 'Sold';    # sold to a purchaser
our $TIX_STATE_USED = 'Used';    # used/expired
our $TIX_STATE_SWAP = 'Swap';    # ticket was swapped for another show or upgraded
our $TIX_STATE_VOID = 'Void';    # voided/cancelled

our %TIX_RANK_STATE = (          #Ranking determines who wins when synchronizing
    $TIX_STATE_IDLE => 1,
    $TIX_STATE_HELD => 2,
    $TIX_STATE_SOLD => 3,
    $TIX_STATE_USED => 4,
    $TIX_STATE_SWAP => 5,
    $TIX_STATE_VOID => 9,

);

our $TIX_POOL_BOOTH = 'b';       # Tickets allocated to on-site ticket booth
our $TIX_POOL_WEB   = 'w';       # Tickets alloacted to web-site

our $ERR = q();                  # Error string for factory methods
my @COLS = qw/salId shoId tixCode tixPool tixState tixHoldUntil tixIsPreprinted tixNote tixAnyCostSwap tixAnyDateSwap/;
my $DEBUG = $ENV{'HTX_DEBUG'} || 0;

# Return current error status
sub error {
    my $this = shift;
    return $this->{err};
}

#
# Creates a new ticket object and a new record in the database
#   If a tixId is given, then we do not create the database record.
#
sub new {
    emit __PACKAGE__ . "::new()" if $DEBUG;
    my $class = shift;
    my %cargs = _c(@_);
    my $this  = {
        err   => q{},
        htx   => $cargs{htx},
        sale  => $cargs{sale} || undef,    # related sale object
        show  => $cargs{show} || undef,    # related show object
        tixId => $cargs{tixid}
            || 0,    #int not null unique auto_increment primary key comment "Ticket ID",
        salId   => $cargs{salid}   || 0,                #int comment "Related sale for this ticket",
        shoId   => $cargs{shoid}   || 0,                #int comment "Related show for this ticket",
        tixCode => $cargs{tixcode} || int(rand(10000)), #int comment "Entropy code",
        tixPool => $cargs{tixpool}
            || q{}, #char(1) comment "To which pool is this ticket allocated? (web, booth, etc...)",
        tixState => $cargs{tixstate}
            || $TIX_STATE_IDLE
        , #enum ("Idle", "Held", "Sold", "Used", "Void", "Swap") default "Idle" comment "State of this ticket",
        tixHoldUntil => $cargs{tixholduntil}
            || 0,    #timestamp default 0 comment "When does the hold expire?",
        tixIsPreprinted => $cargs{tixispreprinted}
            || 0,    #boolean default false comment "Is this a preprinted ticket?",
        tixAnyCostSwap => $cargs{tixanycostswap} || 0,    #Ticket may be swapped with any cost level
        tixAnyDateSwap => $cargs{tixanydateswap}
            || 0,    #Ticket may be swapped regardless of show date
        tixNote => $cargs{tixnote}
            || q{},    #varchar(255) comment "Special note associated with this ticket"
    };
    bless($this, $class);
    return $this if $this->{tixId};

    my $htx = $this->{htx};
    my $db  = $htx->{db};
    my $sql = "INSERT INTO tickets SET "
        . join(q{,}, map {"$_ = " . $db->quote($this->{$_})} @COLS) . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $err = $db->insert($sql);
    if ($db->error) {
        $this->{err} = "Error creating new ticket record: " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }

    # Get back the ticket ID
    $this->{tixId} = $db->last_id;
    $this->{err} = "Error getting ticket ID: " . $db->error if $db->error;
    emit_error {-reason => $this->{err}} if $DEBUG && $this->{err};
    return $this;
}

# Object constructor: Loads a new ticket object from the database.
#  Sets the error string if the record does not exist:
#    $tix = htx::ticket->load(htx->$htx, tixId => $tixId);
#    if ($tix->error) ...
sub load {
    emit __PACKAGE__ . "::load()" if $DEBUG;
    my $class = shift;
    my %cargs = _c(@_);
    my $this  = {
        err   => q{},
        htx   => $cargs{htx},
        tixId => $cargs{tixid} || 0,
    };
    bless($this, $class);

    # Look for the record
    my $htx = $this->{htx};
    my $db  = $htx->{db};
    my $sql
        = "SELECT "
        . join(q{,}, @COLS)
        . " FROM tickets WHERE tixId = "
        . $db->quote($this->{tixId}) . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $recs = $db->select($sql);
    if ($db->error) {
        $this->{err} = "Error loading existing ticket record: " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    if (@$recs != 1) {
        $this->{err} = "Not one ticket record found for ticket ID $this->{tixId}";
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    foreach my $k (@COLS) {
        $this->{$k} = $recs->[0]->{$k} || q{};
    }
    return $this;
}

# Multiple Object Constructor:
#  Finds all tickets for the given sale ID, and creates ticket objects for each.
#  Returns a hashref containing an error string, and an arrayref that's
#    the list of ticket objects.  The ticket object list may be empty.
#    $tl = htx::ticket::load_by_sale(-htx => $htx, -salId => $salId);
#    if ($tl->{err}) ...
#    @tickets = @{$tl->{tickets}};
sub load_by_sale {
    emit __PACKAGE__ . "::load()" if $DEBUG;
    my %cargs = _c(@_);
    my $this  = {
        err     => q{},
        htx     => $cargs{htx},
        salId   => $cargs{salid} || 0,
        tickets => [],
    };

    # Look for the records
    my $htx = $this->{htx};
    my $db  = $htx->{db};
    my $sql
        = "SELECT tixId,"
        . join(q{,}, @COLS)
        . " FROM tickets WHERE salId = "
        . $db->quote($this->{salId}) . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $recs = $db->select($sql);
    if ($db->error) {
        $this->{err} = "Error loading ticket records for salId=$this->{salId} : " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }

    # For each ticket record, create a ticket object
    foreach my $rec (@$recs) {
        my $ticket = htx::ticket->new(-htx => $htx, %$rec);
        push @{$this->{tickets}}, $ticket;
    }

    return $this;
}

# Class-wide method:
#  Find any held tickets that are past their hold time, and release 'em
sub release_expired_holds {
    emit __PACKAGE__ . "::release_expired_holds()" if $DEBUG;
    my $htx = shift;
    my $db  = $htx->{db};

    # Return them back to the pool
    my $sql
        = "UPDATE tickets " . "SET "
        . "tixState = "
        . $db->quote($TIX_STATE_IDLE) . q{,}
        . "salId = "
        . $db->quote(undef) . q{,}
        . "tixHoldUntil = "
        . $db->quote(undef)
        . " WHERE tixstate = "
        . $db->quote($TIX_STATE_HELD)
        . "   AND tixHoldUntil < NOW()" . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    $db->update($sql);
    if ($db->error) {
        $ERR = "Error releasing expired holds on tickets: " . $db->error;
        emit_error {-reason => $ERR} if $DEBUG;
        return $ERR;
    }
    return $ERR = q{};
}

# Class-wide method:
# Release all tickets associated with a sale line.
#  Does NOT check if the ticket is voided or already used, etc...
#  Returns the error string, does not set $ERR
sub release_tickets {
    emit __PACKAGE__ . "::release_tickets()" if $DEBUG;
    my ($htx, $salId) = @_;
    my $db = $htx->{db};
    my $sql
        = "UPDATE tickets " . "SET "
        . "tixState = "
        . $db->quote($TIX_STATE_IDLE) . q{,}
        . "salId = "
        . $db->quote(undef) . q{,}
        . "tixHoldUntil = "
        . $db->quote(undef)
        . " WHERE salId = "
        . $db->quote($salId) . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    $db->update($sql);
    if ($db->error) {
        $ERR = "Error releasing tickets: " . $db->error;
        emit_error {-reason => $ERR} if $DEBUG;
        return $ERR;
    }
    return $ERR = q{};
}

# FACTORY METHOD: Create or find ticket(s) and place 'em on hold
# Returns an empty list if the whole chunk of tickets is not available.
#   @tix = htx::ticket::reserve_tickets(-htx=>$htx, -shoId=>$shoId, -salId=>$salId);
sub reserve_tickets {
    emit __PACKAGE__ . "::reserve_tickets()" if $DEBUG;
    my %cargs   = _c(@_);
    my $htx     = $cargs{htx};         # Required - master context
    my $show    = $cargs{show};        # Required
    my $sale    = $cargs{sale};        # Required
    my $qty     = $cargs{qty} || 1;    # Optional - number of tickets to reserve (to hold)
    my $tixPool = $cargs{tixpool}
        || $TIX_POOL_BOOTH;            # Optional - Which ticket pool can we pull from
    $ERR = q{};
    return () unless $qty > 0;

    # First, release any expired holds, incase we need those tix
    release_expired_holds($htx);

    # Try to reserve tickets getting the amount we need.
    #  Then select 'em back by salId, see if we got 'em all.
    #  If not, unhold 'em, and return none.
    #  Else return what we got back on select, after making 'ticket' objects of 'em
    my $db            = $htx->{db};
    my $cfg           = $htx->{cfg};
    my $salId         = $sale->{salId};
    my $shoId         = $show->{shoId};
    my $hold_duration = $cfg->{pos}->{tix_hold_time} || "0 00:13:00";
    my $sql
        = "UPDATE tickets SET "
        . "tixState = "
        . $db->quote($TIX_STATE_HELD) . q{,}
        . "salId = "
        . $db->quote($salId) . q{,}
        . "tixHoldUntil = ADDTIME(NOW(),"
        . $db->quote($hold_duration) . ")"
        . " WHERE tixState = "
        . $db->quote($TIX_STATE_IDLE)
        . "   AND shoId = "
        . $db->quote($shoId)
        . "   AND tixPool = "
        . $db->quote($tixPool)
        . " LIMIT $qty" . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    $db->update($sql);

    if ($db->error) {
        $ERR = "Error holding tickets: " . $db->error;
        emit_error {-reason => $ERR} if $DEBUG;
        return ();
    }
    $sql
        = "SELECT tixId,"
        . join(q{,}, @COLS)
        . "  FROM tickets"
        . " WHERE salId = "
        . $db->quote($salId) . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $recs = $db->select($sql);
    if ($db->error) {
        $ERR = "Error finding held tickets: " . $db->error;
        emit_error {-reason => $ERR} if $DEBUG;
        return ();
    }
    if (@$recs < $qty) {
        my $tmperr = "Unable to get the $qty requested tickets; " . scalar(@$recs) . " available";

        # Return them back to the pool
        my $relerr = release_tickets($htx, $salId);
        $tmperr .= "\nand unable to return tickets to pool: " . $relerr
            if $relerr;
        $ERR = $tmperr;
        emit_error {-reason => $ERR} if $DEBUG;
        return ();
    }

    # Make ticket objects for each record
    my @tix = ();
    foreach my $rec (@$recs) {
        push @tix,
            htx::ticket->new(
            -htx  => $htx,
            -show => $show,
            -sale => $sale,
            %$rec
            );
    }
    return @tix;
}

# Class function: Mark held tickets as sold, by salId
#   htx::ticket::mark_tickets_as_sold($htx, $salId);
sub mark_tickets_as_sold {
    emit __PACKAGE__ . "::mark_tickets_as_sold()" if $DEBUG;
    my ($htx, $salId) = @_;
    my $db = $htx->{db};
    my $sql
        = "UPDATE tickets SET "
        . "tixState = "
        . $db->quote($TIX_STATE_SOLD) . q{,}
        . "tixHoldUntil = "
        . $db->quote(undef)
        . " WHERE tixState = "
        . $db->quote($TIX_STATE_HELD)
        . "   AND salId = "
        . $db->quote($salId) . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    $db->update($sql);
    if ($db->error) {
        $ERR = "Error marking tickets as sold: " . $db->error;
        emit_error {-reason => $ERR} if $DEBUG;
        return $ERR;
    }
    return $ERR = q{};
}

# Save the object out to the database
sub save {
    emit __PACKAGE__ . "::save()" if $DEBUG;
    my $this = shift;
    my $htx  = $this->{htx};
    my $db   = $htx->{db};
    my $sql
        = "UPDATE tickets SET "
        . join(q{,}, map {"$_ = " . $db->quote($this->{$_})} @COLS)
        . " WHERE tixId = "
        . $db->quote($this->{tixId}) . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $rec = $db->update($sql);
    if ($db->error) {
        $this->{err} = "Error updating existing ticket record: " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    $this->{err} = q{};
    return $this;
}

# Class function
# Make the ticket number from the id and code.
#  See untixno for the reverse.
sub mktixno {
    my ($id, $code) = @_;
    return sprintf "%d%4.4d", $id, $code;
}

# Object funtion - return the ticket number for the given ticket object
sub tixno {
    my $this = shift;
    return mktixno($this->{tixId}, $this->{tixCode});
}

# Class function
# Get the ticket id and code from a ticket number.
#  Returns (undef, undef) if invalid.
#  See mktixno for the reverse.
sub untixno {
    my ($num) = @_;
    return ($1, $2) if $num =~ m{^(\d+?)-?(\d{4})$};
    return (undef, undef);
}

# Print this ticket
sub print_ticket {
    my $this = shift;
    my $htx  = $this->{htx};
    my $cfg  = $htx->{cfg};

    # Ticket printing enabled?
    my $enabled = $cfg->{pos}->{ticket_print_enabled};
    return if !$enabled;

    # Split by formatter
    my $format = $cfg->{pos}->{ticket_print_format};
    if ($format eq "T055020") {

        # 5.5" x 2" stock
        $this->print_ticket_T055020();
    }
    else {

        # Default (receipt) format
        $this->print_ticket_default_format();
    }
}

# Use this format for Datamax ticket printers (real tickets)
sub print_ticket_T055020 {
    ### TODO:  *** Restructure this to a format/driver model
    ### TODO: Error handling

    my $this    = shift;
    my $htx     = $this->{htx};
    my $cfg     = $htx->{cfg};
    my $enabled = $cfg->{pos}->{ticket_print_enabled};
    my $queue   = $cfg->{pos}->{ticket_print_queue};

    # Load the appropriate driver
    my $drvnam = $cfg->{pos}->{ticket_print_driver} || "drv_dpl";
    my $drvpth = "htx/$drvnam.pm";
    require $drvpth;
    my $drvmod = "htx::$drvnam";
    my $drv = $this->{drv} = $drvmod->new;
    $drv->queue($queue);

    # Get info
    my $intro   = $cfg->{haunt}->{intro}            || q{};
    my $name    = $cfg->{haunt}->{name}             || 'Haunted House';
    my $desc    = $cfg->{haunt}->{desc}             || q{};
    my $slogan  = $cfg->{haunt}->{slogan}           || q{};
    my $site    = $cfg->{haunt}->{site}             || q{};
    my $website = $cfg->{haunt}->{website}          || q{};
    my $addr0   = $cfg->{haunt}->{addr0}            || q{};
    my $addr1   = $cfg->{haunt}->{addr1}            || q{};
    my $addr2   = $cfg->{haunt}->{addr2}            || q{};
    my $rftype  = $cfg->{haunt}->{refund_type}      || q{};
    my $rfstmt  = $cfg->{haunt}->{refund_statement} || q{};
    my $apolicy 
        = $this->{tixNote}
        || $cfg->{haunt}->{arrival_policy}
        || q{Please arrive 5 minutes early.};
    my $ticnum  = sprintf '%10.10d', mktixno($this->{tixId}, $this->{tixCode});
    my $sale    = $this->{sale};
    my $show    = $this->{show};
    my $salName = $sale->{salName};
    my $tclass  = $show->{shoClass};

    my $trnId = $sale->{trnId};
    my $when1
        = $sale->{salIsTimed} ? UnixDate($show->{shoTime}, q{%a %d-%b-%Y %H:%M})
        : $sale->{salIsDaily} ? UnixDate($show->{shoTime}, q{%a %d-%b-%Y})
        :                       $salName;
    $when1 =~ s/AM$/a/;
    $when1 =~ s/PM$/p/;
    my $when2
        = $sale->{salIsTimed} ? UnixDate($show->{shoTime}, q{%I:%M%p %a - %d %b})
        : $sale->{salIsDaily} ? UnixDate($show->{shoTime}, q{%a %d %b}) . " - $tclass"
        :                       $salName;
    $when2 =~ s/^0//g;
    ###$when2 =~ s/\s0//g;
    $when2 =~ s/AM/am/;
    $when2 =~ s/PM/pm/;

    # Reset the printer
    $drv->reset;

    # Body
    $drv->cmd("1X11" . "000" . "0510" . "0001" . "L195021");    # Black bar
    $drv->cmd("1311000" . "0514" . "0050" . "Admit One $tclass");
    $drv->cmd("1911A12" . "0485" . "0005" . $when1);
    $drv->cmd("1X11" . "000" . "0460" . "0001" . "L195021");    # Black bar
    $drv->cmd("1311000" . "0463" . "0047" . $rftype);

    $drv->cmd("1111000" . "0452" . "0047" . "HaunTix $htx::HTX_VERSION TID$trnId");

    $drv->cmd("2911A08" . "0437" . "0170" . $intro);
    $drv->cmd("2911A24" . "0430" . "0130" . $name);
    $drv->cmd("2911A10" . "0413" . "0117" . $desc);
    $drv->cmd("2911A18" . "0433" . "0085" . $when2);
    $drv->cmd("2911A10" . "0413" . "0068" . $apolicy);
    $drv->cmd("2911A10" . "0400" . "0043" . $addr0);
    $drv->cmd("2911A12" . "0407" . "0025" . $website);
    $drv->cmd("2911A08" . "0421" . "0007" . $rfstmt);

    $drv->cmd("1911A08" . "0177" . "0031" . "VIP - VIP - VIP - VIP - VIP")
        if $tclass eq 'VIP';
    $drv->cmd("1e00047" . "0130" . "0025" . $ticnum);    # Barcode
    $drv->cmd("1311000" . "0113" . "0050" . $ticnum);    # HRI

    $drv->cmd("1X11" . "000" . "0100" . "0001" . "B188350007007");   # Box wid hgt thk-t/b thk-sides

    # Stub
    $drv->cmd("1X11" . "000" . "0074" . "0001" . "L190024");         # Black Bar L wid hgt
    $drv->cmd("1911A12" . "0075" . "0005" . $when1);
    $drv->cmd("1e00030" . "0040" . "0025" . $ticnum);                # Barcode
    $drv->cmd("1211000" . "0028" . "0070" . $ticnum);                # HRI
    $drv->cmd("1X11" . "000" . "0003" . "0001" . "L195021");         # Black bar
    $drv->cmd("1311000" . "0007" . "0050" . "Admit One $tclass");

    # Page cut and submit
    $drv->feed_and_cut;
    $drv->submit;
}

# Use this format to print on a receipt printer, for example
sub print_ticket_format_default {
    my $this    = shift;
    my $htx     = $this->{htx};
    my $cfg     = $htx->{cfg};
    my $enabled = $cfg->{pos}->{ticket_print_enabled};
    my $queue   = $cfg->{pos}->{ticket_print_queue};

    # Load the appropriate driver
    my $drvnam = $cfg->{pos}->{ticket_print_driver} || "drv_epson_tm88";
    my $drvpth = "htx/$drvnam.pm";
    require $drvpth;
    my $drvmod = "htx::$drvnam";
    my $drv = $this->{drv} = $drvmod->new;
    $drv->queue($queue);

    # Reset the printer
    $drv->reset;

    # Ticket header
    $drv->say("      ADMIT ONE      ", 'rev,wide');
    $drv->say($this->{sal}->{salName}, 'wide,center');
    $drv->say("  GENERAL ADMISSION  ", 'rev,wide');      ### TODO: date or GA
    $drv->say("Non-Refundable",        'wide,center');
    $drv->say(q{ } x 42,               'rev');

    # Ticket midsection
    my $name   = $cfg->{haunt}->{name}   || 'Haunted House';
    my $slogan = $cfg->{haunt}->{slogan} || q{};
    my $site   = $cfg->{haunt}->{site}   || q{};
    my $addr1  = $cfg->{haunt}->{addr1}  || q{};
    my $addr2  = $cfg->{haunt}->{addr2}  || q{};
    $drv->say(_nl($name),   'tall,wide,center');
    $drv->say(_nl($slogan), 'wide,tiny,bold,center') if $slogan;
    $drv->say(_nl($site),   'center') if $site;
    $drv->say(_nl($addr1),  'center') if $addr1;
    $drv->say(_nl($addr2),  'center') if $addr2;

    my $ticnum = mktixno($this->{tixId}, $this->{tixCode});
    $drv->say($this->{sal}->{salName}, 'tall,wide,center');
    $drv->say("#$ticnum",              'wide,center');
    my $bc12 = sprintf("%12.12d", $ticnum);
    my $date = strftime("%a %d-%b-%Y %H:%M:%S %Z", localtime(time()));  # TODO: Use transaction date
    $drv->say($date, 'tiny,center');
    $drv->barcode($bc12, 'center');
    $drv->say(q{ } x 42, 'rev');

    # Tearoff line
    $drv->say;
    $drv->say("---------cut---------", 'wide');
    $drv->say;

    # Stub
    $drv->say("      ADMIT ONE      ", 'rev,wide');
    $drv->say(_nl($name),              'wide,center');
    $drv->say($this->{sal}->{salName}, 'wide,center');
    $drv->barcode($bc12, 'center');
    $drv->say(q{ } x 42, 'rev');

    # Page cut and submit
    $drv->feed_and_cut;
    $drv->submit;
}

sub TO_JSON {
    my $this = shift;
    my $o    = {};
    foreach my $k (keys %$this) {
        $o->{$k} = $this->{$k} if $k =~ m/^tix/ || $k =~ m/Id$/;
    }
    return $o;
}

1;

