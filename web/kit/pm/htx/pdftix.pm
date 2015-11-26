#=============================================================================
#
# Hauntix Point of Sale - PDF Ticket Creator
#   Creates a PDF file containing one or more tickets
#
#-----------------------------------------------------------------------------

### TODO:  Optionally include transaction receipt page at end

use strict;
use warnings;
use lib ($ENV{HOME}          || q{}) . q{/pm};
use lib ($ENV{DOCUMENT_ROOT} || q{}) . q{/../pm};
use htx;
use Config::Std;
use Date::Manip;
use Getopt::Long;

### Test section
if (@ARGV) {
    my $opts = {};
    GetOptions ($opts, 
                "trnid|t:s",
                "trnPickupCode|p:s",
                ) or die "*** Bad options\n";

    my $htx = {};
    read_config $CONFIG_FILE => $htx->{cfg};
    my $trn = new htx::transaction(-htx => $htx, %$opts);
    push @{$trn->{tickets}}, new htx::ticket(-tixid => 947301);
    push @{$trn->{tickets}}, new htx::ticket(-tixid => 947308);
    push @{$trn->{tickets}}, new htx::ticket(-tixid => 947315);
    push @{$trn->{tickets}}, new htx::ticket(-tixid => 947322);
    push @{$trn->{tickets}}, new htx::ticket(-tixid => 947329);
    push @{$trn->{tickets}}, new htx::ticket(-tixid => 947336);
    push @{$trn->{tickets}}, new htx::ticket(-tixid => 947343);
    push @{$trn->{tickets}}, new htx::ticket(-tixid => 947350);

    my $pdftix = new htx::pdftix(-htx => $htx,
                                 -transaction => $trn);
    $pdftix->gentix;
    print "File=".$pdftix->{filename}."\n";
    exit 0;
}
### End test section

package htx::pdftix;
use htx;
use htx::transaction;
use htx::sale;
use htx::ticket;
use PDF::API2;

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

my $TH;
my $TW;
my @TPOS;

#
# Creates a new ticket object and a new record in the database
#   If a tixId is given, then we do not create the database record.
#
sub new {
    $TH = 8.0/3/in;
    $TW = 7.5/2/in;
    @TPOS = (
        [0.5/in+$TW, 0.5/in        ], # 6=0
        [0.5/in    , 0.5/in + 2*$TH], # 1
        [0.5/in+$TW, 0.5/in + 2*$TH], # 2
        [0.5/in    , 0.5/in + 1*$TH], # 3
        [0.5/in+$TW, 0.5/in + 1*$TH], # 4
        [0.5/in    , 0.5/in        ], # 5
    );

    my $class = shift;
    my %cargs = _c(@_);
    my $this  = {
        err         => q{},
        htx         => $cargs{htx},
        transaction => $cargs{transaction},    # The transaction that has tickets to generate
        filename    => q{},                    # Filename of the PDF tickets
        pdf         => undef,                  # PDF object
        currpage    => undef,                  # Current PDF Page object
    };

    $this->{filename} = 'htx-tix-' . $this->{transaction}->fmtpickup() . '.pdf';
    bless($this, $class);
    return $this;
}

# Return current error status
sub error {
    my $this = shift;
    return $this->{err};
}

# Produce the PDF file with *all* the tickets in the transaction
sub gentix {
    my $this = shift;
    my $htx  = $this->{htx};
    my $cfg  = $htx->{cfg};

    my $trn = $this->{transaction};
    my $trnid = $trn->trnid();

    my $intro   = $cfg->{haunt}->{intro}            || q{};
    my $name    = $cfg->{haunt}->{name}             || 'Haunted House';
    my $desc    = $cfg->{haunt}->{desc}             || q{};
    my $slogan  = $cfg->{haunt}->{slogan}           || q{};
    my $site    = $cfg->{haunt}->{site}             || q{};
    my $website = $cfg->{haunt}->{website}          || q{};
    my $addr0   = $cfg->{haunt}->{addr0}            || q{};
    my $addr1   = $cfg->{haunt}->{addr1}            || q{};
    my $addr2   = $cfg->{haunt}->{addr2}            || q{};
    my $rftype  = $cfg->{haunt}->{refund_type}      || q{};
    my $rfstmt  = $cfg->{haunt}->{refund_statement} || q{};

    my $pdf = PDF::API2->new(-file => $this->{filename});
    $pdf->preferences(
        -fullscreen => 0,
        -onecolumn  => 1,
    );
    $pdf->info(
        'Author' => "HaunTix $htx::HTX_VERSION TID$trnid",

        #    'CreationDate' => "D:20020911000000+01'00'",   ### TODO
        #    'ModDate'      => "D:YYYYMMDDhhmmssOHH'mm'",   ### TODO
        'Creator'  => "HaunTix Ticketing System",
        'Producer' => "PDF::API2",
        'Title'    => "$name Tickets",
        'Subject'  => "Enjoy The Show!",
        'Keywords' => "$name Tickets"
    );
    $pdf->mediabox(8.5/in, 11.0/in);
    #$pdf->bleedbox(  5/mm,   5/mm,  100/mm,   143/mm);
    $pdf->cropbox(0/in, 0/in, 8.5/in, 11/in);
    $pdf->artbox(0.5/in, 0.5/in, 7.5/in, 10.0/in);
    $this->{pdf} = $pdf;
    my $font = $this->{font} = $pdf->corefont('Helvetica');

    # Prepare images
    my $picture = "../../html/hmTitleText.png";
    die("Unable to find image file: $!") unless -e $picture;
#    my $photo_file = $pdf->image_jpeg($picture);
    $this->{tiximg} = $pdf->image_png($picture);

    # Create each page of tickets
    my $tpp  = $this->{tpp} = $cfg->{'ticket_layout.web'}->{tickets_per_page} || 6;
    my $tnum = 0;                                                      # Ticket number
    my $pnum = 0;                                                      # Page number
    my $ntix = @{$trn->{tickets}};                     # Number of tickets
    my $pmax = int(($ntix + $tpp - 1) / $tpp);                         # Last page number
    for my $tix (@{$trn->{tickets}}) {

        # Create new page?
        $this->_mkpage(++$pnum, $pmax) if ($tnum++ % $tpp) == 0;
        my $page = $this->{currpage};
        
        # Build the ticket
        $this->_gen_one_tix($tix, $tnum, $ntix);
    }

    # No tickets?
    if (!$ntix) {
        my $page = $this->_mkpage(1, 1);
        my $text = $page->text;
        $text->font($font, 13/pt);
        $text->fillcolor('black');
        $text->translate(4.25/in, 5.5/in);
        $this->{err} = 'There are no tickets for this transaction.';
        $text->text_center($this->{err});
    }

    $pdf->save();
}

# Generate the content of one ticket on the page
### TODO:  Emit the output using a general layout description, 
### instead of hardcoded like it is.
sub _gen_one_tix {
    my $this = shift;
    my $htx  = $this->{htx};
    my $cfg  = $htx->{cfg};

    my $tix  = shift;
    my ($tnum, $tmax) = @_;

    my $trn  = $this->{transaction};
    my $tpp  = $this->{tpp};
    my $pdf = $this->{pdf};
    my $tpos = $tnum % $tpp;
    my ($dx, $dy) = @{$TPOS[$tpos]};
    my $page = $this->{currpage};
    my $gfx  = $page->gfx;
    my $font = $this->{font};
    my $text = $page->text;
    $text->fillcolor('black');

    # Ticket border
    $gfx->strokecolor('green');
    $gfx->linedash(0.15/in);
    $gfx->rect($dx, $dy, $TW-3, $TH-3);
    $gfx->stroke;
    $gfx->linedash(); # back to solid

    # Show & time information
    my $intro   = $cfg->{haunt}->{intro}            || q{};
    my $name    = $cfg->{haunt}->{name}             || 'Haunted House';
    my $desc    = $cfg->{haunt}->{desc}             || q{};
    my $slogan  = $cfg->{haunt}->{slogan}           || q{};
    my $site    = $cfg->{haunt}->{site}             || q{};
    my $website = $cfg->{haunt}->{website}          || q{};
    my $addr0   = $cfg->{haunt}->{addr0}            || q{};
    my $addr1   = $cfg->{haunt}->{addr1}            || q{};
    my $addr2   = $cfg->{haunt}->{addr2}            || q{};
    my $rftype  = $cfg->{haunt}->{refund_type}      || q{};
    my $rfstmt  = $cfg->{haunt}->{refund_statement} || q{};
    my $apolicy = $tix->{tixNote} || $cfg->{haunt}->{arrival_policy} || q{Please arrive 5 minutes early.};
    my $sale    = $tix->{sale};
    my $show    = $tix->{show};
    my $salName = $sale->{salName} || 'General Admission';  ### ||-part is TEMP
    my $tclass  = $show->{shoClass} || 'REG';   ## ||-part is TEMP
    my $trnId = $sale->{trnId};
    my $when1 = $sale->{salIsTimed}
              ? UnixDate($show->{shoTime}, q{%a %d-%b-%Y %H:%M})
              : $salName;
    $when1 =~ s/AM$/a/;
    $when1 =~ s/PM$/p/;
    my $when2 = $sale->{salIsTimed}
              ? UnixDate($show->{shoTime}, q{%I:%M%p %a - %d %b})
              : $salName;
    $when2 =~ s/^0//g;
    ###$when2 =~ s/\s0//g;
    $when2 =~ s/AM/am/;
    $when2 =~ s/PM/pm/;
#    $drv->cmd("2911A08" . "0437" . "0170" . $intro);
    $text->font($font, 7/pt);
    $text->translate($dx + 0.05*$TW, $dy + 0.93*$TH);
    $text->text($intro);
#    $drv->cmd("2911A24" . "0430" . "0130" . $name);
#    $drv->cmd("2911A10" . "0413" . "0117" . $desc);
    $text->font($font, 13/pt);
    $text->translate($dx + 0.45*$TW, $dy + 0.70*$TH);
    $text->text_center($desc);
#    $drv->cmd("2911A18" . "0433" . "0085" . $when2);
    $text->font($font, 24/pt);
    $text->cr(-24/pt);
    $text->text_center($when2);
#    $drv->cmd("2911A10" . "0413" . "0068" . $apolicy);
    $text->font($font, 11/pt);
    $text->cr(-12/pt);
    $text->text_center($apolicy);
#    $drv->cmd("2911A10" . "0400" . "0043" . $addr0);
    $text->font($font, 11/pt);
    $text->cr(-14/pt);
    $text->text_center($addr0);
#    $drv->cmd("2911A12" . "0407" . "0025" . $website);
    $text->font($font, 13/pt);
    $text->cr(-14/pt);
    $text->text_center($website);
#    $drv->cmd("2911A08" . "0421" . "0007" . $rfstmt);
    $text->font($font, 9/pt);
    $text->cr(-13/pt);
    $text->text_center($rfstmt);


    # Put two barcodes on each ticket
    $this->_barcode(
        -x      => $dx + $TW/2,
        '-y'    => $dy + $TH*0.03,
        -text   => $tix->tixno);
    $this->_barcode(
        -rotate => 90,
        -height => 17/pt,
        -x      => $dx + $TW*0.97,
        '-y'    => $dy + $TH/2,
        -text   => $tix->tixno);

    # Add a graphics picture
    my $image = $this->{tiximg};
    $gfx->image($image, $dx+ 0.05*$TW, $dy + 0.73*$TH, $TW*0.80, $TH*0.20);

    # Little stuff
    $text->font($font, 9/pt);
    $text->translate($dx + 5, $dy + 5);
    $text->text("P " . $trn->fmtpickup);

    $text->translate($dx + $TW - 5, $dy + 5);
    $text->text_right("Ticket $tnum of $tmax");
   
}

# Create a new page; working area is 7.5" x 10"
sub _mkpage {
    my $this = shift;
    my ($pnum, $pmax) = @_;
    my $htx  = $this->{htx};
    my $cfg  = $htx->{cfg};
    my $pdf  = $this->{pdf};
    my $font = $this->{font};

    # Create the page
    my $page = $this->{currpage} = $pdf->page;

#my $blue_box = $page->gfx;
#$blue_box->strokecolor('darkblue');
#$blue_box->linedash(0.1/in);
#$blue_box->rect(0.5/in, 0.5/in, 7.5/in, 10/in);
#$blue_box->stroke;
#$blue_box->linedash(); # back to solid


    # Header stuff
    my $intro = $cfg->{haunt}->{intro} || q{};
    my $name  = $cfg->{haunt}->{name}  || 'Haunted House';
    my $desc  = $cfg->{haunt}->{desc}  || q{};

    my $text = $page->text;
    $text->fillcolor('black');
    $text->font($font, 9/pt);
    $text->translate(4.25/in, 10.3/in);
    $text->text_center($intro);
    $text->font($font, 35/pt);
    $text->translate(4.25/in, 9.85/in);
    $text->text_center($name);
    $text->font($font, 13/pt);
    $text->translate(4.25/in, 9.61/in);
    $text->text_center($desc);

    my $trnid = $this->{transaction}->trnid();
    $text->font($font, 9/pt);
    $text->translate(7.9/in, 9.55/in);
    $text->text_right("Transaction $trnid");

    $text->font($font, 13/pt);
    $text->fillcolor('navy');
    $text->translate(1.0/in, 9.25/in);
    $text->text("These are your ticket(s).  Keep them safe.  If you are attending as a group, ");
    $text->cr(-13/pt);
    $text->text("you do not need to cut them apart.  Otherwise carefully cut the tickets ");
    $text->cr(-13/pt);
    $text->text("along the dotted lines and give one to each person.  Please do not fold your");
    $text->cr(-13/pt);
    $text->text("tickets; the barcode and ticket number must be in good condition.  Thanx!");

#    my $gfx = $page->gfx;
#    $gfx->strokecolor('red');
#    $gfx->move(0.5 / in, 9.5 / in);
#    $gfx->line(8.0 / in, 9.5 / in);
#    $gfx->stroke;

    # Footer stuff
#    $gfx->strokecolor('red');
#    $gfx->move(0.5 / in, 0.5 / in);
#    $gfx->line(8.0 / in, 0.5 / in);
#    $gfx->stroke;

    $text->font($font, 9/pt);
    $text->translate(4.25/in, 0.35/in);
    $text->text_center("Page $pnum of $pmax");
    
    return $this->{currpage};
}

# Since the PDF::API2 barcodes don't work, we draw our own
#   barcode(
#       -page => $page,         # Page to draw this on, required
#       -text => $text,         # The text we're encoding, required
#       -barcolor => $color,    # Color of the bar, default=black
#       -textcolor => $color,   # Color of the HRI text, default=black
#       -textfont => $fnt,      # Font for the HRI text, default=Helvetica
#       -textsize => 12,        # Point size of the HRI text, default=12pt
#       -textspot => 1,         # Where to show HRI text, 0=not shown, default=1, 0-5
#       -x => $x, -y => $y,     # Position of start corner
#       -height => $height,     # Height of bars, default 36pt
#       -barwidth => $bwid,     # Width of one unit bar, default 1.5pt
#       -rotate => $angle,      # Rotation angle for whole thing
#       );
sub _barcode {
    my $this = shift;
    my %args = @_;
    my $pdf  = $this->{pdf};
    my $page = $this->{currpage};    # Required
    my $text = $args{'-text'};
    return $this->{err} = "No -text given to barcode()\n" 
        if !exists $args{'-text'};
    my $x0        = $args{'-x'}         || 0;
    my $y0        = $args{'-y'}         || 0;
    my $h         = $args{'-height'}    || 36;
    my $w         = $args{'-width'}     || 1.5; # pts
    my $fat       = $args{'-thickness'} || 0.90; # thickness of a bar in its width; accounts for ink bleed (0.0-1.0)
    my $r         = $args{'-rotate'}    || 0;
    my $barcolor  = $args{'-barcolor'}  || 'black';
    my $textcolor = $args{'-textcolor'} || 'black';
    my $textfont  = $args{'-textfont'}  || 'Helvetica';
    my $textsize  = $args{'-textsize'}  || 12;

    # Make a barcode string of spaces and hashes
    require Barcode::Code128;    # PDF::API2 barcodes are bad; we use this to make our own.
    my $bc    = new Barcode::Code128;
    my $bcstr = $bc->barcode($text);

    # Transform the coordinate system into place
    my $gfx = $page->gfx;
    $gfx->save;
    $gfx->transform(
        -translate => [$x0, $y0],
        -rotate    => $r,
    );

    # Draw the bars
    my $x = -$w * length($bcstr)/2;
    $gfx->fillcolor($barcolor);
    foreach my $b (split //, $bcstr) {
        if ($b ne q{ }) {
            $gfx->rect($x, $textsize, $w*$fat, $h);
            $gfx->fill;
        }
        $x += $w;
    }

    # Draw the HRI text
    my $txt = $page->text;
    my $font = $pdf->corefont($textfont);
    $txt->font($font, $textsize);
    $txt->fillcolor($textcolor);
    $txt->transform(
        -translate => [$x0, $y0],
        -rotate    => $r,
    );
    my $spaced_text = join(' ', split(//, $text));
    $txt->text_center($spaced_text);

    $gfx->restore;
}

1;
