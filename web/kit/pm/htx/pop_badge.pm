#=============================================================================
#
# Hauntix Point of Sale GUI - Badge use check popup
#
#-----------------------------------------------------------------------------


# Badge use table
#create table badgeuse (
#    busTimestamp timestamp default now(),
#    busBadge varchar(32),
#    busQuantity int unsigned not null default 0
#    ) ENGINE=InnoDB;


use strict;
use warnings;
use FindBin;
use Tk;
use Tk::Dialog;
use Tk::NumKeypad;
use Tk::FullKeypad;
use Tk::FmtEntry;
use htx::frame;
use htx::pop_error;

package htx::pop_badge;
require Exporter;
our @ISA = qw(Tk::DialogBox);
use htx;
use htx::db;
use htx::pos_style;

my $FW = 300;
my $FH = 400;

#
# Make a new popup
#
sub new {
    my ($class, $parent, $htx) = @_;
    my $this = $parent->DialogBox(
        -title          => "Check Badge Usage",
        -default_button => "Close",
        -buttons        => ["Close"]
    );
    $this->Subwidget("B_Close")->configure(-font => $FONT_LG);
    $this->{wantsize} = [-width => $FW, -height => $FH];
    $this->{htx}      = $htx;
    $this->{bid}    = q{};
    $this->{uses}    = q{};
    $this->{alltix}   = 0;
    $this->{reason}   = q{};
    $this->{prior}    = q{};

    bless($this, $class);
    return $this;
}

sub do_check {
    my $this   = shift;
    my $htx    = $this->{htx};
    my $bid  = $this->{bid};
    my $uses  = $this->{uses};
print "check badge: $bid\nuses: $uses\n\n";
    return unless $bid;

    my $db  = $htx->{db};
    my $sql
        = "SELECT busTimestamp, busQuantity"
        . " FROM badgeuse WHERE busBadge = "
        . $db->quote($bid) . q{;};
    my $recs = $db->select($sql);
    return htx::pop_error::show({mw => $this}, "Database error:\n" . $db->error)
        if $db->error;

    # Show results
    my $total = 0;
    my $result = q{};
    foreach my $rec (@$recs) {
        $result .= $rec->{busTimestamp} . " - used " . $rec->{busQuantity}."\n";
        $total += $rec->{busQuantity};
    }
    $result .= "Total $total Uses for Badge $bid";
    $this->{lbl_msg}->configure(-text => $result);
}

sub do_use_it {
    my $this   = shift;
    my $htx    = $this->{htx};
    my $bid  = $this->{bid};
    my $uses  = $this->{uses};
print "use badge: $bid\nuses: $uses\n\n";
    return unless $bid && $uses;

    return htx::pop_error::show({mw => $this}, "Usage must be a small number")
        if $uses !~ m/^\d+$/;
    return htx::pop_error::show({mw => $this}, "Usage too big, must be 99 or less")
        if $uses > 99;

    my $db  = $htx->{db};
    my $sql
        = "INSERT INTO badgeuse"
        . "  SET busBadge = ". $db->quote($bid) . q{,}
        . "      busQuantity = ". $db->quote($uses) . q{;};

    $db->insert($sql);
    return htx::pop_error::show({mw => $this}, "Database error:\n" . $db->error)
        if $db->error;

    $this->{lbl_msg}->configure(-text => "Badge $bid updated with $uses uses");
}

sub fill {
    my $this = shift;
    my $l = $this->add('Frame')->grid(-row => 0, -column => 0, -sticky => 'nsew');

    # Title
    $l->Label(-font => $FONT_LG, -text => "Check Badge Usage")
        ->grid(-row => 0, -column => 0, -sticky => 'n', -columnspan => 2);

    # First row
    $this->{lbl_bid} = $l->Label(-font => $FONT_LG, -text => "ID Number:")
        ->grid(-row => 1, -column => 0, -sticky => 'nsew');

    my $e_bid = $l->FmtEntry(
        -fcmd           => \&fmt_int,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{bid},
    );
    $e_bid->grid(-row => 1, -column => 1, -sticky => 'nsew');
    $e_bid->bind('<FocusIn>' => sub {$this->{nkp}->configure(-entry => $e_bid)});
    $e_bid->{_pop} = $this;
    $this->{e_bid} = $e_bid;

    $this->{btn_check} = $l->Button(
        -text    => "Check Usage",
        -font    => $FONT_BG,
        -command => sub {$this->do_check},
    )->grid(-row => 1, -column => 2, -sticky => 'ns');


    # Second Row
    $this->{lbl_uses} = $l->Label(-font => $FONT_LG, -text => "Uses:")
        ->grid(-row => 2, -column => 0, -sticky => 'nsew');

    my $e_uses = $l->FmtEntry(
        -fcmd           => \&fmt_int,
        -font           => $FONT_LG,
        -highlightcolor => 'yellow',
        -textvariable   => \$this->{uses},
    );
    $e_uses->grid(-row => 2, -column => 1, -sticky => 'nsew');
    $e_uses->bind('<FocusIn>' => sub {$this->{nkp}->configure(-entry => $e_uses)});
    $e_uses->{_pop} = $this;
    $this->{e_uses} = $e_uses;

    $this->{btn_useit} = $l->Button(
        -text    => "Use It",
        -font    => $FONT_BG,
        -command => sub {$this->do_use_it},
        -state   => 'disabled',
    )->grid(-row => 2, -column => 2, -sticky => 'ns');


    # Result Text
    $this->{lbl_msg} = $l->Label(
        -font       => $FONT_BG,
        -foreground => $COLOR_BLUE,
        -text       => qq{--}
    )->grid(-row => 5, -column => 0, -columnspan => 2, -sticky => 'nsew');

    # Numeric keypad
    $this->{nkp} = $this->NumKeypad(
        -font   => $FONT_XL,
        -entry  => $e_uses,
        -keysub => {'.' => "\x{21d0}"},
        -keyval => {'.' => 'BACKSPACE'},
    )->grid(-row => 0, -column => 1, -sticky => 'nsew');

    # Action bindings
    $this->bind('<cr>' => sub {$this->do_check});
    $this->bind('<Return>' => sub {$this->do_check});
    $this->bind('<KP_Enter>' => sub {$this->do_check});

    return $this;
}

sub fmt_int {
    my ($old, $i, $w) = @_;

    # Make the new string
    my $new = $old;
    $new =~ s/[^\d]//g;    # remove all but digits
    $new = int($new || 0);
    $new = q{} if $new == 0;
    my $j = $i;
    $j = length($new) if $j > length($new);

    # Test fields - are we complete?
    $w->afterIdle(sub {$w->{_pop}->test_fields;});

    return ($new, $j);
}

sub show {
    my $this = shift;
    $this->{e_bid}->focus;
    return $this->Show();
}

sub test_fields {
    my $this = shift;

    # Is there a transaction or ticket number?
    if ($this->{bid} && !$this->{uses}) {
        $this->{btn_check}->configure(-state => 'normal');
        $this->{lbl_uses}->configure(-foreground => $COLOR_FG);
        $this->{e_uses}->configure(-state => 'normal');
        $this->{btn_useit}->configure(-state => 'disabled');
        $this->{lbl_msg}->configure(-text => q{});
    }
    elsif ($this->{bid} && $this->{uses}) {
        $this->{lbl_uses}->configure(-foreground => $COLOR_FG);
        $this->{e_uses}->configure(-state => 'normal');
        $this->{btn_useit}->configure(-state => 'normal');
        $this->{lbl_msg}->configure(-text => q{});
    }
    else {
        $this->{btn_check}->configure(-state => 'disabled');
        $this->{lbl_uses}->configure(-foreground => $COLOR_DIM);
        $this->{e_uses}->configure(-state => 'disabled');
        $this->{btn_useit}->configure(-state => 'disabled');
        $this->{lbl_msg}->configure(-text => q{});
        return 0;
    }

    return 1;
}

1;
