#=============================================================================
#
# Hauntix Point of Sale GUI - Generic Error Popup Dialog Box
#
#-----------------------------------------------------------------------------

use strict;
use warnings;
use FindBin;
use Tk;
use Tk::Dialog;

package htx::pop_error;
use htx;
use htx::pos_style;

#
# Display an error popup
#
sub show {
    my $htx  = shift;
    my $text = shift;
    my %opts = _c(@_);
    my $parent = $htx->{mw};
    my $box    = $parent->DialogBox(
        -title          => "Error",
        -default_button => "Close",
        -buttons        => ["Close","Hold"]
    );
    $box->Subwidget("B_Close")->configure(-font => $FONT_LG);
    $box->Subwidget("B_Hold") ->configure(-font => $FONT_LG, -state => 'disabled');

    my $f = $box->add('Frame')
                ->grid(-row => 0, -column => 0, -sticky => 'nsew');
    # wrap text if long
    my $wtext = join("\n", _wrap($text, 80, 100));
    $f->Label(-text => $wtext,
              -font => $FONT_MD)->pack;

    if (!$opts{keep}) {
        my $id = $box->after(7000, sub{$box->Exit; 
                                       $box->destroy;
                                       exit $opts{exit} if defined $opts{exit};
                                      });
        $box->Subwidget("B_Hold")
            ->configure(-state => 'normal',
                        -command => sub {
                                    $box->afterCancel($id);
                                    $box->Subwidget("B_Hold")->configure(-state => 'disabled');
                                    });
    }
    if (defined $opts{exit}) {
        $box->Subwidget("B_Close")->configure(-command => sub {
                exit $opts{exit};
            });
    }

    $parent->bell;
    return $box->Show();
}

# Long line splitter
sub _wrap {
    my ($msg, $min, $max) = @_;
    return ($msg)
        if !defined $msg
            || $max < 3
            || $min > $max;

    # First split on newlines
    my @lines = ();
    foreach my $line (split(/\n/, $msg)) {
        my $split = $line;

        # Then if each segment is more than the width, wrap it
        while (length($split) > $max) {

            # Look backwards for whitespace to split on
            my $pos = $max;
            while ($pos >= $min) {
                if (substr($split, $pos, 1) =~ m{\s}sxm) {
                    $pos++;
                    last;
                }
                $pos--;
            }
            $pos = $max if $pos < $min;    #no good place to break, use the max

            # Break it
            my $chunk = substr($split, 0, $pos);
            $chunk =~ s{\s+$}{}sxm;
            push @lines, $chunk;
            $split = substr($split, $pos, length($split) - $pos);
        }
        $split =~ s{\s+$}{}sxm;            #trim
        push @lines, $split;
    }
    return @lines;
}

1;
