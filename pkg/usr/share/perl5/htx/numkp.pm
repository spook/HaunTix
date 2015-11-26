#=============================================================================
#
# Hauntix GUI - Numeric Keypad
#   Creates a numeric keypad and sticks it into a Frame.
#   Should be associated with a Tk::Entry widget (otherwise it does nothing!)
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use FindBin;
use Tk;

package htx::numkp;
  our @ISA = qw(htx::frame);
  use htx;

#
# Make a new numeric keypad
#
sub new {
    my $class  = shift;
    my $parent = shift;
    my %cargs  = _c(@_);
    my $opts   = {};
    foreach
        my $o (qw/integer entry font/)
    {
        $opts->{$o} = delete $cargs{$o} || undef;    # Associated entry widget
    }
    my %dargs = _d(%cargs);
    my $this  = $parent->Frame(%dargs);
    $this->{_o} = $opts;                             # Widget-specific options
    bless($this, $class);
    return $this->fill;
}

sub integer_mode {
    my ($this, $i) = @_;
    $this->{_o}->{integer} = $i || 0;
    $this->{_k}->{"."}->{_o}->{wantstate} = $i? 'disabled' : 'normal';
    return $this;
}

sub fill {
    my $this = shift;
    my @font = $this->{_o}->{font} ? (-font => $this->{_o}->{font}) : ();

    # Keypad
    my $i = 0;
    foreach my $n (qw{7 8 9 4 5 6 1 2 3 . 0 C}) {
        $this->{_k}->{$n} = $this->Button(
            -text => $n,
            @font,
            -command => sub {$this->padpress($n);},
            -state   => 'disabled', # start disabled
            )->grid(-row    => int($i / 3),
                    -column => $i % 3,
                    -sticky => 'nsew');
        ++$i;
    }
    $this->integer_mode($this->{_o}->{integer});
    $this->lit;
    return $this;
}

# Switch to using a different entry widget
sub use_entry {
    my ($this, $e) = @_;
    $this->{_o}->{entry} = $e;
    return $this;
}

sub padpress {
    my ($this, $n) = @_;
    my $e = $this->{_o}->{entry};
    return if !$e;
    if ($e->selectionPresent) {
        $e->delete('sel.first','sel.last');
    }
    if ($n eq 'C') {
        return $e->delete(0,'end');
    }
    $e->insert('insert', $n)
}
