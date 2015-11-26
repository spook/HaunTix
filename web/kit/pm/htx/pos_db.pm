#=============================================================================
#
# Hauntix Point of Sale - Database functions
#   Note: This is a collection of functions, not an OO class.
#
#-----------------------------------------------------------------------------

### TODO: use constants for itmType's "prd", "upg", etc...

use strict;
use warnings;
use htx::db;

package htx::pos_db;
  require Exporter;
  our @ISA    = qw(Exporter);
  our @EXPORT = qw(connect_db load_items);

#
# Connect to our database and set it up
#
sub connect_db {
    my $htx = shift;
    my $db = new htx::db;
    $db->connect($htx->{cfg}->{db});
    my $err = $db->error;
    die "*** $err\n" if $err;
    $htx->{db} = $db;

    $err = $db->setup;
    die "*** $err\n" if $err;
}

#
# Load sale items: products, upgrades, discounts
#
sub load_items {
    my $htx = shift;
    my $db = $htx->{db};
    $htx->{items} = [];

    # Products
    my $products = $db->select("SELECT prdName,prdCost,prdIsTaxable,prdIsTicket,prdIsTimed,prdIsDaily,prdIsNextAvail,prdScreenPosition,prdClass FROM products;");
    return $db->error if $db->error;
    foreach my $p (@$products) {
        my $pos = $p->{prdScreenPosition};
        next unless defined $pos;
        $htx->{items}->[$pos] = {
            itmName           => $p->{prdName},
            itmCost           => $p->{prdCost},
            itmClass          => $p->{prdClass},
            itmScreenPosition => $p->{prdScreenPosition},
            itmIsTaxable      => $p->{prdIsTaxable},
            itmIsTicket       => $p->{prdIsTicket},
            itmIsTimed        => $p->{prdIsTimed},
            itmIsDaily        => $p->{prdIsDaily},
            itmIsNextAvail    => $p->{prdIsNextAvail},
            itmType           => "prd"
        };
    }

    # Upgrades
    my $upgrades = $db->select("SELECT upgName,upgCost,upgScreenPosition FROM upgrades;");
    return $db->error if $db->error;
    foreach my $u (@$upgrades) {
        my $pos = $u->{upgScreenPosition};
        next unless defined $pos;

        my $cost = $u->{upgCost};
        if (!defined $cost) {

            # TODO: Lookup old and new product costs
            $cost = 1;    #*** TEMPORARY, set cost to 1 cent
        }

        $htx->{items}->[$pos] = {
            itmName           => $u->{upgName},
            itmCost           => $cost,
            itmScreenPosition => $u->{upgScreenPosition},
            itmType           => "upg"
        };
    }

    # Discounts
    my $discounts = $db->select("SELECT dscName,dscMethod,dscAmount,dscClass,dscScreenPosition FROM discounts;");
    return $db->error if $db->error;
    foreach my $d (@$discounts) {
        my $pos = $d->{dscScreenPosition};
        next unless defined $pos;
        $htx->{items}->[$pos] = {
            itmName           => $d->{dscName},
            itmMethod         => $d->{dscMethod},   # FixedAmount, Percent, ...
            itmCost           => -$d->{dscAmount},  # cents or hundredths of percent off
            itmClass          => $d->{dscClass},
            itmScreenPosition => $d->{dscScreenPosition},
            itmType           => "dsc",
        };
    }

    return 0;    #OK
}

1;

