#!/usr/bin/perl -w


            ####### DO NOT USE - see htx-sync instead #######

$| = 1;
sleep 1;    # simple D.O.S. mitigation
use strict;
use warnings;
use lib $ENV{HOME} . q{/pm};
use lib $ENV{DOCUMENT_ROOT} . q{/../pm};

use CGI qw/:standard *table/;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use Config::Std;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use htx;
use htx::charge;
use htx::db;
use htx::sale;
use htx::show;
use htx::ticket;
use htx::transaction;
use JSON;

use constant HTTP_BAD_REQUEST => 400;
use constant HTTP_X_SERVICE_EXCEPTION => 597;

my $htx = {};


# Initialize the CGI object, start the page
my $q = CGI->new;
my $step = $q->param('step') || q{};
my $body = $ENV{REQUEST_METHOD} eq "GET"
         ? $q->param('body') || $q->param('b') || q{}
         : $q->param('POSTDATA');

# Parse the body
my $data = undef;
exit send_http_error($q, HTTP_BAD_REQUEST,
                           "Bad request: No body content found")
    if !$body;
eval {$data = decode_json($body);};
exit send_http_error($q, HTTP_BAD_REQUEST,
                           "Bad request: Content is not valid JSON: $@")
    if $@;
exit send_http_error($q, HTTP_BAD_REQUEST,
                           "Bad request: Content not a hashref")
    if ref($data) ne 'HASH';

# Dispatch
my @stat = $step eq 'wtrn' ? sync_wtrn($q)
         : $step eq 'wtix' ? sync_wtix($q)
         : ("Invalid step: $step")
         ;
exit send_http_error($q, HTTP_X_SERVICE_EXCEPTION, "Service exception: $stat[0]")
    if (@stat == 1) && !ref($stat[0]);
exit send_http_error($q, $stat[0], $stat[1])
    if (@stat >= 2) && !ref($stat[0]) && !ref(stat[1]);
exit send_http_error($q, HTTP_X_SERVICE_EXCEPTION, "Improper service function return value")
    if (@stat != 1) || !ref($stat[0]);

# Encode and send the response
my $json = JSON->new->utf8(1)->convert_blessed(1)->pretty(1)->encode($stat[0]);
print $q->header(-status         => "200 OK",
                 -type           => 'text/plain; charset=utf-8',    ###TEMP: application/json for real
                 -content_length => length($json));
print $json;

exit 0;


# Init
sub init {
    # Globals & config
    eval {read_config $CONFIG_FILE => $htx->{cfg};};
    return "Configuration file error: $@\n" if $@;
    my $cfg = $htx->{cfg};
    
    # Database setup
    my $db = htx::db->new;
    $htx->{db} = $db;
    $db->connect($cfg->{dbweb});
    return "Error opening database: " . $db->error
        if $db->error;

    $db->setup;
    return "Error on setup of database: " . $db->error
        if $db->error;
}

# Error back
sub send_http_error {
    my ($q, $code, $text) = @_;
    print $q->header(-status         => "$code $text",
                     -type           => 'text/plain; charset=utf-8',
                     -content_length => length($text));
    print $text;
    return $code;
}

# Ticket set sync
sub sync_wtix {
    my $q = shift;
    init();
    return (501, "NYI - Not yet implemented WTIX");
}

# Transaction sync
sub sync_wtrn {
    my $q = shift;
    my $ret = {transactions => [],
               charges => [],
               checks => [],    # Should always be empty - no online checks
               sales => [],
               tickets => [],
              };
    init();

    # Find web transactions starting with the given trnId
    my $start_trnId = $q->param("trnId") || 0;
    my $t = new htx::transaction(-htx => $htx, -trnId => 'X');
    my @tids = $t->find(-trnId => {$start_trnId, undef},
                        -trnStation => [qw/W X Y Z/],
                       );
    return (HTTP_X_SERVICE_EXCEPTION,$t->error()) if $t->error();
    $ret->{_trn_sql} = $t->{_sql};  # for testing

    # Pull transactions
    foreach my $trnId (@tids) {
        # this also loads sale, charge, and ticket objects
        my $trn = htx::transaction->load(-htx => $htx, -trnId => $trnId);
        return (HTTP_X_SERVICE_EXCEPTION,$trn->error()) if $trn->error();
        push @{$ret->{transactions}}, $trn;
        push @{$ret->{sales}}, @{$trn->{sales}};
        push @{$ret->{tickets}}, @{$trn->{tickets}};
        push @{$ret->{charges}}, @{$trn->{charges}};
    }


    return $ret;
}

