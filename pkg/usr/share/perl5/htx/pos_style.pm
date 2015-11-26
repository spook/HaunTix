#=============================================================================
#
# Hauntix Point of Sale GUI - Style constants
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

package htx::pos_style;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
    $COLOR_BG
    $COLOR_FG
    $COLOR_NOP
    $COLOR_DIM
    $COLOR_LIT
    $COLOR_BLUE
    $COLOR_RED
    $COLOR_LTRED
    $COLOR_GOLD
    $COLOR_VIO
    $COLOR_DKGRN
    $COLOR_LTGRN
    $COLOR_BTN_NOP
    $COLOR_BTN_TIX
    $COLOR_BTN_MCH
    $COLOR_BTN_UPG
    $COLOR_BTN_DSC
    $COLOR_TXT_NOP
    $COLOR_TXT_TIX
    $COLOR_TXT_MCH
    $COLOR_TXT_UPG
    $COLOR_TXT_DSC
    $COLOR_YELLOW
    $FONT_XXL
    $FONT_XL
    $FONT_LG
    $FONT_BG
    $FONT_MD
    $FONT_SM
    $FONT_XS);

our $COLOR_BG    = "#555533";    # green-ish
our $COLOR_FG    = "#000000";
our $COLOR_NOP   = "#e3e3e3";
our $COLOR_DIM   = "#aaaaaa";
our $COLOR_LIT   = "#ddddcc";
our $COLOR_RED   = "maroon";
our $COLOR_LTRED = "#ffcccc";
our $COLOR_BLUE  = "navy";
our $COLOR_GOLD  = "#e3dcc5";
our $COLOR_VIO   = "#553355";
our $COLOR_DKGRN = "#555533";
our $COLOR_LTGRN = "#c5e3c5";
our $COLOR_YELLOW = "yellow";

our $COLOR_BTN_NOP = "#e3e3e3";  # Unused POS button background
our $COLOR_BTN_TIX = "#c5e3c5";  # Product button background (green-ish)
our $COLOR_BTN_MCH = "#e3dcc5";  # Taxable Product button background (gold-ish)
our $COLOR_BTN_UPG = "#c5c5e3";  # Upgrade button background (blue-ish)
our $COLOR_BTN_DSC = "#e3c5c5";  # Discount button background (red-ish)

our $COLOR_TXT_NOP = "black";      # Ordinary text
our $COLOR_TXT_TIX = "#008000";    # Ticket text (green-ish)
our $COLOR_TXT_MCH = "#806000";    # Merchandise text (gold-ish)
our $COLOR_TXT_UPG = "#000080";    # Upgrade text (blue-ish)
our $COLOR_TXT_DSC = "#800000";    # Discount text (red-ish)


our $FONT_XXL = "sans-serif 35";    # Standard extra extra large font
our $FONT_XL  = "sans-serif 28";    # Standard extra large font
our $FONT_LG  = "sans-serif 21";    # Standard large font
our $FONT_BG  = "sans-serif 17";    # Standard big font
our $FONT_MD  = "sans-serif 12";    # Standard medium font
our $FONT_SM  = "sans-serif 9";     # Standard small font
our $FONT_XS  = "sans-serif 7";     # Standard extra small font

1;
