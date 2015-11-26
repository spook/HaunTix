#=============================================================================
#
# Hauntix Point of Sale GUI - Epson TM88 driver
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

package htx::drv_epson_tm88;
    require Exporter;
    our @ISA    = qw(Exporter);
    our @EXPORT = qw();

    our $FW = 42;   # Full width, characters

sub new {
    my ($class) = @_;
    my $this = {queue => q{},
                blob  => q{},   # The raw blob to be printed
                mode  => 999,   # Current print mode in effect
                just  => 999,   # Current justification in effect
                revm  => 999,   # Current reverse mode in effect
                flip  => 999,   # Current flip (upside-down) in effect
               };
    bless($this, $class);
    return $this;
}

# Produce a barcode
sub barcode {
    my ($this, $data, $opts) = @_;
    my $ht = 74;
    my $bc = "\x1dH2";          # numbers below barcode
    $bc .= "\x1df0";            # numbers in font A
    $bc .= "\x1dh".chr($ht);    # barcode height
    $bc .= "\x1dw3";            # barcode width (1-6)
    $bc .= "\x1dk".chr(0);      # begin barcode, 0=UPC-A
    $bc .= $data;
    $bc .= "\x00";              # end barcode
    $this->put($bc, $opts);
}

# Return the error string
sub error {
    my $this = shift;
    return $this->{err};
}

# Feed and cut
sub feed_and_cut {
    my $this = shift;
    $this->{blob} .= qq{\x1d\x56\x42\x01};
}

# Put raw text to the blob buffer
sub put {
    my ($this, $text, $opts) = @_;
    if ($this->{mode} != (my $mode = _pmode($opts))) {
        $this->{blob} .= qq{\x1b!}.chr($mode);
        $this->{mode} = $mode;
    }
    if ($this->{just} != (my $just = _pjust($opts))) {
        $this->{blob} .= qq{\x1ba}.chr($just);
        $this->{just} = $just;
    }
    if ($this->{revm} != (my $revm = _prevm($opts))) {
        $this->{blob} .= qq{\x1dB}.chr($revm);
        $this->{revm} = $revm;
    }
    if ($this->{flip} != (my $flip = _pflip($opts))) {
        $this->{blob} .= qq/\x1b{/.chr($flip);
        $this->{flip} = $flip;
    }
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
    $this->{blob} .= "\x1b@";
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

# Get 'print flip mode' from options string
sub _pflip {
    my $ostr = shift || q{};
    my $f = 0; # normal
    $f = 1 if $ostr =~ m{\bflip\b}i;
    return $f;
}

# Get 'print justification' from options string
sub _pjust {
    my $ostr = shift || q{};
    my $j = 0; # center
    $j = 1 if $ostr =~ m{\bcenter\b}i;
    $j = 2 if $ostr =~ m{\bright\b}i;
    return $j;
}

# Get 'print mode' from options string
sub _pmode {
    my $ostr = shift || q{};
    my $m = 0;
    $m +=   1 if $ostr =~ m{\btiny\b}i;
    $m +=   8 if $ostr =~ m{\bbold\b}i;
    $m +=  16 if $ostr =~ m{\btall\b}i;
    $m +=  32 if $ostr =~ m{\b(wide|fat)\b}i;
    $m += 128 if $ostr =~ m{\bunder\b}i;
    return $m;
}

# Get 'print reverse mode' from options string
sub _prevm {
    my $ostr = shift || q{};
    my $r = 0;
    $r = 1 if $ostr =~ m{\brev\b}i;
    return $r;
}

1;