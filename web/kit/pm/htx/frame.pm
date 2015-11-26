#=============================================================================
#
# Hauntix Point of Sale GUI - Base Frame Object
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use Tk;

package htx::frame;
  our @ISA    = qw(Tk::Frame);
  use htx::pos_style;

my $FW = 300;
my $FH = 100;

#
# Make a new generic panel (this should be overridden)
#
sub new {
    my ($class, $parent_frame, $htx) = @_;
    my $this = $parent_frame->Frame(
        -borderwidth => 3,
        -relief      => 'ridge',
        -background  => $COLOR_LIT,
        -width       => $FW,
        -height      => $FH,
    );
    $this->{wantsize} = [-width => $FW, -height => $FH];
    $this->{htx} = $htx;
    bless($this, $class);
    return $this;
}

#
# Populate the panel
#
sub fill {
    my $this = shift;
    my $htx  = $this->{htx};

    $this->Label(-text => "Generic Hauntix Panel - override this function")
        ->pack();
    return $this;
}

#
# Update the panel by rewriting it
#
sub update {
    my $this = shift;

    # Delete existing items
    foreach my $kid ($this->children()) {
        $kid->destroy() if Tk::Exists $kid;
    }

    # Refill it
    return $this->fill();
}

#
# Dim and disable all buttons
#
sub dim {
    my $this = shift;
    ### TODO:  Recurse to grandchildren, etc...
    for my $w ($this->children) {
        $w->configure(-state => 'disabled')
            if $w->class eq "Button";
    }
    return $this;
}

#
# Put all buttons back to normal (undo a dim())
#
sub lit {
    my $this = shift;
    ### TODO:  Recurse to grandchildren, etc...
    for my $w ($this->children) {
        $w->configure(-state => $w->{_o}->{wantstate} || 'normal')
            if $w->class eq "Button";
    }
    return $this;
}

#
# Start things that run
#
sub start {
    my $this = shift;
    my $htx  = $this->{htx};

    return $this;
}

#
# Stop things that're running
#
sub stop {
    my $this = shift;
    my $htx  = $this->{htx};

    return $this;
}

1;
