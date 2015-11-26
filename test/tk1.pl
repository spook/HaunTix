#!/usr/bin/perl -w
use Tk;

my $mw = MainWindow->new;
$mw->title("Tk1");

my $l1 = $mw->Label(-text=>"lable one")->pack;
$mw->Button(-text => "Some button")->pack();
$mw->Button(-text => "Exit")->pack();

MainLoop;

