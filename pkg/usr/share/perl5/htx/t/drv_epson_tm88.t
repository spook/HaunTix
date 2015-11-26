#!/usr/bin/perl -w
# Test script for the hauntix Epson TM88 print driver module

use htx::drv_epson_tm88;

my $drv = new htx::drv_epson_tm88;
$drv->queue("receipt-3");

# Normal stuff
$drv->say(q{-}x42);
$drv->say("Beginning the test print.");
$drv->say("Left justified","left");
$drv->say("Center justified","center");
$drv->say("Right justified","right");
$drv->say;
$drv->say("Blank line above & below, and this should be left justified and the lines should wrap to three lines.");
$drv->say;

$drv->put("Here's ");
$drv->put("a line ");
$drv->put("made in ");
$drv->say("parts.");
$drv->say;

$drv->put("Modes: ");
$drv->put("bold ", "bold");
$drv->put("under ","under");
$drv->put("tiny",  "tiny");
$drv->put("wide ", "wide");
$drv->put("tall ", "tall");
$drv->put("rev ",  "rev");
$drv->put("flip ", "flip");  # flip must be on a whole line
$drv->say("end.");

$drv->put("Wide", "wide");
$drv->put(" and ");
$drv->put("Fat", "fat");
$drv->say(" are the same.");

$drv->say("Next line tries left center & right mixed");  # not supported
$drv->put("RRR", "right");
$drv->put("LLL", "left");
$drv->put("CCC", "center");
$drv->say();
$drv->say();

$drv->say("Flipped text","flip");
$drv->say("upside-down bold tiny centered text","flip,bold,tiny,center");

$drv->barcode("123456789010","center");
$drv->barcode("123456789011","left");
$drv->barcode("123456789012","right");
$drv->barcode("123456789013","center,flip");

$drv->say("Combined modes:");
$drv->say("Bold under", "bold under");
# Todo - permute all combinations

# Send the page
$drv->feed_and_cut;
$drv->submit;