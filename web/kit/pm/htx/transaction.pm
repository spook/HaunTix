#=============================================================================
#
# Hauntix Point of Sale - Transaction Object
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

package htx::transaction;
use htx;
use htx::charge;
use htx::pos_db;
use htx::pos_rcpt;
use htx::sale;
use htx::ticket;
use POSIX qw/strftime/;
use Term::Emit qw/:all/;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
    fmtpickup
    unpickup
    $TRN_PHASE_NEW
    $TRN_PHASE_OPN
    $TRN_PHASE_PAY
    $TRN_PHASE_XCL
    $TRN_PHASE_VYD
    $TRN_PHASE_FIN
    @TRN_STATIONS_WEB);

#
# Design note: Transaction phases
#   Rational for a "Pay" phase - I've got a separate Payment phase because
#   if the transaction gets cancelled, we've got to return some money.
#   If cash or a check, that's easy, we do a popup and tell the agent to
#   return XX dollars or the check.  But if credit card(s), we need to
#   invokereturn processing on the card(s).  So that's why.
#
our $TRN_PHASE_NEW = 'n';    # New, unstarted transaction
our $TRN_PHASE_OPN = 'o';    # Open transaction - ringing up sales
our $TRN_PHASE_PAY = 'p';    # Payment phase of transaction
our $TRN_PHASE_XCL = 'x';    # Cancelled before completion
our $TRN_PHASE_VYD = 'v';    # Voided after completion
our $TRN_PHASE_FIN = 'z';    # Completed transaction

our @TRN_STATIONS_WEB = (qw/W X Y Z/);    # Station codes for web sales

my @COLS = qw/trnPhase trnUser trnMod trnStation
    trnCashAmount trnCheckAmount trnCheckInfo
    trnTaxAmount trnTaxRate trnServiceCharge trnPickupCode
    trnRemoteAddr trnEmail trnNote/;
my @CIAS = qw/trnId trnTimestamp/;        # columns indexed or auto's
my $DEBUG = $ENV{'HTX_DEBUG'} || 0;

#
# Creates a new transaction object and corresponding record in the database.
#   If a trnId is given, only the object is created, without the database.
#   my $trn = htx::transaction->new(-htx => $htx);
#
sub new {
    emit __PACKAGE__ . "::new()" if $DEBUG;
    my $class = shift;
    my %cargs = _c(@_);
    my $htx   = $cargs{htx};                        # Required
    my $stn   = $htx->{cfg}->{pos}->{station_id};
    my $this  = {
        err     => q{},
        htx     => $htx,
        sales   => [],                              # List of items sold (sale objects)
        tickets => [],                              # List of tickets sold (ticket objects)
        charges => [],                              # Credit/debit charges (charge objects)
        #<<<
        trnId            => $cargs{trnid}            || 0,        # Unique transaction ID
        trnTimestamp     => $cargs{trntimestamp}     || 0,        # When the transaction happened
        trnPhase         => $cargs{trnphase}         || $TRN_PHASE_NEW,       # char(1) comment "Disposition phase: new, open, pay, final or x-cancelled"
        trnUser          => $cargs{trnuser}          || $ENV{USER} || q{},    # varchar(32) comment "cashier who did this transaction"
        trnMod           => $cargs{trnmod}           || $ENV{HTX_MOD} || q{}, # varchar(32) comment "manager on duty"
        trnStation       => $cargs{trnstation}       || $stn || q{},          # char(1) comment "Station ID"
        trnCashAmount    => $cargs{trncashamount}    || 0,        # int not null default 0 comment "Cash amount, unit:cents"
        trnCheckAmount   => $cargs{trncheckamount}   || 0,        # Units are cents
        trnCheckInfo     => $cargs{trncheckinfo}     || q{},      # Misc check info
        trnTaxAmount     => $cargs{trntaxamount}     || 0,        # int not null default 0 comment "Sales tax paid on the transaction, units:cents"
        trnTaxRate       => $cargs{trntaxrate}       || 0,        # decimal(7,6) default 0 comment "Tax rate in effect, 0.074000 = 7.4%"
        trnServiceCharge => $cargs{trnservicecharge} || 0,        # int not null default 0 comment "Service charge amount, units: cents"
        trnPickupCode    => $cargs{trnpickupcode}    || mkpickup(), # int null unique comment "Pickup code for the items in this transaction"
        trnRemoteAddr    => $cargs{trnremoteaddr}    || q{},      # IP addr of web customer
        trnEmail         => $cargs{trnemail}         || q{},      # varchar(255) comment "email address for this transaction"
        trnNote          => $cargs{trnnote}          || q{},      # varchar(255) comment "Special note associated with this transaction"
        #>>>
        subtotal => 0,    # Units are cents
        total    => 0,    # Units are cents
        change   => 0,    # Units are cents
        cc_tally => 0,    # Credit/debit card totals (cents)
        prdcount => 0,    # Number of products sold
        upgcount => 0,    # Number of upgrades sold
        dsccount => 0,    # Number of discounts sold
        fullcomp => 0,    # Doing a full comp, allow 0-paid amount
    };
    bless($this, $class);
    return $this if $this->{trnId};

    my $db  = $htx->{db};
    my $sql = "INSERT INTO transactions SET "
        . join(q{,}, map {"$_ = " . $db->quote($this->{$_})} @COLS) . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    $db->insert($sql);
    if ($db->error) {
        $this->{err} = "Error creating new transaction record: " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }

    # Get back the ID
    $this->{trnId} = $db->last_id;
    $this->{err} = "Error getting transaction ID: " . $db->error if $db->error;
    emit_error {-reason => $this->{err}} if $DEBUG && $this->{err};

    # Initial phase change events
    $this->phase_change(undef);
    return $this;
}

# Object constructor: Creates a new transaction object, loading info from the database.
#  Loads in sales, ticket, and charge objects too.
#  Sets the error string if the record does not exist.
#    $t = htx::transaction->load(-htx => $htx, -trnId => $trnId);
#    if ($t->error) ...
sub load {
    emit __PACKAGE__ . "::load()" if $DEBUG;
    my $class = shift;
    my %cargs = _c(@_);
    my $this  = htx::transaction->new(
        -htx   => $cargs{htx},
        -trnId => $cargs{trnid} || 0
    );

    # Look for the record
    my $htx = $this->{htx};
    my $db  = $htx->{db};
    my $sql
        = "SELECT "
        . join(q{,}, (@COLS, @CIAS))
        . " FROM transactions WHERE trnId = "
        . $db->quote($this->{trnId}) . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $recs = $db->select($sql);
    if ($db->error) {
        $this->{err} = "Error loading existing transaction record: " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    if (@$recs == 0) {
        $this->{err} = "Transaction #$this->{trnId} not found";
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    if (@$recs > 1) {
        $this->{err} = "Multiple transaction #$this->{trnId} records found";
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    foreach my $k (@COLS, @CIAS) {
        $this->{$k} = $recs->[0]->{$k};
    }

    # Load all sale records for this transaction
    my $sl = htx::sale::load_by_transaction(-htx => $htx, -trnId => $this->{trnId});
    if ($sl->{err}) {
        $this->{err} = $sl->{err};
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    $this->{sales} = $sl->{sales};

    # Accumulate the tickets for each sale
    foreach my $sale (@{$this->{sales}}) {
        push @{$this->{tickets}}, @{$sale->{tickets}};
    }

    # Load all charges
    my $cl = htx::charge::load_by_transaction(-htx => $htx, -trnId => $this->{trnId});
    if ($cl->{err}) {
        $this->{err} = $cl->{err};
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    $this->{charges} = $cl->{charges};

    $this->retally;
    $this->phase_check;
    return $this;
}

#
# Add an item to this transaction's sales
#   Auto correlates similar items
sub add_item {
    emit __PACKAGE__ . "::add_item()" if $DEBUG;
    my ($this, $item, $qty) = @_;
    my $htx = $this->{htx};
    $item->{trnId} = $this->{trnId};

    # Existing sale? adding more of same?
    foreach my $sale (@{$this->{sales}}) {

        if (   $sale->{salType} eq $item->{itmType}
            && $sale->{salName} eq $item->{itmName}
            && $sale->{salCost} == $item->{itmCost}
            && $sale->{salPaid} == $item->{itmCost}
            && (!$item->{itmIsTicket}    # not a ticket?
                || (!$sale->{show} && !$item->{show})    # both pre-purchased tickets?
                || (   $sale->{show}
                    && $item->{show}
                    && $sale->{show}->{shoId} == $item->{show}->{shoId})
            )
            )
        {

            # Get more tickets - note: we get back the new total list, not just the added ones
            if ($item->{itmIsTicket} && $item->{show}) {
                my @tix = htx::ticket::reserve_tickets(
                    -htx     => $htx,
                    -sale    => $sale,
                    -show    => $item->{show},
                    -tixPool => $item->{tixPool},
                    -qty     => $qty
                );
                if ($htx::ticket::ERR
                    || (@tix != ($sale->{salQuantity} + $qty)))
                {
                    $this->{err}
                        = "Error reserving more tickets: "
                        . ($htx::ticket::ERR
                            || "quantity mismatch, want $sale->{salQuantity}+$qty, got "
                            . (0 + @tix));
                    emit_error {-reason => $this->{err}} if $DEBUG;
                    return $this->{err};
                }

                # add only the new ones to the existing list
                my @newtix = ();
            OLD: foreach my $ntix (@tix) {
                    foreach my $otix (@{$this->{tickets}}) {
                        next OLD if $otix->{tixId} == $ntix->{tixId};
                    }
                    push @newtix, $ntix;
                }
                push @{$this->{tickets}}, @newtix;
            }

            # If a percentage discount, ...
            if (0) { }    ### TODO: what do we do here?

            # Update the quantity
            $sale->{salQuantity} += $qty;
            $sale->save;
            if ($sale->error) {
                $this->{err} = "Error updating sale item quantity: " . $sale->error;
                emit_error {-reason => $this->{err}} if $DEBUG;
                return $this->{err};
            }
            $this->retally;
            $this->phase_check;
            return $this->{err} = q{};
        }
    }

    # If a percentage discount, calculate credit paid
    if (($item->{itmType} eq "dsc") && ($item->{itmMethod} eq "Percent")) {    # PercentSubtotal
        $qty = 1;
        $item->{itmPaid} = int($item->{itmCost} / 10000 * $this->subtotal() - 0.5);
    }

    # If a fixed discount, set paid amount
    if (($item->{itmType} eq "dsc") && ($item->{itmMethod} eq "FixedAmount")) {
        $item->{itmPaid} = $item->{itmCost};
    }

    # New sale
    my $sale = htx::sale->new(
        -htx          => $htx,
        -trnId        => $item->{trnId},
        -show         => $item->{show},
        -salType      => $item->{itmType},
        -salName      => $item->{itmName},
        -salCost      => $item->{itmCost},
        -salPaid      => $item->{itmPaid} || $item->{itmCost},
        -salIsTaxable => $item->{itmIsTaxable},
        -salIsTicket  => $item->{itmIsTicket},
        -salIsTimed   => $item->{itmIsTimed},
        -salIsDaily   => $item->{itmIsDaily},
        -salQuantity  => $qty,
    );
    push @{$this->{sales}}, $sale;
### TODO:  Design idea -- Link the sale to a future 'item' object, leaving cost & quantity here

    # If a ticket, and show selected, reserve the requested quantity
    if ($item->{itmIsTicket} && $item->{show}) {
        my @tix = htx::ticket::reserve_tickets(
            -htx     => $htx,
            -sale    => $sale,
            -show    => $item->{show},
            -tixPool => $item->{tixPool},
            -qty     => $qty
        );
        if ($htx::ticket::ERR || (@tix != $qty)) {
            # Remove sale from internal list and from database
            pop @{$this->{sales}};  # discard it
            $sale->nuke();

            $this->{err} = "Error reserving tickets (shoId=$item->{show}->{shoId}): "
                . ($htx::ticket::ERR || "quantity mismatch, want $qty, got " . (0 + @tix));
            emit_error {-reason => $this->{err}} if $DEBUG;
            return $this->{err};
        }
        push @{$this->{tickets}}, @tix;
    }

    # refresh things
    $this->retally();
    $this->phase_check;
    return $this->{err} = q{};
}

# Cancel this transaction entirely
### WORKING HERE
sub cancel {
    my $this = shift;
    my $htx = $this->{htx};

    # If already cancelled, just return
    return $this->{err} = q{} if $this->{trnPhase} eq $TRN_PHASE_XCL;

    # Have any of the tickes for this transaction been used, voided, etc?
    foreach my $tix (@{$this->{tickets}}) {
        return $this->{err} = "Some tickets already sold/used/voided; cannot cancel"
        if ($tix->{tixState} ne $TIX_STATE_IDLE) &&
           ($tix->{tixState} ne $TIX_STATE_HELD);
    }

    # Mark transaction as cancelled
    $this->{trnPhase} = $TRN_PHASE_XCL;

    # Release hold on tickets
    foreach my $sale (@{$this->{sales}}) {
        next unless $sale->{salIsTicket};
        my $err = htx::ticket::release_tickets($htx, $sale->{salId});
        if ($err) {
            return $this->{err} = "Could not release ticket hold: $err";
        }
    }

    # Refund any charges
    foreach my $crg (@{$this->{charges}}) {
        my $rfd = htx::charge->new($htx);    # Refund object

        $rfd->trnid($this->trnid);
        $rfd->type("Refund");
        $rfd->track($crg->track);
        $rfd->acct($crg->acct);
        $rfd->ccv($crg->ccv);
        $rfd->expdate($crg->expdate);
        $rfd->comment("Cancel transaction $this->{trnId}");
        $rfd->amount_requested($crg->amount_charged);


### TODO:  Do htx::cc::refund_keyed or refund_swiped, don't use the CLI since this goes in a history buffer!
        my $amt = dol($crg->amount_charged);    # In simple dollar format 1.23
        my $cmd
            = $crg->track
           ? "htx-ccproc refund -t '" . $crg->track . "' $amt"
            : "htx-ccproc refund -a '" . $crg->acct
                        . "' -c '" . $crg->ccv
                        . "' -e '" . $crg->expdate
                        . "' $amt";
#        my $out = qx($cmd 2>&1);    # This will pause
    ### TEST:    print "\nRefund says:\n$out\n";
#        $rfd->parse_proc($out);
#        my $err = $rfd->save;
#        $f->Label(-text=>"Unable to save record of refund: $err",
#                -font=>$FONT_SM,
#                -fg => $COLOR_RED)->pack
#            if $err;
        my $ctid = $rfd->{chgTransactionID};
        my $rcode = $rfd->rcode;
        my $rdesc = $rfd->rdesc;
        if ($rcode eq "000") {
            ##$f->Label(-text=>"Refund $rdesc \#$ctid",
            ### Good!  
        }



    }

    # Save/update the transaction record
    return $this->save;
}


sub cash {
    my ($this, $amt) = @_;
    if (defined $amt) {
        $this->{trnCashAmount} += $amt;
        $this->retally;
        $this->phase_check;
    }
    return $this->{trnCashAmount};
}

# Adds charge object to list, or returns total of charges
sub cc {
    my ($this, $crg) = @_;
    if (defined $crg) {
        push @{$this->{charges}}, $crg;
        $this->retally;
        $this->phase_check;
    }
    return $this->{cc_tally};
}

# Returns list of charges
sub charges {
    my $this = shift;
    return @{$this->{charges}};
}

sub check {
    my ($this, $amt) = @_;
    if (defined $amt) {
        $this->{trnCheckAmount} += $amt;
        $this->retally;
        $this->phase_check;
    }
    return $this->{trnCheckAmount};
}

sub checkinfo {
    my ($this, $info) = @_;
    $this->{trnCheckInfo} = $info if defined $info;
    return $this->{trnCheckInfo};
}

# Returns change due (negative means amount still owed)
sub change {
    my $this = shift;
    return $this->{change};
}

# Record final transaction to database
#  - Finalizes transaction
#  - Updates all database records: sales, tickets, transaction
#  - Loads timestamp and transaction ID, for receipt printing, etc...
sub complete {
    emit __PACKAGE__ . "::complete()" if $DEBUG;
    my $this = shift;
    my $htx  = $this->{htx};
    my $cfg  = $htx->{cfg};

    # Note: Charge records are written when the cc processing goes thru; no update needed here

    # Sales records
    foreach my $sale ($this->sales) {
        $sale->save;
        return $this->{err} = "Error updating sale: " . $sale->error if $sale->error;
        my $err = htx::ticket::mark_tickets_as_sold($htx, $sale->{salId});
        return $this->{err} = "Error marking tickes as sold: $err" if $err;
    }

    # Transaction record
    $this->save;
    return $this->{err} = "Unable to save transaction: " . $this->error
        if $this->error;

### TODO:  This should not be here - move it out
    # Print the ticket(s)
    foreach my $tic ($this->tickets) {
        $tic->print_ticket;
    }

### TODO:  This should not be here - move it out
    # Print the receipt, except if cash only
    if ($cfg->{pos}->{receipt_print_if_cash_only}
        || $this->check
        || $this->cc) {
        my $rct = new htx::pos_rcpt($htx, $this);
        $rct->print_receipt;
    }

    # Sound
### TODO:  This should not be here - move it out
    system("aplay -q $cfg->{sound}->{trn_complete} &")
        if $cfg->{sound}->{enabled}
            && -r $cfg->{sound}->{trn_complete};
}

# Return error string
sub error {
    my $this = shift;
    return $this->{err};
}

# Find transactions meeting the given criteria.
#   Returns a list of transaction id's for matching records
#   Call with a set of criteria; each is a field given as:
#       field => scalar value
#       field => [arrayref of acceptable values],
#       field => {low => hi} hashref range(s), undef for unbounded lo or hi
#   Example:  trnId => {1234 => undef}  All trnId's greater or equal to 1234
#   All criteria must be met (they're AND'd)
sub find {
    emit __PACKAGE__ . "::find()" if $DEBUG;
    my $this  = shift;
    my $htx   = $this->{htx};
    my $db    = $htx->{db};
    my %cargs = _c(@_);

    # Process args into WHERE clause
    my @wc = ();
    foreach my $col (@COLS, @CIAS) {
        next if !exists $cargs{lc $col};
        my $val = $cargs{lc $col};
        if (ref($val) eq q{}) {

            # Single scalar value
            push @wc, $col . '=' . $db->quote($val);
        }
        elsif (ref($val) eq 'ARRAY') {

            # List of values
            push @wc, $col . ' IN (' . join(',', map {$db->quote($_)} @$val) . ')';
        }
        elsif (ref($val) eq 'HASH') {

            # (list of) low/high bounds
            foreach my $lo (keys %$val) {
                my $hi = $val->{$lo};
                push @wc, $col . '>=' . $db->quote($lo) if defined $lo;
                push @wc, $col . '<=' . $db->quote($hi) if defined $hi;
            }
        }
    }
    my $where_clause = join(' AND ', @wc);

    # Look for the record
    my $sql = "SELECT trnId FROM transactions WHERE $where_clause;";
    emit_text "SQL = $sql" if $DEBUG;
    $this->{_sql} = $sql;    # For testing
    my $recs = $db->select($sql);
    if ($db->error) {
        $this->{err} = "Error finding transaction records: " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    return map {$_->{trnId}} @$recs;
}

# Full-comp flag get/set
sub fullcomp {
    my ($this, $flag) = @_;
    $this->{fullcomp} = $flag
        if defined $flag;
    return $this->{fullcomp};
}

# Return the formatted pickup code XXXX-XXXXX (trnId-trnPickupCode)
sub fmtpickup {
    my $this = shift;
    return sprintf '%d-%5.5d', $this->{trnId}, $this->{trnPickupCode};
}

# Make a pickup code
sub mkpickup {
    return 1 + int(rand(99999));
}

# Returns the amount owed (still to pay)
sub owed {
    my $this = shift;
    return -$this->{change};
}

# Returns the amount paid so far
sub paid {
    my $this = shift;
    return $this->{change} + $this->{total};
}

#
# Set or get the current phase
#
### TODO: hook in phase_change here too, or disallow it to change, only return
sub phase {
    my ($this, $phase) = @_;
    $this->{trnPhase} = $phase if defined $phase;
    return $this->{trnPhase};
}

sub phase_name {
    my $this = shift;
    return $this->{trnPhase} eq $TRN_PHASE_NEW? 'New'
         : $this->{trnPhase} eq $TRN_PHASE_OPN? 'Open'
         : $this->{trnPhase} eq $TRN_PHASE_PAY? 'Paying'
         : $this->{trnPhase} eq $TRN_PHASE_FIN? 'Complete'
         : $this->{trnPhase} eq $TRN_PHASE_XCL? 'Canceled'
         : $this->{trnPhase} eq $TRN_PHASE_VYD? 'Void'
         : '-unknown-';
}


# Event processing when the transaction phase changes
sub phase_change {
    my ($this, $old_phase) = @_;
    my $htx  = $this->{htx};
    my $cfg  = $htx->{cfg};
    my $mw   = $htx->{mw};
    my $trn  = $htx->{trn};
    my $nums = $htx->{nums};
    my $itms = $htx->{itms};
    my $pays = $htx->{pays};
    my $bill = $htx->{bill};
    my $func = $htx->{func};

    # my $old = $old_phase || '-';  #TEMP
    # print "Phase change from $old to $this->{trnPhase}\n"; ### TEMP
    if ($this->{trnPhase} eq $TRN_PHASE_NEW) {
### TODO:  tax rate shouldn't come from {pos}, what about web sales?
        $this->{trnTaxRate} = $cfg->{pos}->{tax_rate};
    }
    elsif ($this->{trnPhase} eq $TRN_PHASE_OPN) {
    }
    elsif ($this->{trnPhase} eq $TRN_PHASE_PAY) {
    }
    elsif ($this->{trnPhase} eq $TRN_PHASE_XCL) {
    }
    elsif ($this->{trnPhase} eq $TRN_PHASE_FIN) {

        # Complete the transaction
        $this->complete;
    }
    else {
        die "\n*** Yikes! Bad transaction phase: <$this->{trnPhase}>\n"
            . "  * I must die, this is too messed up!\n";
    }
}

# What phase are we in now?  Do we need to change phases?
sub phase_check {
    my $this      = shift;
    my $old_phase = $this->{trnPhase};
    return $old_phase if $old_phase eq $TRN_PHASE_FIN; # Final is final
    $this->{trnPhase}
        = (($this->paid() > 0) || $this->fullcomp()) && ($this->owed() <= 0) ? $TRN_PHASE_FIN
        : (($this->paid() > 0) || $this->fullcomp()) ? $TRN_PHASE_PAY
        : @{$this->{sales}} ? $TRN_PHASE_OPN
        :                     $TRN_PHASE_NEW;
    $this->phase_change($old_phase)
        if $this->{trnPhase} ne $old_phase;
    return $this->{trnPhase};
}

# Set remote ip address
sub remote_addr {
    my ($this, $ip) = @_;
    $this->{trnRemoteAddr} = $ip if defined $ip;
    return $this->{trnRemoteAddr};
}

# Remove a sale item.  $i is index, one-based
sub remove_item {
    my ($this, $i) = @_;
    my $htx = $this->{htx};
    return if $i < 1 || $i > @{$this->{sales}};

    my $sale  = $this->{sales}->[$i - 1];
    my $salId = $sale->{salId};
    if ($sale->{salIsTicket} && $sale->{show}) {

        # Remove tickets from transaction's convienence list
        my @newtix = ();
        foreach my $tix (@{$this->{tickets}}) {
            push @newtix, $tix if $tix->{salId} != $salId;
        }
        $this->{tickets} = \@newtix;

        # Release hold on tickets
        my $err = htx::ticket::release_tickets($htx, $salId);
        if ($err) {
            ### TODO: Error popup somehow
            print STDERR "*** remove_item(): $err\n";
            return $err;
        }
    }

    # Remove sale line from list
    my @newlist = @{$this->{sales}};
    @newlist = @newlist[0 .. $i - 2, $i .. $#newlist];
    $this->{sales} = \@newlist;

    $this->retally;    ### TODO: Discounts must be rechecked for validity
    $this->phase_check;
    return q{};
}

# Redo taxes, service fees, and totals
sub retally {
    my $this = shift;

    # Recalculate automatic discounts

    # Add 'em up
    $this->{prdcount} = 0;
    $this->{upgcount} = 0;
    $this->{dsccount} = 0;
    $this->{subtotal} = 0;
    $this->{taxtotal} = 0;
    foreach my $sale (@{$this->{sales}}) {
        $this->{prdcount} += $sale->{salQuantity}
            if $sale->{salType} eq $SALE_TYPE_PRODUCT;
        $this->{upgcount} += $sale->{salQuantity}
            if $sale->{salType} eq $SALE_TYPE_UPGRADE;
        $this->{dsccount} += $sale->{salQuantity}
            if $sale->{salType} eq $SALE_TYPE_DISCOUNT;
        $this->{subtotal} += $sale->{salQuantity} * $sale->{salPaid};
        $this->{taxtotal} += $sale->{salQuantity} * $sale->{salPaid}
            if $sale->{salIsTaxable};
    }
    $this->{trnTaxAmount} = int($this->{taxtotal} * $this->{trnTaxRate} + 0.5);
    $this->{total}        = $this->{subtotal} + $this->{trnServiceCharge} + $this->{trnTaxAmount};

    # Add up payments
    $this->{cc_tally} = 0;
    foreach my $chg (@{$this->{charges}}) {    ### TODO: use accessor fn's on $chg
        $this->{cc_tally} += $chg->amount_charged
            if $chg->{chgType} eq "Charge"
                && $chg->rcode == 0;           ### TODO: is it "000" or 0 or ???
        $this->{cc_tally} -= $chg->amount_charged
            if $chg->{chgType} eq "Refund"
                && $chg->rcode == 0;
    }

    my $pmt = $this->{trnCashAmount} + $this->{trnCheckAmount} + $this->{cc_tally};
    $this->{change} = $pmt - $this->{total};
### TEST
    if (0) {
        print "\nTransaction tally:\n";
        print "  Subtotal \t$this->{subtotal}\n";
        print "  Tax Amount \t$this->{trnTaxAmount}\n";
        print "  Service Charge \t$this->{trnServiceCharge}\n";
        print "  Cash Amount\t$this->{trnCashAmount}\n";
        print "  Check Amount\t$this->{trnCheckAmount}\n";
        print "  CC Amounts (" . scalar(@{$this->{charges}}) . "):\n";
        foreach my $chg (@{$this->{charges}}) {
            print
                "    $chg->{chgType} $chg->{chgResponseCode} APV=$chg->{chgApprovalCode} Amt=$chg->{chgAmount}\n";
        }
        print "  Total    \t$this->{total}\n";
        print "  Change/owed\t$this->{change}\n";
    }
### END TEST
}

# Saves (updates) the transaction record in the database
sub save {
    emit __PACKAGE__ . "::save()" if $DEBUG;
    my $this = shift;
    my $htx  = $this->{htx};
    my $db   = $htx->{db};
    my $sql
        = "UPDATE transactions SET "
        . join(q{,}, map {"$_ = " . $db->quote($this->{$_})} @COLS)
        . " WHERE trnId = "
        . $db->quote($this->{trnId}) . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $rec = $db->update($sql);
    if ($db->error) {
        $this->{err} = "Error updating existing transaction record: " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    $this->{err} = q{};
    return $this;
}

# Return the list of sales
sub sales {
    my $this = shift;
    return @{$this->{sales}};
}

# Set or get service charge amount
sub servicecharge {
    my ($this, $sc) = @_;
    $this->{trnServiceCharge} = $sc if defined $sc;
    return $this->{trnServiceCharge};
}

# Subtotal
sub subtotal {
    my $this = shift;
    return $this->{subtotal};
}

# Tax amount
sub tax {
    my $this = shift;
    return $this->{trnTaxAmount};
}

# Tax rate as a percentage
sub taxrate {
    my $this = shift;
    return $this->{trnTaxRate} * 100.0;
}

# Return the list of tickets
sub tickets {
    my $this = shift;
    return @{$this->{tickets}};
}

# Total
sub total {
    my $this = shift;
    return $this->{total};
}

# Set/get transaction id
sub trnid {
    my ($this, $val) = @_;
    $this->{trnId} = $val if defined $val;
    return $this->{trnId};
}

# Helper function for JSON serialization
sub TO_JSON {
    my $this = shift;
    my $o    = {};
    foreach my $k (keys %$this) {
        $o->{$k} = $this->{$k} if $k =~ m/^trn/;
    }
    return $o;
}

# Split a pickup code into it's two parts
# Returns (trnId, trnPickupCode), else undef if errors
# XXXX-XXXXX (trnId-trnPickupCode)
sub unpickup {
    my $pk = shift;
    $pk =~ s/[^\w]//ig;  # get rid of anything but word chars (ie, toss delimiters)
    return (undef, undef) 
        if ($pk =~ m/[^\d]/)
        || length($pk) < 6;
    $pk = int($pk);
    my $trnId = int(substr($pk, 0, length($pk) - 5));
    my $code = int(substr($pk, -5, 5));
    return ($trnId, $code);
}

1;

