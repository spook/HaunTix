#=============================================================================
#
# Hauntix Point of Sale GUI - Nums (numbar + numpad) Panel
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use Tk;
use htx::frame;
my $TESTMODE = ($ENV{HTX_TEST}||q{}) =~ m/n/;
my $TESTFILE = 'htx-pos-nums.t.out';

package htx::pos_nums;
use htx;
use htx::pos_style;
require Exporter;
our @ISA    = qw(Exporter htx::frame);
our @EXPORT = qw($NUMBAR_MODE_AMT
    $NUMBAR_MODE_MSG
    $NUMBAR_MODE_TOT
    $NUMBAR_MODE_CHG
);

our $NUMBAR_MODE_AMT = 'A';    # Amount mode
our $NUMBAR_MODE_TOT = 'T';    # Total mode
our $NUMBAR_MODE_CHG = 'C';    # Change mode
our $NUMBAR_MODE_MSG = 'M';    # Message mode

my $FW = 250;
my $FH = 400;

### TODO: Make {amt} be in pure cents, and set/get work in cents only

#
# Make a new numbers panel (numbar + numpad)
#
sub new {
    my ($class, $parent_frame, $htx) = @_;
    my $this = $parent_frame->Frame(
        -borderwidth => 3,
        -relief      => 'ridge',
        -background  => $COLOR_DIM,
        -width       => $FW,
        -height      => $FH,
    );
    $this->{wantsize} = [-width => $FW, -height => $FH];
    $this->{amt}      = 0;                                 # Current numeric amount in main display
    $this->{mode}     = $NUMBAR_MODE_AMT;
    $this->{lbl_dsp}  = undef;                             # Label for main display value
    $this->{lbl_amt}  = undef;                             # Label for amount mode
    $this->{lbl_tot}  = undef;                             # Label for total mode
    $this->{lbl_chg}  = undef;                             # Label for change mode
    $this->{lbl_msg}  = undef;                             # Label for message mode
    $this->{msg_tmr}  = undef;                             # Timer handle for timed messages
    $this->{htx}      = $htx;
    bless($this, $class);
    return $this;
}

#
# Populate this frame
#
sub fill {
    my $this = shift;
    my $htx  = $this->{htx};

    # Number bar (numbar)
    my $nbf = $this->Frame(-borderwidth => 1, -relief => 'groove')->form(
        -left   => '%1',
        -right  => '%99',
        -top    => '%1',
        -bottom => '%20'
    );
    $this->{lbl_dsp} = $nbf->Label(-text => '0', -font => $FONT_XL, -wraplength => 220)->pack(
        -padx   => 5,
        -side   => 'bottom',
        -anchor => 'se',
        -expand => 1
    );

    # Numbar mode
    $this->{lbl_amt} = $nbf->Label(
        -text       => 'Amount',
        -font       => $FONT_SM,
        -foreground => $COLOR_FG
    )->pack(-padx => 5, -side => 'left', -anchor => 'nw', -expand => 1);
    $this->{lbl_tot} = $nbf->Label(
        -text       => 'Total',
        -font       => $FONT_SM,
        -foreground => $COLOR_DIM
    )->pack(-padx => 5, -side => 'left', -anchor => 'n', -expand => 1);
    $this->{lbl_chg} = $nbf->Label(
        -text       => 'Chg',
        -font       => $FONT_SM,
        -foreground => $COLOR_DIM
    )->pack(-padx => 5, -side => 'left', -anchor => 'n', -expand => 1);
    $this->{lbl_msg} = $nbf->Label(
        -text       => 'Msg',
        -font       => $FONT_SM,
        -foreground => $COLOR_DIM
    )->pack(-padx => 5, -side => 'left', -anchor => 'ne', -expand => 1);

    # Keypad
    my $kf = $this->Frame(-borderwidth => 1, -relief => 'groove')->form(
        -left   => '%1',
        -right  => '%99',
        -top    => '%20',
        -bottom => '%99'
    );

    my $i = 0;
    foreach my $n (qw{7 8 9 4 5 6 1 2 3 . 0 C}) {
        my $this->{"lbl_key_$n"} = $kf->Button(
            -text    => $n,
            -font    => $FONT_XXL,
            -command => sub {$this->keypress($n);}
            )->grid(
            -row    => int($i / 3),
            -column => $i % 3,
            -sticky => 'nsew'
            );
        ++$i;
    }

    # Keyboad bindings
    foreach my $key (0 .. 9) {
        $htx->{mw}->bind("<Key-$key>" => sub {$this->keypress($key);});
        $htx->{mw}->bind("<KP_$key>"  => sub {$this->keypress($key);});
    }
    $htx->{mw}->bind("<period>" => sub {$this->keypress(q{.});});
    $htx->{mw}->bind("<Key-c>"  => sub {$this->keypress(q{C});});
    $htx->{mw}->bind("<Key-C>"  => sub {$this->keypress(q{C});});

    # Numeric keypad bindings
    $htx->{mw}->bind("<KP_Insert>"    => sub {$this->keypress(q{0});});
    $htx->{mw}->bind("<KP_End>"       => sub {$this->keypress(q{1});});
    $htx->{mw}->bind("<KP_Down>"      => sub {$this->keypress(q{2});});
    $htx->{mw}->bind("<KP_Page_Down>" => sub {$this->keypress(q{3});});
    $htx->{mw}->bind("<KP_Left>"      => sub {$this->keypress(q{4});});
    $htx->{mw}->bind("<KP_Begin>"     => sub {$this->keypress(q{5});});
    $htx->{mw}->bind("<KP_Right>"     => sub {$this->keypress(q{6});});
    $htx->{mw}->bind("<KP_Home>"      => sub {$this->keypress(q{7});});
    $htx->{mw}->bind("<KP_Up>"        => sub {$this->keypress(q{8});});
    $htx->{mw}->bind("<KP_Page_Up>"   => sub {$this->keypress(q{9});});
    $htx->{mw}->bind("<KP_Delete>"    => sub {$this->keypress(q{.});});

    return $this;
}

#
# Handler for a keypad press
#
sub keypress {
    my ($this, $key) = @_;
    my $mw = $this->{htx}->{mw};
    $this->{amt} = 0
        if $this->{mode} ne $NUMBAR_MODE_AMT;
    if ($key =~ m/^\d+$/) {
        return $mw->bell()
            if $this->{amt} =~ m{\.\d{2}};    # max two decimal digits
        $this->{amt} .= $key;
    }
    elsif ($key eq q{.}) {
        return $mw->bell()
            if $this->{amt} =~ m/\./;         # already got decimal pt
        $this->{amt} .= $key;
    }
    elsif ($key eq 'C') {
        $this->{amt} = 0;
    }
    else {
        return $mw->bell();                   # Bad key
    }
    $this->set_amt($this->{amt});
}

sub get_amt {
    my $this = shift;
    return 0 if $this->{mode} ne $NUMBAR_MODE_AMT;
    return $this->{amt};
}

sub get_chg {
    my $this = shift;
    return 0 if $this->{mode} ne $NUMBAR_MODE_CHG;
    return $this->{amt};
}

sub get_tot {
    my $this = shift;
    return 0 if $this->{mode} ne $NUMBAR_MODE_TOT;
    return $this->{amt};
}

sub set {
    my ($this, $mode, $val) = @_;
    return $this->set_amt($val) if $mode eq $NUMBAR_MODE_AMT;
    return $this->set_tot($val) if $mode eq $NUMBAR_MODE_TOT;
    return $this->set_chg($val) if $mode eq $NUMBAR_MODE_CHG;
    return $this->set_msg($val) if $mode eq $NUMBAR_MODE_MSG;
    return "Bad mode: $mode";
}

sub set_amt {
    my ($this, $val) = @_;
    if ($this->{msg_tmr}) {
        $this->afterCancel($this->{msg_tmr});
        $this->{msg_tmr} = undef;
    }

    $this->{amt}  = $val;
    $this->{mode} = $NUMBAR_MODE_AMT;
    $this->{lbl_amt}->configure(-foreground => $COLOR_FG);
    $this->{lbl_tot}->configure(-foreground => $COLOR_DIM);
    $this->{lbl_chg}->configure(-foreground => $COLOR_DIM);
    $this->{lbl_msg}->configure(-foreground => $COLOR_DIM);
    $val =~ s{^0}{};
    $val =~ s{^\.}{0.};
    $val = "0" if $val eq q{};
    $val = commify($val);
    $this->{lbl_dsp}->configure(
        -foreground => $COLOR_FG,
        -font       => $FONT_XL,
        -text       => $val
    );

    # Test output
    if ($TESTMODE && open (F, '>', $TESTFILE)) {
        print F "Amt: $val\n";
        close F;
    }
}

sub set_tot {
    my ($this, $val) = @_;
    if ($this->{msg_tmr}) {
        $this->afterCancel($this->{msg_tmr});
        $this->{msg_tmr} = undef;
    }

    $this->{amt}  = $val;
    $this->{mode} = $NUMBAR_MODE_TOT;
    $this->{lbl_amt}->configure(-foreground => $COLOR_DIM);
    $this->{lbl_tot}->configure(-foreground => $COLOR_FG);
    $this->{lbl_chg}->configure(-foreground => $COLOR_DIM);
    $this->{lbl_msg}->configure(-foreground => $COLOR_DIM);
    my $txt = q{$} . commify(sprintf('%4.2f', $val));
    $this->{lbl_dsp}->configure(
        -foreground => $COLOR_FG,
        -font       => $FONT_XL,
        -text       => $txt
    );

    # Test output
    if ($TESTMODE && open (F, '>', $TESTFILE)) {
        print F "Tot: $txt\n";
        close F;
    }
}

sub set_chg {
    my ($this, $val) = @_;
    if ($this->{msg_tmr}) {
        $this->afterCancel($this->{msg_tmr});
        $this->{msg_tmr} = undef;
    }

    $this->{amt}  = $val;
    $this->{mode} = $NUMBAR_MODE_CHG;
    $this->{lbl_amt}->configure(-foreground => $COLOR_DIM);
    $this->{lbl_tot}->configure(-foreground => $COLOR_DIM);
    $this->{lbl_chg}->configure(-foreground => $COLOR_FG);
    $this->{lbl_msg}->configure(-foreground => $COLOR_DIM);
    my $txt;

    if ($val < 0) {
        $txt = "Need\n\$" . commify(sprintf('%4.2f', -$val));
        $this->{lbl_dsp}->configure(
            -foreground => $COLOR_RED,
            -font       => $FONT_LG,
            -text       => $txt
        );
    }
    else {
        $txt = q{$} . commify(sprintf('%4.2f', $val));
        $this->{lbl_dsp}->configure(
            -foreground => $COLOR_DKGRN,
            -font       => $FONT_XL,
            -text       => $txt
        );
    }

    # Test output
    if ($TESTMODE && open (F, '>', $TESTFILE)) {
        print F "Chg: $txt\n";
        close F;
    }
}

sub set_msg {
    my ($this, $msg, $timeout) = @_;
    if ($this->{msg_tmr}) {
        $this->afterCancel($this->{msg_tmr});
        $this->{msg_tmr} = undef;
    }

    my $old_mode = $this->{mode};
    $this->{mode} = $NUMBAR_MODE_MSG;
    $this->{lbl_amt}->configure(-foreground => $COLOR_DIM);
    $this->{lbl_tot}->configure(-foreground => $COLOR_DIM);
    $this->{lbl_chg}->configure(-foreground => $COLOR_DIM);
    $this->{lbl_msg}->configure(-foreground => $COLOR_FG);
    $this->{lbl_dsp}->configure(
        -foreground => $COLOR_VIO,
        -font       => $FONT_MD,
        -text       => $msg
    );

    # Timeout?
    if (($old_mode ne $NUMBAR_MODE_MSG) && $timeout) {
        my $old_amt = $this->{amt};
        $this->{msg_tmr} = $this->after($timeout, sub {$this->set($old_mode, $old_amt)});
    }

    # Test output
    if ($TESTMODE && open (F, '>', $TESTFILE)) {
        print F "Msg: $msg\n";
        close F;
    }
}

1;
