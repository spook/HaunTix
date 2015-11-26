#=============================================================================
#
# Hauntix Common Stuff
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

package htx;
  use Carp qw(cluck);
  require Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = qw($CONFIG_FILE 
                   $HTX_NAME
                   $HTX_VERSION
                   _c cent cents commify _d dol dollar dollars _nl);


  our $HTX_NAME    = "Hauntix Ticketing System";
  our $HTX_VERSION = "v0.5";
  ### TODO: This below is a mess - do it a better way!
  our $CONFIG_FILE = -r '/etc/htx/hauntix.conf'? '/etc/htx/hauntix.conf'
                   : -r ($ENV{DOCUMENT_ROOT}||q{}) . q{/../etc/htx/hauntix.conf}? $ENV{DOCUMENT_ROOT} . q{/../etc/htx/hauntix.conf}
                   : $ENV{HOME} . q{/etc/htx/hauntix.conf};

# Cleanup tags for named arg notation
sub _c {
    my %args  = @_;
    my %clean = ();
    foreach my $k (keys %args) {
        my $ck = lc $k;
        $ck =~ s/^\s*-//;
        $clean{$ck} = $args{$k};
    }
    return %clean;
}

# Re-dash tags so we can give 'em back to Perl/Tk, which wants leading dashes
sub _d {
    my %args  = @_;
    my %dashed = ();
    foreach my $k (keys %args) {
        my $ck = lc $k;
        $ck =~ s/^\s*-//;   # pull it first, so we don't double-up
        $dashed{"-$ck"} = $args{$k};
    }
    return %dashed;
}

# Returns an integer cent amount given a float dollar amount
sub cent {
    my $fdol = shift;
    if (!defined($fdol) or ($fdol eq q{})) {
        cluck "\ncent() called with empty value"; ### TEST
    }
    return int($fdol*100.00 + 0.5);
}

# Returns integer cents given a formatted dollar string
sub cents {
    my $fdol = shift;
    $fdol =~ s{\x{2212}}{-}mg;  # fancy minus sign back to normal
    $fdol =~ s/[^\-\d\.]//mg;   # remove any non-(digit, minus, or decimal pt)
    $fdol =~ s/\.\.+/./mg;      # multiple dots to one

    # Only one leading negative sign allowed
    my $neg = $fdol =~ m/^-/;
    $fdol =~ s/-//mg;
    $fdol = -$fdol if $neg;

    $fdol ||= 0;
    return cent($fdol);
}

# Put commas every three digits, watching for decimal point too
sub commify {
    my $a = shift;
    $a = reverse $a;
    $a =~ s/(\d{3})(?=\d)(?!\d*\.)/$1,/g;
    $a = reverse $a;
    return $a;
}

# Returns a plain-formatted dollar string, given integer cents
#  No currency sign, no commas
sub dol {
    my $cents = shift;
    my $str = sprintf('%4.2f', $cents / 100.0);
    return $str;
}

# Returns a semi-formatted dollar string, given integer cents
#  Includes currency sign ($) and commas every three digits.
sub dollar {
    my $cents = shift;
    my $str = q{$} . commify(sprintf('%4.2f', $cents / 100.0));
    $str =~ s{\$\-}{-\$};    # Put a plain minus sign in front
    return $str;
}

# Returns a formatted dollar string, given integer cents
#  Includes currency sign ($), commas every three digits, fancy minus.
sub dollars {
    my $cents = shift;
    my $str = q{$} . commify(sprintf('%4.2f', $cents / 100.0));
    $str =~ s{\$\-}{\x{2212}\$};    # Put a "real" minus sign in front
    return $str;
}

# Convert literal '/n' into a newline character
sub _nl {
    my $a = shift;
    $a =~ s{\\n}{\n}mg;
    return $a;
}

1;
