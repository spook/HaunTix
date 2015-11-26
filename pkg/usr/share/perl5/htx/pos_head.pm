#=============================================================================
#
# Hauntix Point of Sale GUI - Header
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use Tk;
use htx::frame;

package htx::pos_head;
  require Exporter;
  our @ISA    = qw(Exporter htx::frame);
  our @EXPORT = qw();
  use POSIX qw(strftime);
  use htx::pos_style;

  my $FW = 1024;
  my $FH = 76;

#
# Make a new header
#
sub new {
    my ($class, $parent_frame, $htx) = @_;
    my $this = $parent_frame->Frame(
        -borderwidth => 3,
        -relief      => 'ridge',
        -background  => $COLOR_VIO,
        -width       => $FW,
        -height      => $FH,
    );
    $this->{wantsize} = [-width => $FW, -height => $FH];
    $this->{htx} = $htx;
    bless($this, $class);
    return $this;
}

#
# Fill in the header
#
sub fill {
    my $this = shift;
    $this->userinfo_frame()->form(
        -left   => '%0',
        -right  => '%25',
        -top    => '%0',
        -bottom => '%100'
    );
    $this->title_frame()->form(
        -left   => '%25',
        -right  => '%75',
        -top    => '%0',
        -bottom => '%100'
    );
    $this->status_frame()->form(
        -left   => '%75',
        -right  => '%100',
        -top    => '%0',
        -bottom => '%100'
    );
    return $this;
}

#
# Start things that run in the header (like clocks, status checkers, etc)
#
sub start {
    my $this = shift;
    my $htx  = $this->{htx};

    $htx->{clock_tmr}
        = $this->repeat(1000, sub {_update_current_time($htx->{clock_lbl})});
    $htx->{stat_tmr}
        = $this->repeat(3000, sub {$this->_update_system_status});

    return $this;
}

#
# Stop things that're running in the header
#
sub stop {
    my $this = shift;
    my $htx  = $this->{htx};

    $this->afterCancel($htx->{clock_tmr});

    return $this;
}

sub title_frame {
    my $this = shift;
    my $htx  = $this->{htx};
    my $f    = $this->Frame(-borderwidth => 1, -relief => 'groove');
    $this->{title_f} = $f;
    $f->Label(
        -text       => 'HaunTix Ticketing System',
        -font       => "$FONT_LG bold",
        -foreground => $COLOR_RED,
    )->pack();

    # Setup time clock
    $htx->{clock_lbl} = $f->Label(
        -text => '00:00:00',
        -font => $FONT_MD
    )->pack();
    return $f;
}

sub userinfo_frame {
    my $this = shift;
    my $f = $this->Frame(-borderwidth => 1, -relief => 'groove');
    $this->{user_f} = $f;
    $f->Label(
        -text => 'User info goes here',
        -font => "$FONT_XS bold"
    )->pack();
    $f->Label(
        -text => 'Cashier: ' . $ENV{USER},
        -font => $FONT_SM
    )->pack();
    return $f;
}

sub status_frame {
    my $this = shift;
    my $htx  = $this->{htx};
    my $f    = $this->Frame(-borderwidth => 1, -relief => 'groove');
    $this->{status_f} = $f;
    $f->Label(
        -text => 'System Status',
        -font => "$FONT_SM bold"
    )->grid(-row => 0, -column => 0, -columnspan => 2, -sticky => "ew");
    my $dbstat = $htx->{db} && $htx->{db}->ping? 'OK' : '---';
    $htx->{stat_db_lbl} = $f->Label(
        -text => '--',
        -font => $FONT_XS
    )->grid(-row => 1, -column => 0, -sticky => "w");
    $htx->{stat_sync_lbl} = $f->Label(
        -text => '--',
        -font => $FONT_XS
    )->grid(-row => 2, -column => 0, -sticky => "w");
    $htx->{stat_lan_lbl} = $f->Label(
        -text => '--',
        -font => $FONT_XS
    )->grid(-row => 1, -column => 1, -sticky => "e");
    $htx->{stat_net_lbl} = $f->Label(
        -text => '--',
        -font => $FONT_XS
    )->grid(-row => 2, -column => 1, -sticky => "e");
    return $f;
}

sub _update_current_time {
    my $lbl = shift;
    $lbl->configure(
        -text => strftime("%a %d-%b-%Y %H:%M:%S %Z", localtime(time())));
}

sub _update_system_status {
    my $this = shift;
    my $htx  = $this->{htx};

    my $dbstat = $htx->{db} && $htx->{db}->ping? 'OK' : '---';
    $htx->{stat_db_lbl}->configure(-text => "Database: $dbstat");
    $htx->{stat_sync_lbl}->configure(-text => 'Web-Sync: XX');

    my $lan_stat = qx(ip addr 2>&1) =~ m/eth\d+:\s+\<.*?(LOWER_UP|NO-CARRIER)/sim? $1 : 'Unknown';
    $htx->{stat_lan_lbl}->configure(-text => "LAN: $lan_stat");
    $htx->{stat_net_lbl}->configure(-text => 'Internet: XX');
}

1;
