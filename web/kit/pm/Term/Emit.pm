# This is a dummy Term::Emit module.
# It exports the same functions as Term::Emit, but they all are no-op's or minimal.
# It's used where Term::Emit can't be installed, probably due to
#   not having the privs to get Scope::Upper installed.

package Term::Emit;
use warnings;
use strict;
use 5.008;

use Exporter;
use base qw/Exporter/;

our $VERSION = '0.0.3';
our @EXPORT_OK = qw/emit emit_over emit_prog emit_text emit_done emit_none
                    emit_emerg
                    emit_alert
                    emit_crit emit_fail emit_fatal
                    emit_error
                    emit_warn
                    emit_note
                    emit_info emit_ok
                    emit_debug
                    emit_notry
                    emit_unk
                    emit_yes
                    emit_no/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

sub emit {print "$_[0]...";};
sub emit_over {};
sub emit_prog {};
sub emit_text {};
sub emit_done {print "[".$_[0]."]\n";};

sub emit_emerg {emit_done @_,"EMERG"};  # syslog: Off the scale!
sub emit_alert {emit_done @_,"ALERT"};  # syslog: A major subsystem is unusable.
sub emit_crit  {emit_done @_,"CRIT"};   # syslog: a critical subsystem is not working entirely.
sub emit_fail  {emit_done @_,"FAIL"};   # Failure
sub emit_fatal {emit_done @_,"FATAL"};  # Fatal error
sub emit_error {emit_done @_,"ERROR"};  # syslog 'err': Bugs, bad data, files not found, ...
sub emit_warn  {emit_done @_,"WARN"};   # syslog 'warning'
sub emit_note  {emit_done @_,"NOTE"};   # syslog 'notice'
sub emit_info  {emit_done @_,"INFO"};   # syslog 'info'
sub emit_ok    {emit_done @_,"OK"};     # copacetic
sub emit_debug {emit_done @_,"DEBUG"};  # syslog: Really boring diagnostic output.
sub emit_notry {emit_done @_,"NOTRY"};  # Untried
sub emit_unk   {emit_done @_,"UNK"};    # Unknown
sub emit_yes   {emit_done @_,"YES"};    # Yes
sub emit_no    {emit_done @_,"NO"};     # No
sub emit_none  {emit_done {-silent => 1}, @_, "NONE"};

1;
