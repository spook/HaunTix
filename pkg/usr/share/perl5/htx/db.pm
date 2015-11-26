use strict;
use warnings;
use FindBin;
use DBI;

package htx::db;

sub new {
    my ($class) = @_;
    my $this = {
        dbh => undef,    # Database handle
        err => q{},      # Most recent error text
        loc => undef,    # Location of connection
    };
    bless($this, $class);
    return $this;
}

sub connect {
    my ($this, $loc) = @_;
    $this->{loc} = $loc;    # {loc} is the $cfg->{db} subkey
    $this->{err} = q{};

    my $driver = $loc->{drvr} || "mysql";
    my $db     = $loc->{name} || "Hauntix";
    my $host   = $loc->{host} || "localhost";
    my $port   = $loc->{port} || 3306;
    my $user   = $loc->{user} || "hauntix";
    my $pass   = $loc->{pass} || "Scary!";
    $this->{dsn} = "dbi:$driver:database=$db;host=$host;port=$port";

    $this->{dbh} = DBI->connect(
        $this->{dsn}, $user, $pass,
        {   RaiseError => 0,
            PrintError => 0,
            AutoCommit => 1,
            ShowErrorStatement => 1,
        }
    );
    return $this->{err} = $DBI::errstr if !$this->{dbh};
    return q{};
}

sub dbh {
    my $this = shift;
    return $this->{dbh};
}

# Any SQL statement - unchecked
sub do_sql {
    my ($this, $stmt) = @_;
    my $dbh = $this->{dbh};
    $this->{err} = q{};

    my $sth = $dbh->prepare($stmt);
    return $this->{err} = "SQL statement preparation error: " . $sth->errstr()
        if $sth->err();
    return $this->{err} = "SQL statement execution error: " . $sth->errstr()
        if !defined $sth->execute();
    return q{};
}

sub delete {
    my ($this, $stmt) = @_;
    my $dbh = $this->{dbh};
    $this->{err} = q{};
    return $this->{err} = "Not a DELETE: $stmt"
        if $stmt !~ m{^DELETE\s}i;

    my $sth = $dbh->prepare($stmt);
    return $this->{err} = "SQL statement preparation error: " . $sth->errstr()
        if $sth->err();
    return $this->{err} = "SQL statement execution error: " . $sth->errstr()
        if !defined $sth->execute();
    return q{};
}

sub disconnect {
    my $this = shift;
    my $dbh  = $this->{dbh};
    $dbh->disconnect;
    $this->{err} = q{};
    $this->{dbh} = undef;
    return q{};
}

sub error {
    my $this = shift;
    return $this->{err};
}

sub insert {
    my ($this, $stmt) = @_;
    my $dbh = $this->{dbh};
    $this->{err} = q{};
    return $this->{err} = "Not an INSERT: $stmt"
        if $stmt !~ m{^INSERT\s}i;

    my $sth = $dbh->prepare($stmt);
    return $this->{err} = "SQL statement preparation error: " . $sth->errstr()
        if $sth->err();
    return $this->{err} = "SQL statement execution error: " . $sth->errstr()
        if !defined $sth->execute();
    return q{};
}

# Returns undef on error and sets $this->{err}
sub last_id {
    my $this = shift;
    my $dbh  = $this->{dbh};
    $this->{err} = q{};

    my $sth = $dbh->prepare("SELECT LAST_INSERT_ID();");
    if (!$sth) {
        $this->{err} = "SQL statement preparation error: " . $sth->errstr();
        return undef;
    }
    if (!defined $sth->execute()) {
        $this->{err} = "SQL statement execution error: " . $sth->errstr();
        return undef;
    }
    my $ar = $sth->fetchrow_arrayref();
    return $this->{err} = "Error fetching last_insert_id row: " . $sth->errstr()
        if $sth->err();
    return $ar->[0];
}

# Test if database is alive
sub ping {
    my $this = shift;
    return $this->{dbh}->ping;
}

# String quoting
sub quote {
    my $this = shift;
    return $this->{dbh}->quote(@_);
}

# Returns an arrayref (rows) of hash refs (columns); undef on error
sub select {
    my ($this, $stmt) = @_;
    my $dbh = $this->{dbh};
    $this->{err} = q{};
    return $this->{err} = "Not a SELECT: $stmt"
        if $stmt !~ m{^SELECT\s}i;

    my $sth = $dbh->prepare($stmt);
    if (!$sth) {
        $this->{err} = "SQL statement preparation error: " . $sth->errstr();
        return undef;
    }
    if (!defined $sth->execute()) {
        $this->{err} = "SQL statement execution error: " . $sth->errstr();
        return undef;
    }

    my $rows = [];
    while (my $colhash = $sth->fetchrow_hashref()) {
        push @$rows, $colhash;
    }
    if ($sth->err()) {
        $this->{err} = "Error fetching database rows: " . $sth->errstr();
        return undef;
    }
    return $rows;
}

# Setup the session - call after connecting
sub setup {
    my $this   = shift;
    my $dbvars = $this->{loc};    # {loc} is the $cfg->{db} subkey
    my $dbh    = $this->{dbh};
    foreach my $k (qw/auto_increment_increment
                      auto_increment_offset/) {
        next if !exists $dbvars->{$k};
        my $v = $dbvars->{$k};
        my $stmt = "SET $k=$v;";
        my $sth = $dbh->prepare($stmt);
        if (!$sth) {
            return $this->{err} = "SQL setup statement preparation error: " . $sth->errstr();
        }
        if (!defined $sth->execute()) {
            return $this->{err} = "SQL setup statement execution error: " . $sth->errstr();
        }
    }
    return $this->{err} = q{};
}

sub update {
    my ($this, $stmt) = @_;
    my $dbh = $this->{dbh};
    $this->{err} = q{};
    return $this->{err} = "Not an UPDATE: $stmt"
        if $stmt !~ m{^UPDATE\s}i;

    my $sth = $dbh->prepare($stmt);
    return $this->{err} = "SQL statement preparation error: " . $sth->errstr()
        if $sth->err();
    return $this->{err} = "SQL statement execution error: " . $sth->errstr()
        if !defined $sth->execute();
    return q{};
}


1;

