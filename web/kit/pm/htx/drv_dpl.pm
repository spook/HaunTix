#=============================================================================
#
# Hauntix Point of Sale GUI - Dataman Printing Language (DPL) driver
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

package htx::drv_dpl;

my $soh = "\x01";
my $stx = "\x02";

sub new {
    my ($class) = @_;
    my $this = {queue => q{},
                blob  => q{},   # The raw blob to be printed
#                mode  => 999,   # Current print mode in effect
#                just  => 999,   # Current justification in effect
#                revm  => 999,   # Current reverse mode in effect
#                flip  => 999,   # Current flip (upside-down) in effect
               };
    bless($this, $class);
    return $this;
}

# Produce a barcode
#sub barcode {
#    my ($this, $data, $opts) = @_;
#    my $ht = 74;
#    my $bc = "\x1dH2";          # numbers below barcode
#    $bc .= "\x1df0";            # numbers in font A
#    $bc .= "\x1dh".chr($ht);    # barcode height
#    $bc .= "\x1dw3";            # barcode width (1-6)
#    $bc .= "\x1dk".chr(0);      # begin barcode, 0=UPC-A
#    $bc .= $data;
#    $bc .= "\x00";              # end barcode
#    $this->put($bc, $opts);
#}

# Put a command line
sub cmd {
    my ($this, $text, $opts) = @_;
    $this->put($text, $opts);
    $this->put(qq{\r}, $opts);
}

# Return the error string
sub error {
    my $this = shift;
    return $this->{err};
}

# Feed and cut
sub feed_and_cut {
    my $this = shift;
    $this->cmd("Q0001");  # quantity
    $this->cmd("E");      # End format, begin print
}

# Put raw text to the blob buffer
sub put {
    my ($this, $text, $opts) = @_;
    $this->{blob} .= $text || q{};
}

# Get or set the print queue name
sub queue {
    my ($this, $queue) = @_;
    $this->{queue} = $queue if defined $queue;
    return $this->{queue};
}

# Reset/initialize the printer
sub reset {
    my $this = shift;
    $this->{blob} .= "${stx}V5";    # Enable cutter
    $this->{blob} .= "${stx}n";     # Set imperial units
    $this->{blob} .= "${stx}L\r";   # Begin label
    $this->{blob} .= "D11\r";       # Dot scaling 1x1
}

# Put text with a newline
sub say {
    my ($this, $text, $opts) = @_;
    $this->put($text, $opts);
    $this->put(qq{\n}, $opts);
}

# Submit the job to the queue
sub submit {
    my $this = shift;
    my $Pswitch = q{};
    $Pswitch = " -P $this->{queue}" if $this->{queue};
    if (!open(LPR, "|lpr$Pswitch")) {
        return $this->{err} = "Error opening pipe to lpr: $!";
    }
    print LPR $this->{blob};
    close LPR;
    $this->{blob} = q{};
    return $this->{err} = q{};
}

1;