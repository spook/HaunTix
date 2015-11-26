#=============================================================================
#
# Hauntix Point of Sale - Sale Item Object - one line on a receipt
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

package htx::sale;
  use htx;
  use Term::Emit qw/:all/;

  require Exporter;
  our @ISA    = qw(Exporter);
  our @EXPORT = qw(
    $SALE_TYPE_PRODUCT
    $SALE_TYPE_UPGRADE
    $SALE_TYPE_DISCOUNT
  );
  our $SALE_TYPE_PRODUCT  = 'prd';
  our $SALE_TYPE_UPGRADE  = 'upg';
  our $SALE_TYPE_DISCOUNT = 'dsc';

  my @COLS = qw/trnId salType salName salQuantity salCost salPaid salIsTaxable salIsTicket salIsTimed salIsDaily salPickupCount/;
  my $DEBUG = $ENV{'HTX_DEBUG'} || 0;

# A sale line-item - creates new record in d/b, with a new salId.
#  But if a salId is given, just the object is created, without the database.
#  $s = htx::sale->new(htx => $htx, ...)
#  if ($s->error) ...
sub new {
    emit __PACKAGE__ . "::new()" if $DEBUG;
    my $class = shift;
    my %cargs = _c(@_);
    my $this  = {
        err            => q{},
        htx            => $cargs{htx},
        show           => $cargs{show}  || undef,         #Related show object (convienence)
        tickets        => $cargs{tickets} || [],          #Related list of tickets (convienence)
        salId          => $cargs{salid} || 0,             #int not null unique auto_increment primary key comment "ID for this record",
        trnId          => $cargs{trnid} || 0,             #int comment "Transaction ID in transactions table",
        salType        => $cargs{saltype} || q{},         #char(3) comment "type code: prd, dsc, upg, ...",
        salName        => $cargs{salname} || q{},         #varchar(32) not null comment "Item name - product, discount, or upgrade",
        salQuantity    => $cargs{salquantity} || 1,       #int not null default 1 comment "Number of this product sold at this price",
        salCost        => $cargs{salcost} || 0,           #int not null comment "cost per-item, units: cents",
        salPaid        => $cargs{salpaid} || 0,           #int not null comment "actual amt paid per-item, after discounts, unit: cents",
        salIsTaxable   => $cargs{salistaxable}   || 0,    #boolean comment "item is taxed?",
        salIsTicket    => $cargs{salisticket}    || 0,    #boolean comment "is the item a ticket?",
        salIsTimed     => $cargs{salistimed}     || 0,    #boolean comment "is this for a timed event?",
        salIsDaily     => $cargs{salisdaily}     || 0,    #boolean comment "is this for a daily event?",
        salPickupCount => $cargs{salpickupcount} || 0,    #int default 0 comment "Count of pickups done on this item"
    };
    bless($this, $class);
    return $this if $this->{salId};

    my $htx = $this->{htx};
    my $db = $htx->{db};
    my $sql = "INSERT INTO sales SET "
            . join(q{,}, map {"$_ = " . $db->quote($this->{$_})} @COLS)
            . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $err = $db->insert($sql);
    if ($db->error) {
        $this->{err} = "Error creating new sale record: " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }

    # Get back the sale ID
    $this->{salId} = $db->last_id;
    $this->{err} = "Error getting sale ID: " . $db->error if $db->error;
    emit_error {-reason => $this->{err}} if $DEBUG && $this->{err};
    return $this;
}

# Object constructor: Creates new sale object, loading info from the database.
#  Sets the error string if the record does not exist:
#    $s = htx::sale->load(htx->$htx, salId => $salId);
#    if ($s->error) ...
sub load {
    emit __PACKAGE__ . "::load()" if $DEBUG;
    my $class = shift;
    my %cargs = _c(@_);
    my $this  = {
        err            => q{},
        htx            => $cargs{htx},
        show           => $cargs{show}    || undef,
        tickets        => $cargs{tickets} || [],
        salId          => $cargs{salid}   || 0,
    };
    bless($this, $class);

    # Look for the record
    my $htx = $this->{htx};
    my $db = $htx->{db};
    my $sql = "SELECT " 
        . join(q{,}, @COLS)
        . " FROM sales WHERE salId = " . $db->quote($this->{salId})
        . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $recs = $db->select($sql);
    if ($db->error) {
        $this->{err} = "Error loading existing sale record: " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    if (@$recs != 1) {
        $this->{err} = "Not one sale record found for sale ID $this->{salId}";
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    foreach my $k (@COLS) {
        $this->{$k} = $recs->[0]->{$k};
    }

    # If sale item is a ticket, load the tickets and the show
    if ($this->{salIsTicket} && !$this->{show}) {

        # Find first ticket with this salID and get it's shoId
        my $sql = "SELECT tixId,shoId FROM tickets" 
                . " WHERE salId = " . $db->quote($this->{salId});
        emit_text "SQL = $sql" if $DEBUG;
        my $tixrecs = $db->select($sql);
        if ($db->error) {
            $this->{err} = "Error finding tickets for sale $this->{salId}: " . $db->error;
            emit_error {-reason => $this->{err}} if $DEBUG;
            return $this;
        }

        # Load each ticket
        foreach my $tixrec (@$tixrecs) {
            my $tixId = $tixrec->{tixId};
### TODO: make the load() fn in tickets.pm
            ### my $ticket = htx::ticket->load(-htx => $htx, -tixId => $tixId);
            ### push @{$this->{tickets}}, $ticket;
        }

        # Note: it's not an error if the ticket has no shoId.
        #  That's how a FlexTix ticket is represented.
        if (@$tixrecs && $tixrecs->[0]->{shoId}) {
            $this->{show} = htx::show->load(-htx => $this->{htx},
                                            -shoId => $tixrecs->[0]->{shoId});
            # But it is an error if the ticket has a shoId for a non-existant show
            if ($this->{show}->error) {
                $this->{err} = "No show for sale $this->{salId}'s ticket: " . $this->{show}->error;
                $this->{show} = undef;  # toss the object
                emit_error {-reason => $this->{err}} if $DEBUG;
                return $this;
            }
        }
    }
    return $this;
}

# Multiple Object constructor:
#  Finds all sales for the given transaction ID, and creates
#  sale objects for each.
#  Returns a hashref containing an error string, and an arrayref that's 
#    the list of sale objects.  The sale object list may be empty.
#    $sl = htx::sale::load_by_transaction(-htx => $htx, -trnId => $trnId);
#    if ($sl->{err}) ...
#    @sales = @{$sl->{sales}};
sub load_by_transaction {
    emit __PACKAGE__ . "::load()" if $DEBUG;
    my %cargs = _c(@_);
    my $this  = {
        err   => q{},
        sales => [],
        htx   => $cargs{htx},
        trnId => $cargs{trnid} || 0,
    };

    # Look for the records
    my $htx = $this->{htx};
    my $db = $htx->{db};
    my $sql = "SELECT salId," 
            . join(q{,}, @COLS)
            . " FROM sales WHERE trnId = " . $db->quote($this->{trnId})
            . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $recs = $db->select($sql);
    if ($db->error) {
        $this->{err} = "Error loading sale records for trnId=$this->{trnId} : " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }

    # For each sale record, create a sale object
    foreach my $rec (@$recs) {

        # Create the sale object
        my $sale = htx::sale->new(-htx => $htx, %$rec);

        # If sale item is a ticket, load the tickets and the show
        if ($sale->{salIsTicket}) {
            my $tl = htx::ticket::load_by_sale(-htx => $htx, -salId => $sale->{salId});
            if ($tl->{err}) {
                $this->{err} = $tl->{err};
                emit_error {-reason => $this->{err}} if $DEBUG;
                return $this;
            }
            $sale->{tickets} = $tl->{tickets};

            # Get shoId from first ticket, and load that show object into 
            #   both the sale and the ticket
            # Note: it's not an error if the ticket has no shoId.
            #  That's how a FlexTix ticket is represented.
            if (@{$sale->{tickets}} && $sale->{tickets}->[0]->{shoId}) {
                $sale->{show} = htx::show->load(-htx   => $this->{htx},
                                                -shoId => $sale->{tickets}->[0]->{shoId});
                map {$_->{show} = $sale->{show}} @{$sale->{tickets}};
                # But it is an error if the ticket has a shoId for a non-existant show
                if ($sale->{show}->error) {
                    $this->{err} = "No show for sale $sale->{salId}'s ticket: " . $sale->{show}->error;
                    $sale->{show} = undef;  # toss the object
                    emit_error {-reason => $this->{err}} if $DEBUG;
                    return $this;
                }
            }
        }

        push @{$this->{sales}}, $sale;
    }

    return $this;
}

# Delete this sale from the database
sub nuke {
    emit __PACKAGE__ . "::nuke()" if $DEBUG;
    my $this = shift;
    my $htx = $this->{htx};
    my $db = $htx->{db};
    my $sql = "DELETE FROM sales WHERE salId = " . $db->quote($this->{salId}) . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $rec = $db->delete($sql);
    if ($db->error) {
        $this->{err} = "Error deleting sale record $this->{salId}: " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }
    $this->{err} = q{};
    return $this;
}

# Save the object out to the database
sub save {
    emit __PACKAGE__ . "::save()" if $DEBUG;
    my $this = shift;
    my $htx = $this->{htx};
    my $db = $htx->{db};
    my $sql = "UPDATE sales SET " 
        . join(q{,}, map {"$_ = " . $db->quote($this->{$_})} @COLS)
        . " WHERE salId = " . $db->quote($this->{salId})
        . q{;};
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

sub TO_JSON {
    my $this = shift;
    my $o = {};
    foreach my $k (keys %$this) {
        $o->{$k} = $this->{$k} if $k =~ m/^sal/ || $k eq 'trnId';
    }
    return $o;
}

1;

