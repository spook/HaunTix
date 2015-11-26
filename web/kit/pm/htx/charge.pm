#=============================================================================
#
# Hauntix Point of Sale - Credit Card Charge object
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

package htx::charge;
use htx;
use htx::db;
use Digest::MD5 qw/md5_hex/;
use Term::Emit qw/:all/;
my @COLS = qw/
    trnId
    chgTimestamp
    chgType
    chgDuplicateMode
    chgRequestAmount
    chgAmount
    chgApprovalCode
    chgBatchNum
    chgCardType
    chgCommercialCardResponseCode
    chgExpDate
    chgMaskedAcctNum
    chgProcessorResponse
    chgResponseCode
    chgTransactionID
    chgAcctNumSource
    chgAcctNumHash
    chgComment /;
my $DEBUG = $ENV{'HTX_DEBUG'} || 0;

sub new {
    emit __PACKAGE__ . "::new()" if $DEBUG;
    my $class = shift;
    my %cargs = _c(@_);
    my $this  = {
        htx          => $cargs{htx},
        err          => q{},
        trnId        => $cargs{trnid}   || 0,            # Transaction ID in transactions table
        chgId        => $cargs{chgid}   || 0,            #  int not null primary key auto_increment,
        chgType      => $cargs{chgtype} || q{Charge},    #  enum ("Charge", "Refund", "Void"),
        chgTimestamp => $cargs{chgtimestamp} || 0,       #  timestamp default now(),

        # Sent into the processor, along with our account info, pwd's, etc.
        chgDuplicateMode => $cargs{chgduplicatemode} || 0,    # boolean comment "Is duplicate checking enabled?",
        chgRequestAmount => $cargs{chgrequestamount} || 0,    # int comment "Amount requested to be charged, in cents",

        # The following fields are returned from the processor on a successful charge
        chgAmount                     => $cargs{chgamount}                     || 0,      # int comment "Amount charged, in cents",
        chgApprovalCode               => $cargs{chgapprovalcode}               || q{},    # varchar(6),
        chgBatchNum                   => $cargs{chgbatchnum}                   || q{},    #  varchar(6),
        chgCardType                   => $cargs{chgcardtype}                   || q{},    #  varchar(16),
        chgCommercialCardResponseCode => $cargs{chgcommercialcardresponsecode} || q{},    #  char(1) default " ",
        chgExpDate                    => $cargs{chgexpdate}                    || q{},    #  char(4),
        chgMaskedAcctNum              => $cargs{chgmaskedacctnum}              || q{},    #  varchar(24),
        chgProcessorResponse          => $cargs{chgprocesorresponse}           || q{},    #  varchar(32),
        chgResponseCode               => $cargs{chgresponsecode}               || 0,      #  int,
        chgTransactionID              => $cargs{chgtransactionid}              || q{},    #  char(12),  ***Not the htx trnId!***

        # Additional info we store in the database
        chgAcctNumHash => $cargs{chgacctnumhash} || q{},                                  #  char(32) comment "MD5 hash of card account number",
        chgComment     => $cargs{chgcomment}     || q{},                                  #  varchar(255)

        # NEVER STORE THE FOLLOWING INFO IN THE D/B!
        #   Only used to void a charge if the transaction is cancelled.
        track   => q{},
        acct    => q{},
        expdate => q{},
        ccv     => q{},
    };
    bless($this, $class);
    return $this;
}

# Multiple Object Constructor:
#  Finds all charges for the given transaction ID, and creates charge objects for each.
#  Returns a hashref containing an error string, and an arrayref that's
#    the list of charge objects.  The charge object list may be empty.
#    $cl = htx::charge::load_by_transaction(-htx => $htx, -trnId => $trnId);
#    if ($cl->{err}) ...
#    @charges = @{$cl->{charges}};
sub load_by_transaction {
    emit __PACKAGE__ . "::load()" if $DEBUG;
    my %cargs = _c(@_);
    my $this  = {
        err     => q{},
        htx     => $cargs{htx},
        trnId   => $cargs{trnid} || 0,
        charges => [],
    };

    # Look for the records
    my $htx = $this->{htx};
    my $db  = $htx->{db};
    my $sql = "SELECT chgId," . join(q{,}, @COLS) . " FROM charges WHERE trnId = " . $db->quote($this->{trnId}) . q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $recs = $db->select($sql);
    if ($db->error) {
        $this->{err} = "Error loading charge records for trnId=$this->{trnId} : " . $db->error;
        emit_error {-reason => $this->{err}} if $DEBUG;
        return $this;
    }

    # For each charge record, create a charge object
    foreach my $rec (@$recs) {
        my $charge = htx::charge->new(-htx => $htx, %$rec);
        push @{$this->{charges}}, $charge;
    }

    return $this;
}

# Set/get the account number
sub acct {
    my ($this, $val) = @_;
    if (defined $val) {
        $this->{acct}           = $val;
        $this->{chgAcctNumHash} = md5_hex($val);
    }
    return $this->{acct};
}

# Get the cc processor's approval code (see also rcode)
sub acode {
    my $this = shift;
    return $this->{chgApprovalCode};
}

# Get-only (not set) the amount that was actually charged (in cents)
sub amount_charged {
    my ($this) = @_;
    return $this->{chgAmount};
}

# Set/get the amount to be charged (in cents)
sub amount_requested {
    my ($this, $amt) = @_;
    $this->{chgRequestAmount} = $amt
        if defined $amt;
    return $this->{chgRequestAmount};
}

# Set/get the CCV code
sub ccv {
    my ($this, $val) = @_;
    $this->{ccv} = $val if defined $val;
    return $this->{ccv};
}

# Get-only the charge transaction ID (not the HTX transaction id)
sub charge_id {
    my ($this) = @_;
    return $this->{chgTransactionID};
}

# Set/get comment
sub comment {
    my ($this, $val) = @_;
    $this->{chgComment} = $val
        if defined $val;
    return $this->{chgComment};
}

# Set/get duplicate checking mode (true means dup check enabled)
sub dup_mode {
    my ($this, $dup) = @_;
    $this->{chgDuplicateMode} = $dup ? 1 : 0
        if defined $dup;
    return $this->{chgDuplicateMode};
}

# Return current error string
sub error {
    my $this = shift;
    return $this->{err};
}

# Set/get the expiration date (mmyy)
sub expdate {
    my ($this, $val) = @_;
    if (defined $val) {
        $this->{expdate} = $val;
        $this->{expdate} =~ s{/}{};    # Remove delimiter if given
    }
    return $this->{expdate};
}

# Parse text or hash response from CC processor
sub parse_proc {
    my ($this, $rsp) = @_;
    foreach my $k (
        qw/
        AcctNumSource
        Amount
        ApprovalCode
        BatchAmount
        BatchNum
        CardType
        CommercialCardResponseCode
        ExpDate
        MaskedAcctNum
        ProcessorResponse
        ResponseCode
        ResponseDescription
        TransactionID /
        )
    {

        if (ref $rsp) {
            $this->{"chg$k"} = exists $rsp->{$k} ? $rsp->{$k} : q{};
        }
        else {
            $this->{"chg$k"} = $rsp =~ m/^\s*$k\s+=>\s+(.+)\s*$/im ? $1 : q{};
        }
        if (($k =~ m{Amount$}i) && length($this->{"chg$k"})) {

            # Processor uses float dollars.  Use cents for internal storage.
            $this->{"chg$k"} = cent($this->{"chg$k"});
        }
    }
}

sub rcode {
    my $this = shift;
    return $this->{chgResponseCode};
}

sub rdesc {
    my $this = shift;
    return $this->{chgResponseDescription};
}

# Write the record to the database; returns error string.
sub save {
    emit __PACKAGE__ . "::save()" if $DEBUG;
    my $this = shift;
    my $db   = $this->{htx}->{db};
    return $this->{err} = "Cannot save charge record; HTX database not defined" if !$db;
    my $sql  = "INSERT INTO charges SET " . " trnId = $this->{trnId}";
    foreach my $k (keys %$this) {
        next if $k !~ m/^chg/;
        next if $k eq "chgId";
        next if $k eq "chgTimestamp";              # Don't set, so timestamp is auto
        next if $k eq "chgBatchAmount";            # We don't store this in the d/b
        next if $k eq "chgResponseDescription";    # We don't store this in the d/b
        if ($k eq "chgDuplicateMode") {
            $sql .= qq{, $k = '} . ($this->{chgDuplicateMode} ? "true" : "false") . q{'};
        }
        else {
            $sql .= ", $k = " . $db->quote($this->{$k});
        }
    }
    $sql .= q{;};
    emit_text "SQL = $sql" if $DEBUG;
    my $err = $db->insert($sql);
    emit_error {-reason => $db->error} if $DEBUG && $db->error;
    return $this->{err} = $db->error if $db->error;
    $this->{chgId} = $db->last_id;
    emit_error {-reason => $db->error} if $DEBUG && $db->error;
    return $this->{err} = $db->error if $db->error;
    return $this->{err} = q{};
}

# Set/get the track swipe
sub track {
    my ($this, $val) = @_;
    if (defined $val) {
        $this->{track} = $val;
        if ($val =~ m{^\;(\d{13,19})\=}) {
            my $acctnum = $1;
            $this->{chgAcctNumHash} = md5_hex($acctnum);
        }
    }
    return $this->{track};
}

# Get/set the HTX transaction ID (not the CC transaction ID)
sub trnid {
    my ($this, $val) = @_;
    $this->{trnId} = $val if defined $val;
    return $this->{trnId};
}

# Get/set the type (Charge, Refund, ...)
sub type {
    my ($this, $val) = @_;
    $this->{chgType} = $val if defined $val;
    return $this->{chgType};
}

sub TO_JSON {
    my $this = shift;
    my $o    = {};
    foreach my $k (keys %$this) {
        $o->{$k} = $this->{$k} if $k =~ m/^chg/ || $k eq 'trnId';
    }
    return $o;
}

1;

