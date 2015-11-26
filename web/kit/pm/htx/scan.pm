#=============================================================================
#
# Hauntix Point of Sale - Scan Object - records ticket barcode scans
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

package htx::scan;
  use htx;
  use Term::Emit qw/:all/;


  my @COLS = qw/scnNumber scnStatus scnResult scnUser/;   # scnId scnTimestamp 
  my $DEBUG = $ENV{'HTX_DEBUG'} || 0;

# A scan record - creates new record in d/b with a new scnId.
#  But if a scnId is given, just the object is created, without the database.
#  $s = htx::scan->new(htx => $htx, ...)
#  if ($s->error) ...
sub new {
    emit __PACKAGE__ . "::new()" if $DEBUG;
    my $class = shift;
    my %cargs = _c(@_);
    my $this  = {
        err            => q{},
        htx            => $cargs{htx},
        scnId          => $cargs{scnid} || 0,
        scnTimestamp   => $cargs{scntimestamp} || q{},
        scnNumber      => $cargs{scnnumber} || 0,
        scnStatus      => $cargs{scnstatus} || q{},
        scnResult      => $cargs{scnresult} || q{},
        scnUser        => $cargs{scnuser}   || $ENV{USER} || q{},
    };
    bless($this, $class);
    return $this if $this->{salId};

    my $htx = $this->{htx};
    my $db = $htx->{db};
    my $sql = "INSERT INTO scans SET "
            . join(q{,}, map {"$_ = " . $db->quote($this->{$_})} @COLS)
            . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $err = $db->insert($sql);
    if ($db->error) {
        $this->{err} = "Error creating new scan record: " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }

    # Get back the scan ID
    $this->{scnId} = $db->last_id;
    $this->{err} = "Error getting scan ID: " . $db->error if $db->error;
    emit_error {-reason => $this->{err}} if $DEBUG && $this->{err};
    return $this;
}

# Save the object out to the database
sub save {
    emit __PACKAGE__ . "::save()" if $DEBUG;
    my $this = shift;
    my $htx = $this->{htx};
    my $db = $htx->{db};
    my $sql = "UPDATE scans SET " 
        . join(q{,}, map {"$_ = " . $db->quote($this->{$_})} @COLS)
        . " WHERE scnId = " . $db->quote($this->{scnId})
        . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $rec = $db->update($sql);
    if ($db->error) {
        $this->{err} = "Error updating existing scan record: " . $db->error;
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
