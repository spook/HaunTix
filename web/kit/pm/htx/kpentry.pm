#=============================================================================
#
# Hauntix GUI - An entry field that's tied to a keypad
#   Should be associated with an htx::numkeys or similar.
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use FindBin;
use Tk;
use Tk::Entry;

package htx::kpentry;
 our @ISA = qw(Tk::Entry);
 use htx;

#
# Make and setup the Entry widget
#
sub new {
    my $class  = shift;
    my $parent = shift;
    my %cargs  = _c(@_);
    my $opts   = {};
    foreach my $o (qw/keypad autoclear currency number integer negative/) {
        $opts->{$o} = delete $cargs{$o} || undef;    # Associated entry widget
    }
    my %dargs = _d(%cargs);
    my $this  = $parent->Entry(%dargs);
    $this->{_o} = $opts;        # Internal options
    $this->{_o}->{ev} = q{};    # Entry's value (what is displayed)
    $this->configure(-validate        => 'key',
                     -validatecommand => sub {$this->vfunc(@_)},
                     -textvariable    => $this->{_o}->{ev},
                    );
    if (my $kp = $this->{_o}->{keypad}) {
        $kp->use_entry($this);  # tell the keypad widget to use us
        $kp->integer_mode($this->{_o}->{integer});
        $kp->lit;
        $this->bind('<FocusIn>' => sub {$kp->use_entry($this);
                                        $kp->integer_mode($this->{_o}->{integer});
                                        $kp->lit;
                                       }); # ...and whenever we get focus
    }
###$this->bind('<KeyRelease>' => sub {print "KeyRelease event on entry widget\n";    ###, keycode=".Ev('k')."\n";
###            $this->{_o}->{ev} = '5' . $this->{_o}->{ev};  ### THIS DOES NOT WORK
###                                      }); 
    bless($this, $class);   # re-bless into our class
    return $this;
}

# Return the internal (cleaned-up) value
sub iv {
    my $this = shift;
    return $this->{_o}->{parsecmd}
        ? $this->{_o}->{parsecmd}($this->{_o}->{ev})
        : $this->{_o}->{ev};
}

# Validation function
sub vfunc {
    my ($this, $val) = @_;
    ### TODO: re-format the field every time, if it's good - risky to change -textvariable each time?
print "$this vfunc($val) called\n"; ### TEMP
    if ($this->{_o}->{currency}) {
        my $neg = $this->{_o}->{negative}? '(-|\x{2212})?' : q{};
        my $dec = $this->{_o}->{integer}? q{} : '(\.\d{0,2})?';
        return 0 if $val !~ m{^                # Start
                              $neg             # optional minus, either style
                              \$?              # optional dollar sign
                              [,\d]*           # digits or commas
                              $dec             # one decimal and max two digits
                              $}x;
        # reformat it...
        $this->{_o}->{ev} = "-" . $this->{_o}->{ev}; ### TEST
    }
    elsif ($this->{_o}->{number}) {
        my $neg = $this->{_o}->{negative}? '(-|\x{2212})?' : q{};
        my $dec = $this->{_o}->{integer}? q{} : '(\.\d*)?';
        return 0 if $val !~ m{^                # Start
                              $neg             # optional minus, either style
                              [,\d]*           # digits or commas
                              $dec             # optional one decimal point and digits
                              $}x;
        # reformat it...
    }
    return 1;
}