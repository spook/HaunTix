#!/usr/bin/perl -w

### TODO:  normal header, copyright by me (Steve Roscio), GPL license stuff, etc.
### Then... a complete refactoring of this MESS!  This is what happens when you have
### only a few hours TO GET A WHOLE WEB TICKETING SYSTEM online.  Lots of duplicate,
### ugly code, bad flows, unchecked statii, etc etc...   But it will get us thru
### our first season, then (I hope) i'll have time to clean this up.  Ugh!

$| = 1;
sleep 1;    # simple D.O.S. mitigation
use strict;
use warnings;
use lib $ENV{HOME} . q{/pm};
use lib $ENV{DOCUMENT_ROOT} . q{/../pm};

use CGI::Pretty qw/:standard *table/;    ### TODO:  When done developing, use normal CGI module
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use Config::Std;
use Date::Manip;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use htx;
use htx::cc;
use htx::db;
use htx::show;
use htx::ticket;
use htx::transaction;

my $RE_CC
    = qr{^3(?:[47]\d([ -]?)\d{4}(?:\1\d{4}){2}|0[0-5]\d{11}|[68]\d{12})$|^4(?:\d\d\d)?([ -]?)\d{4}(?:\2\d{4}){2}$|^6011([ -]?)\d{4}(?:\3\d{4}){2}$|^5[1-5]\d\d([ -]?)\d{4}(?:\4\d{4}){2}$|^2014\d{11}$|^2149\d{11}$|^2131\d{11}$|^1800\d{11}$|^3\d{15}$};
my $RE_ZIP   = qr{^((\d{5}-\d{4})|(\d{5})|([A-Z]\d[A-Z]\s\d[A-Z]\d))$};
my $RE_EMAIL = qr{^\w[-._\w]*\@\w[-._\w]*\.\w{2,3}$};
my $RE_CCV   = qr{^\d{3,4}$};

my $EXPM = {
    '0'  => 'month',
    '01' => '01 - January',
    '02' => '02 - February',
    '03' => '03 - March',
    '04' => '04 - April',
    '05' => '05 - May',
    '06' => '06 - June',
    '07' => '07 - July',
    '08' => '08 - August',
    '09' => '09 - September',
    '10' => '10 - October!',
    '11' => '11 - November',
    '12' => '12 - December',
};
my $EXPY = {'0' => 'year'};
for my $y (2013 .. 2021) {$EXPY->{$y - 2000} = $y;}

# Initialize the CGI object, start the page
my $tix_proc_open = 0;
my $q             = CGI->new;

# If not SSL, redirect to our SSL-form
my $url = $q->url(-full=>1, -query=>1);
my $unsafe = $q->param('unsafe');
if (($url =~ m/^http:/i) && !$unsafe) {
    # Redirect to the SSL form of our site
    $url =~ s/^http/https/i;
    print $q->redirect($url, -status => 301);
    exit 0;
}

# Begin the page
print $q->header(
    -charset => 'utf-8',
    -expires => '+13s'
);

print $q->start_html(
    -title  => 'Haunted Mines Tickets',
    -author => 'Hauntix $htx::HTX_VERSION',
    -style  => {
        -src => [
            '/htx/css/reset.css',                       '/htx/css/jquery.validationEngine.css',
            '/htx/css/htx/jquery-ui-1.8.22.custom.css', '/htx/css/htxTix.css',
        ],
    },
    -script => [
        {   -type => 'text/javascript',
            -src  => '../htx/js/jquery-1.7.2.min.js',
        },
        {   -type => 'text/javascript',
            -src  => '../htx/js/jquery.jstepper.min.js',
        },
        {   -type => 'text/javascript',
            -src  => '../htx/js/jquery.validationEngine.js'
        },
        {   -type => 'text/javascript',
            -src  => '../htx/js/jquery.validationEngine-en.js'
        },
        {   -type => 'text/javascript',
            -src  => '../htx/js/jquery-ui-1.8.22.custom.min.js'
        },
        {   -type => 'text/javascript',
            -src  => '../htx/js/htxTix.js'
        },
    ],
);

# Global Params
my $step = lc($q->param('step') || 'buy');
my $shoClass = lc($q->param('shoClass')) eq 'vip' ? 'VIP' : 'REG';
my $seqId  = int($q->param('seqId')  || 0) || time();
my $tixQty = int($q->param('tixQty') || 0);
my $trnId  = int($q->param('trnId')  || 0);

# Standard banner
print q{
  <!--[if IE]>
   <center><a href="http://HauntedMines.org" alt="Haunted Mines Haunted House in Colorado Springs - Home"><img src="/hmTitleText.gif" border="0" alt="Haunted Mines"></a></center>
  <![endif]-->
  <![if !IE]>
   <center><a href="http://HauntedMines.org" alt="Haunted Mines Haunted House in Colorado Springs - Home"><img src="/hmTitleText.png" border="0" alt="Haunted Mines"></a></center>
  <![endif]>
};

# Globals & config
my $htx = {};
eval {read_config $CONFIG_FILE => $htx->{cfg};};
die "Configuration file error: $@\n" if $@;
my $cfg = $htx->{cfg};

# Test mode?
if ($cfg->{system}->{testmode}) {
    print q{<div id="testmode">TEST MODE ENABLED};

    # Show query params
    print qq{\n <table id="debug">\n};
    my %allp = $q->Vars;
    print qq{  <tr><th colspan="2">Params</th></tr>\n};
    my $anyp = 0;
    foreach my $p (sort keys %allp) {
        ++$anyp;
        print q{  <tr><td>}
            . CGI::escapeHTML($p)
            . q{</td><td>}
            . CGI::escapeHTML($allp{$p})
            . qq{</td></tr>\n};
    }
    print qq{  <tr><td>--- No params passed---</td></tr>\n} if !$anyp;

    # Env vars
    print qq{  <tr><th colspan="2">Environment</th></tr>\n};
    my $anyv = 0;
    foreach my $v (sort keys %ENV) {
        ++$anyv;
        print q{  <tr><td>}
            . CGI::escapeHTML($v)
            . q{</td><td>}
            . CGI::escapeHTML($ENV{$v})
            . qq{</td></tr>\n};
    }
    print qq{  <tr><td>--- No environment---</td></tr>\n} if !$anyv;

    # Process info
    print qq{  <tr><th colspan="2">Process</th></tr>\n};
    print qq{  <tr><td>PID</td><td>$$</td></tr>\n};

    # End table, etc
    print qq{ </table>\n};
    print qq{</div>\n};
}

# Check the signature
if (($step ne 'buy') && ($step ne 'pik')) {
    my $wantsig = psig($step);
    my $gotsig = $q->param('sig') || q{-no-sig-};    # crypto sig across the page
    if ($gotsig ne $wantsig) {
        my $err = "This request appears to be a forgery.  Connection terminated.\n";
        print $q->h1("Hauntix Tampering Error");
        print $q->p($err);
##        print $q->p("got=$gotsig want=$wantsig");
        print $q->end_html;
        exit 0;
    }
}

# Database setup
my $db = htx::db->new;
$htx->{db} = $db;
$db->connect($cfg->{dbweb});
die "Error opening database: " . $db->error . "\nDSN=$db->{dsn}\n"
    if $db->error;
$db->setup;
die "Error on setup of database: " . $db->error . "\nDSN=$db->{dsn}\n"
    if $db->error;

# Determine page for dispatch
exit(
      $step eq 'buy' ? _page_buy($q)
    : $step eq 'swp' ? _page_buy($q)
    : $step eq 'upg' ? _page_buy($q)
    : $step eq 'pik' ? _page_pik($q)
    : $step eq 'tix' ? _page_tix($q)
    : _page_error($q, "Invalid step: $step")
);

#
# Buy tickets first page: show selection, tickets, payment
#
sub _page_buy {
    my $q        = shift;
    my $alert    = shift || q{};
    my $alertdiv = $alert ? qq{\t<div class="alert">\n$alert\n\t</div>} : q{};

    # Release any expired holds, so we start fresh
    my $relerr = htx::ticket::release_expired_holds($htx);
    if ($relerr) {
        my $err = "Error releasing expired holds: " . $relerr . "\n";
        print $q->h1("Hauntix Error");
        print $q->p($err);
        print $q->end_html;
        exit 0;
    }

    # Load ticket tallies for what's in the web pool
    my $tally = htx::show::ticket_tally(-htx => $htx, -tixPool => 'w');
    my $showdata = {};
    my $STATE_SHUT = 0;    ### TODO:  Move constants to better place
    my $STATE_OPEN = 1;
    my $STATE_NEAR = 2;
    my $STATE_FULL = 3;
    foreach my $show (@$tally) {
        my $shoCost  = uc($show->{shoCost});
        my $shoClass = uc($show->{shoClass});
        next unless ($shoClass eq 'REG') || ($shoClass eq 'VIP');
        my $showId   = $show->{shoId};
        my $date     = substr($show->{shoTime}, 0, 10);
        my $avail    = $show->{avail} || 0;
        my $total    = $show->{total} || 0;
        my $ratio    = $total <= 0 ? 0.0 : $avail / $total;
        my $state
            = $total <= 0
            ? $STATE_SHUT
            : $avail < 4 ? $STATE_FULL    ### TODO:  Constants and clearer threshold definitions
            : ($ratio < 0.33) || ($avail < 13) ? $STATE_NEAR
            :                                    $STATE_OPEN;
        $showdata->{$date}->{$shoClass} = [$state, $showId, $shoCost, $avail, $total];
    }

    # now make a JSON structure of it (if this gets any bigger, then just 'use JSON;' instead)
    my $d1          = "\t";
    my $showdata_js = q{};
    foreach my $date (sort keys %$showdata) {
        $showdata_js .= qq/$d1"$date": {/;
        my $d2 = q{};
        foreach my $class (sort keys %{$showdata->{$date}}) {
            my $state = $showdata->{$date}->{$class}->[0];
            my $shoid = $showdata->{$date}->{$class}->[1];
            my $price = $showdata->{$date}->{$class}->[2];
            my $avail = $showdata->{$date}->{$class}->[3];    # for debugging
            my $total = $showdata->{$date}->{$class}->[4];    # for debugging
            $showdata_js .= qq/$d2$class: [$state, $shoid, $price, $avail, $total]/;
            $d2 = ", ";
        }
        $showdata_js .= qq/}/;
        $d1 = ",\n\t";
    }

    # Page Items
    my $action_intro = $step eq 'buy'? q^<h1>Purchase Tickets</h1>
    <p> Tickets may be purchased here online and printed on your own printer. &nbsp;
    Tickets will also be emailed to you in PDF format, so you may print them later. &nbsp;
    Choose the day, enter the number of tickets you want to purchase, verify your order, 
    then enter your payment information (debit or credit card). &nbsp;
    Tickets are good ONLY on the day selected.
    </p>^
        : $step eq 'swp'? q^<h1>Exchange Tickets</h1>
    <p>You may exchange tickets for another day, up until 36 hours before 
    the show time on your current tickets.  Enter your current ticket information,
    select the new day, verify any additional costs, and if necessary,
    then enter payment information for the additional cost.
    Your old tickets will be voided and you will be issued tickets for the new day.
    </p>^
        : $step eq 'upg'? q^<h1>Upgrade Tickets</h1>
    <p>You may upgrade your Regular Admission tickets to VIP Fastpass tickets
    for $10 more per ticket.  Enter your current ticket information,
    verify your order, then enter payment information for the upgrade.
    Your old tickets will be voided and you will be issued new VIP tickets.
    </p>^
        : '<h1>Tickets</h1>';

    # The page body
    my $sigId = psig('tix');
    print qq^
  <script type="text/javascript">
    function show_data() {
        return {
$showdata_js
        };
    }
    setInterval(tally_order, 3000);
  </script>

  <div class="funcs">
   <a id="fhome" href="/">Home Page</a>
   <a id="fpik"  href="#">Enter Pickup Code</a>
   <a id="fswap" href="?step=swp">Exchange Tickets</a>
<!--   <a id="fupg"  href="?step=upg">Upgrade Tickets</a> -->
   <a id="fpol"  href="/hmTix.html">Ticket Policy</a>
  </div>

  <div id="pikInfo" style="display:none">
    <p>Pickup codes let you view and print your tickets online, 
    whether purchased from the ticket booth, purchased on-line, or awarded to you. 
    Tickets will be emailed to the address you supply so you can print them yourself. </p>
     <form action="https://hauntedmines.org/cgi/htxTix.cgi" method="post">
      <table>
        <tr>
         <td align="right">Pickup Code:&nbsp;</td>
         <td><input name="pcode" type="text" maxlength="13" size="10"/></td>
        </tr>
        <tr>
         <td align="right">E-Mail Address:&nbsp;</td>
         <td><input name="email" type="text" maxlength="255" size="28"/></td>
        </tr>
        <tr>
         <td align="right">Repeat E-Mail:&nbsp;</td>
         <td><input name="emailcheck" type="text" maxlength="255" size="28"/></td>
        </tr>
        <tr>
         <td colspan="2" align="center"><input type="submit" name="getpik" id="getpik" value="Submit"/></td>
        </tr>
      </table>
      <input type="hidden" name="step" value="pik"/>
     </form>
  </div>

  <div id="swapInfo" style="display:none">
    <p>You may exchange tickets for another day up until 36 hours before 
    the show date and time on the tickets.  Enter the pickup code from your
    receipt to exchange all those tickets, or enter individual ticket numbers:</p>

     <form action="https://hauntedmines.org/cgi/htxTix.cgi" method="post">
      <table>
        <tr>
         <td align="right">Pickup Code:&nbsp;</td>
         <td><input name="pcode" type="text" maxlength="13" size="10"/></td>
        </tr>
        <tr>
         <td align="right" id="swaptixnolabel">Ticket Numbers:&nbsp;</td>
         <td><textarea name="tixnos" rows="4" cols="28"/>&nbsp;</textarea></td>
        </tr>

        <tr>
         <td align="right">E-Mail Address:&nbsp;</td>
         <td><input name="email" type="text" maxlength="255" size="28"/></td>
        </tr>
        <tr>
         <td align="right">Repeat E-Mail:&nbsp;</td>
         <td><input name="emailcheck" type="text" maxlength="255" size="28"/></td>
        </tr>
        <tr>
         <td colspan="2" align="center"><input type="submit" name="doswap" id="doswap" value="Next: Verify Tickets"/></td>
        </tr>
      </table>
      <input type="hidden" name="step" value="swp"/>
     </form>
  </div>

  <div title="About VIP Tickets" id="whatisVIP">
	VIP ticket holders are admitted to the haunt at a faster rate than Regular ticket holders.
	These tickets cost a bit more but are a good choice if you
	want to impress your date, or just can't wait to be scared!
  </div>
  <div title="About Regular Tickets" id="whatisREG">
	Regular Tickets let you experience the whole haunt,
	but you may need to wait to let VIP ticket holders go in ahead of you.
	These tickets are your best value.
  </div>
  <div title="About Service Charges" id="whatisServiceCharge">
	The service charge covers the additional cost of processing
	credit/debit cards online that is charged to us by the financial gateway.
  </div>

    $action_intro
    $alertdiv

  <form method="post" action="htxTix.cgi" enctype="multipart/form-data" id="htxForm">

    <h2>Step 1: Select Day</h2>
    <div class="ctext">Click the day you want to attend the Haunted Mines.</div>
    <div id="datepick"></div>
    <div class="legend">
      <span class="box_open">&#9633;</span> Available   &nbsp;
      <span class="box_near">&#9633;</span> Selling out &nbsp;
      <span class="box_full">&#9633;</span> Sold Out    &nbsp;
      <span class="box_shut">&#9633;</span> Closed      &nbsp;
    </div>
    <input type="hidden" name="shoDate"    id="shoDate"    value=""/>
    <input type="hidden" name="shoIdREG"   id="shoIdREG"   value="0"/>
    <input type="hidden" name="shoIdVIP"   id="shoIdVIP"   value="0"/>


    <h2>Step 2: Enter Number of Tickets</h2>
      <div id="ntix" class="ui-helper-reset ui-widget-content ui-corner-all">
		<table id="ntixtable">
          <tr>
            <td>Selected Date</td>
            <td colspan="3"><span id="datewant"><font color="red">-- Select Day Above --</font></span></td>
          </tr>
          <tr>
            <td><span id="shoNameREG">Regular Ticket</span> 
                <a href="#" class="explain" id="explainREG">&#9432;</a> </td>
            <td><span id="priceREG">\$--.--</span> each</td>
            <td width="13%"><input id="ntixREG" name="ntixREG" value="0" size="2" maxlength="3" onkeyup="onlydigits(this);"/></td>
            <td><span id="ntixStateREG">&nbsp;</span>
          </tr>
          <tr>
            <td><span id="shoNameVIP">VIP Ticket</span>
                <a href="#" class="explain" id="explainVIP">&#9432;</a> </td>
            <td><span id="priceVIP">\$--.--</span> each</td>
            <td width="13%"><input id="ntixVIP" name="ntixVIP" value="0" size="2" maxlength="3" onkeyup="onlydigits(this);"/></td>
            <td><span id="ntixStateVIP">&nbsp;</span>
          </tr>
          <tr>
            <td>Discount Code</td>
            <td colspan="3"><input id="dc" name="dc" value="" size="9" maxlength="9" onkeyup="onlydigits(this);"/></td>
          </tr>
        </table>
      </div>


    <h2>Step 3: Verify Your Order</h2>
      <div id="order" class="ui-helper-reset ui-widget-content ui-corner-all">
		<table id="ordertable">
			<thead>
				<tr id="orderhead">
					<th width="10%">Quantity</th>
					<th>Ticket and Show</th>
					<th width="13%">Cost Each</th>
					<th width="15%">Line Total</th>
				</tr>
			</thead>
			<tbody id="orderbody">
				<tr>
					<td align="center" colspan="4"><br/>-- No Tickets Selected Yet --<br/>&nbsp;</td>
				</tr>
			</tbody>
            <tfoot id="orderfoot">
		  	  <tr>
				<td align="right" colspan="3">Subtotal: </td>
				<td width="15%" align="right" id="ordersubtotal">\$0.00</td>
			  </tr>
	      	  <tr>
				<td align="right" colspan="3">Tax: </td>
				<td width="15%" align="right" id="ordertax">\$0.00</td>
			  </tr>
			  <tr>
				<td align="right" colspan="3">
                    <a href="#" class="explain" id="explainServiceCharge">&#9432;</a>
                    Service Charge:</td>
				<td width="15%" align="right" id="ordercharge">\$0.00</td>
			  </tr>
			  <tr>
				<td align="right" colspan="3">Total: </td>
				<td width="15%" align="right" id="ordertotal">\$0.00</td>
			  </tr>
            </tfoot>
		</table>
      </div>


    <h2>Step 4: Enter Payment Information</h2>
      <p>You are purchasing tickets that are only good for the selected night.<br/>
      Be certain this is the night you wish to attend - these tickets are NOT valid on other nights!
      </p>
      <div id="pay" class="ui-helper-reset ui-widget-content ui-corner-all">
        <table id="paytable">
	      <tr>
		    <td>Name on Card</td>
		    <td><input type="text" id="nameoncard" name="nameoncard"
                   size="32" maxlength="80"
                   class="payinfo validate[required]" /></td>
	      </tr>
	      <tr>
		    <td>Your Email</td>
		    <td><input type="text"  id="email" name="email"
                   size="40" maxlength="127"
                   class="payinfo validate[required,custom[email]]" />
	      </tr>
	      <tr>
		    <td>Repeat Email</td>
		    <td><input type="text" id="emailcheck" name="emailcheck"
                   size="40" maxlength="127" 
                   class="payinfo validate[required,equals[email]]" /></td>
	      </tr>
	      <tr>
		    <td>Billing ZIP Code</td>
		    <td><input type="text" id="zip" name="zip"
                   size="9" maxlength="14"
                   class="payinfo validate[required,custom[onlyNumberSp]]" /></td>
	      </tr>
	      <tr>
		    <td>Credit Card Number</td>
		    <td><input type="text" id="acctnum" name="acctnum"
                   size="24" maxlength="24"
                   class="payinfo validate[required,custom[creditcard]]" />
                   (MC, Visa, Discover only)</td>
	      </tr>
	      <tr>
		    <td>Expiration Date</td>
		    <td><span>
			    <select name="expm">
			        <option selected="selected" value="0">month</option>
			        <option value="01">01 - January</option>
			        <option value="02">02 - February</option>
			        <option value="03">03 - March</option>
			        <option value="04">04 - April</option>
			        <option value="05">05 - May</option>
			        <option value="06">06 - June</option>
			        <option value="07">07 - July</option>
			        <option value="08">08 - August</option>
			        <option value="09">09 - September</option>
			        <option value="10">10 - October!</option>
			        <option value="11">11 - November</option>
			        <option value="12">12 - December</option>
			    </select>
                <select name="expy">
			        <option selected="selected" value="0">year</option>
			        <option value="13">2013</option>
			        <option value="14">2014</option>
			        <option value="15">2015</option>
			        <option value="16">2016</option>
			        <option value="17">2017</option>
			        <option value="18">2018</option>
			        <option value="19">2019</option>
			        <option value="20">2020</option>
			        <option value="21">2021</option>
			    </select>
		    </span></td>
	      </tr>
	      <tr>
		    <td>Security Code on Back</td>
		    <td><input type="text" id="cardcode" name="cardcode"
                   size="7" maxlength="7"
                   class="payinfo validate[required,custom[onlyNumberSp]]" /></td>
	      </tr>
        </table>
      </div>

    <h3>Others are purchasing tickets right now, 
    and may get these tickets before you do. &nbsp;  Act fast!</h3>

    <div id="submits">
     <span class="small">&nbsp;By clicking the Buy Tickets button below, 
        you agree to our <a href="/hmTix.html">Ticket Policy</a>.</span><br/>
     <input type="submit" name="cancel"      value=" Cancel Order " style="float:left"
         onclick="\$(&quot;#tixForm&quot;).validationEngine(&quot;detach&quot;);" id="cancel" />
     <input type="submit" name="do_purchase" value=" Buy Tickets "  style="float:right" id="buytix" />
    </div>

    <input type="hidden" name="seqId" value="$seqId"/>
    <input type="hidden" name="sig"   value="$sigId"/>
    <input type="hidden" name="step"  value="tix"/>

  </form>

  <p class="ctext small">
	 For ticketing assistance, please email 
        Tickets<img src="/htx/img/at.bmp" border="0" width="9px"/>HauntedMines.org
  </p>
^;
    print $q->end_html;

    return 0;
}

#
# Swap Tickets second page
#
sub _page_swp {
    my $q        = shift;
    my $alert    = shift || q{};
    my $alertdiv = $alert ? qq{\t<div class="alert">\n$alert\n\t</div>} : q{};

    # Dummy showdata so our js code is simpler
    print qq^
  <script type="text/javascript">
    function show_data() {return {};}
  </script>
^;

    # check email addresses
    my $email  = $q->param("email");
    my $echeck = $q->param("emailcheck");
    $email  =~ s/^\s+//sm;    # trim leading
    $email  =~ s/\s+$//sm;    # trim trailing
    $echeck =~ s/^\s+//sm;    # trim leading
    $echeck =~ s/\s+$//sm;    # trim trailing
    _emit_bad_code(
        $q,
        "Bad Email Address",
        "The given email address is missing, appears to be invalid, "
            . "or does not match the repeated email address.  "
            . "We require a valid email address to exhange tickets."
    ) if (!$email || $email !~ m{$RE_EMAIL}i || (lc($echeck) ne lc($email)));

    # Check the pickup code
    my $pikCode = $q->param("pcode");
    if ($pcode) {
        my ($trnId, $trnPickupCode) = unpickup($pikCode);
        _emit_bad_code($q) if !$trnId || !defined($trnPickupCode);
        $pikCode = sprintf '%d-%5.5d', $trnId, $trnPickupCode;    # make it pretty for recording
    }

    # Cleanup ticket numbers, if any given
    my $tixnos = join(q{,}, split(/[\s,;\/\:\.]+/sm,$q->param("tixnos")||q{}));

    _emit_bad_code(
        $q,
        "Missing Pickup Code or Ticket Numbers",
        "You must supply a pickup code or a list of ticket numbers "
            . "to do an exchange."
    ) if !$pcode || $tixnos;

#pcode tixnos email emailcheck

### WORKING HERE

    # Build a progress area on the page
    $tix_proc_open = 1;
    print $q->start_div({id => "tix_proc"});
    print $q->h2("Verifying exchange, please wait...");
    print $q->start_pre;
    my $cmd = "htx-swaptix  -m a@b -s 120 -p 1564-26287 -n 1502020096,1502094691,1501741660,1501816703 -z -v";
    my $out = qx($cmd 2>&1);
    $q->_close_prog();

    # Page Items
    my $action_intro = q^<h1>Exchange Tickets</h1>
    <p>You may exchange tickets for another day, up until 36 hours before 
    the show time on your current tickets.  Enter your current ticket information,
    select the new day, verify any additional costs, and if necessary,
    then enter payment information for the additional cost.
    Your old tickets will be voided and you will be issued tickets for the new day.
    </p>^;

    # The page body
    my $sigId = psig('tix');
    print qq^
  <script type="text/javascript">
    function show_data() {
        return {
$showdata_js
        };
    }
    setInterval(tally_order, 3000);
  </script>

  <div class="funcs">
   <a id="fhome" href="/">Home Page</a>
   <a id="fpik"  href="#">Enter Pickup Code</a>
   <a id="fswap" href="?step=swp">Exchange Tickets</a>
<!--   <a id="fupg"  href="?step=upg">Upgrade Tickets</a> -->
   <a id="fpol"  href="/hmTix.html">Ticket Policy</a>
  </div>

  <div id="pikInfo" style="display:none">
    <p>Pickup codes let you view and print your tickets online, 
    whether purchased from the ticket booth, purchased on-line, or awarded to you. 
    Tickets will be emailed to the address you supply so you can print them yourself. </p>
     <form action="https://hauntedmines.org/cgi/htxTix.cgi" method="post">
      <table>
        <tr>
         <td align="right">Pickup Code:&nbsp;</td>
         <td><input name="pcode" type="text" maxlength="13" size="10"/></td>
        </tr>
        <tr>
         <td align="right">E-Mail Address:&nbsp;</td>
         <td><input name="email" type="text" maxlength="255" size="28"/></td>
        </tr>
        <tr>
         <td align="right">Repeat E-Mail:&nbsp;</td>
         <td><input name="emailcheck" type="text" maxlength="255" size="28"/></td>
        </tr>
        <tr>
         <td colspan="2" align="center"><input type="submit" name="getpik" id="getpik" value="Submit"/></td>
        </tr>
      </table>
      <input type="hidden" name="step" value="pik"/>
     </form>
  </div>

  <div id="swapInfo" style="display:none">
    <p>You may exchange tickets for another day up until 36 hours before 
    the show date and time on the tickets.  Enter the pickup code from your
    receipt to exchange all those tickets, or enter individual ticket numbers:</p>

     <form action="https://hauntedmines.org/cgi/htxTix.cgi" method="post">
      <table>
        <tr>
         <td align="right">Pickup Code:&nbsp;</td>
         <td><input name="pcode" type="text" maxlength="13" size="10"/></td>
        </tr>
        <tr>
         <td align="right" id="swaptixnolabel">Ticket Numbers:&nbsp;</td>
         <td><textarea name="tixnos" rows="4" cols="28"/>&nbsp;</textarea></td>
        </tr>

        <tr>
         <td align="right">E-Mail Address:&nbsp;</td>
         <td><input name="email" type="text" maxlength="255" size="28"/></td>
        </tr>
        <tr>
         <td align="right">Repeat E-Mail:&nbsp;</td>
         <td><input name="emailcheck" type="text" maxlength="255" size="28"/></td>
        </tr>
        <tr>
         <td colspan="2" align="center"><input type="submit" name="doswap" id="doswap" value="Next: Verify Tickets"/></td>
        </tr>
      </table>
      <input type="hidden" name="step" value="swp"/>
     </form>
  </div>

  <div title="About VIP Tickets" id="whatisVIP">
	VIP ticket holders are admitted to the haunt at a faster rate than Regular ticket holders.
	These tickets cost a bit more but are a good choice if you
	want to impress your date, or just can't wait to be scared!
  </div>
  <div title="About Regular Tickets" id="whatisREG">
	Regular Tickets let you experience the whole haunt,
	but you may need to wait to let VIP ticket holders go in ahead of you.
	These tickets are your best value.
  </div>
  <div title="About Service Charges" id="whatisServiceCharge">
	The service charge covers the additional cost of processing
	credit/debit cards online that is charged to us by the financial gateway.
  </div>

    $action_intro
    $alertdiv

  <form method="post" action="htxTix.cgi" enctype="multipart/form-data" id="htxForm">

    <h2>Step 1: Select Day</h2>
    <div class="ctext">Click the day you want to attend the Haunted Mines.</div>
    <div id="datepick"></div>
    <div class="legend">
      <span class="box_open">&#9633;</span> Available   &nbsp;
      <span class="box_near">&#9633;</span> Selling out &nbsp;
      <span class="box_full">&#9633;</span> Sold Out    &nbsp;
      <span class="box_shut">&#9633;</span> Closed      &nbsp;
    </div>
    <input type="hidden" name="shoDate"    id="shoDate"    value=""/>
    <input type="hidden" name="shoIdREG"   id="shoIdREG"   value="0"/>
    <input type="hidden" name="shoIdVIP"   id="shoIdVIP"   value="0"/>


    <h2>Step 2: Enter Number of Tickets</h2>
      <div id="ntix" class="ui-helper-reset ui-widget-content ui-corner-all">
		<table id="ntixtable">
          <tr>
            <td>Selected Date</td>
            <td colspan="3"><span id="datewant"><font color="red">-- Select Day Above --</font></span></td>
          </tr>
          <tr>
            <td><span id="shoNameREG">Regular Ticket</span> 
                <a href="#" class="explain" id="explainREG">&#9432;</a> </td>
            <td><span id="priceREG">\$--.--</span> each</td>
            <td width="13%"><input id="ntixREG" name="ntixREG" value="0" size="2" maxlength="3" onkeyup="onlydigits(this);"/></td>
            <td><span id="ntixStateREG">&nbsp;</span>
          </tr>
          <tr>
            <td><span id="shoNameVIP">VIP Ticket</span>
                <a href="#" class="explain" id="explainVIP">&#9432;</a> </td>
            <td><span id="priceVIP">\$--.--</span> each</td>
            <td width="13%"><input id="ntixVIP" name="ntixVIP" value="0" size="2" maxlength="3" onkeyup="onlydigits(this);"/></td>
            <td><span id="ntixStateVIP">&nbsp;</span>
          </tr>
          <tr>
            <td>Discount Code</td>
            <td colspan="3"><input id="dc" name="dc" value="" size="9" maxlength="9" onkeyup="onlydigits(this);"/></td>
          </tr>
        </table>
      </div>


    <h2>Step 3: Verify Your Order</h2>
      <div id="order" class="ui-helper-reset ui-widget-content ui-corner-all">
		<table id="ordertable">
			<thead>
				<tr id="orderhead">
					<th width="10%">Quantity</th>
					<th>Ticket and Show</th>
					<th width="13%">Cost Each</th>
					<th width="15%">Line Total</th>
				</tr>
			</thead>
			<tbody id="orderbody">
				<tr>
					<td align="center" colspan="4"><br/>-- No Tickets Selected Yet --<br/>&nbsp;</td>
				</tr>
			</tbody>
            <tfoot id="orderfoot">
		  	  <tr>
				<td align="right" colspan="3">Subtotal: </td>
				<td width="15%" align="right" id="ordersubtotal">\$0.00</td>
			  </tr>
	      	  <tr>
				<td align="right" colspan="3">Tax: </td>
				<td width="15%" align="right" id="ordertax">\$0.00</td>
			  </tr>
			  <tr>
				<td align="right" colspan="3">
                    <a href="#" class="explain" id="explainServiceCharge">&#9432;</a>
                    Service Charge:</td>
				<td width="15%" align="right" id="ordercharge">\$0.00</td>
			  </tr>
			  <tr>
				<td align="right" colspan="3">Total: </td>
				<td width="15%" align="right" id="ordertotal">\$0.00</td>
			  </tr>
            </tfoot>
		</table>
      </div>


    <h2>Step 4: Enter Payment Information</h2>
      <p>You are purchasing tickets that are only good for the selected night.<br/>
      Be certain this is the night you wish to attend - these tickets are NOT valid on other nights!
      </p>
      <div id="pay" class="ui-helper-reset ui-widget-content ui-corner-all">
        <table id="paytable">
	      <tr>
		    <td>Name on Card</td>
		    <td><input type="text" id="nameoncard" name="nameoncard"
                   size="32" maxlength="80"
                   class="payinfo validate[required]" /></td>
	      </tr>
	      <tr>
		    <td>Your Email</td>
		    <td><input type="text"  id="email" name="email"
                   size="40" maxlength="127"
                   class="payinfo validate[required,custom[email]]" />
	      </tr>
	      <tr>
		    <td>Repeat Email</td>
		    <td><input type="text" id="emailcheck" name="emailcheck"
                   size="40" maxlength="127" 
                   class="payinfo validate[required,equals[email]]" /></td>
	      </tr>
	      <tr>
		    <td>Billing ZIP Code</td>
		    <td><input type="text" id="zip" name="zip"
                   size="9" maxlength="14"
                   class="payinfo validate[required,custom[onlyNumberSp]]" /></td>
	      </tr>
	      <tr>
		    <td>Credit Card Number</td>
		    <td><input type="text" id="acctnum" name="acctnum"
                   size="24" maxlength="24"
                   class="payinfo validate[required,custom[creditcard]]" />
                   (MC, Visa, Discover only)</td>
	      </tr>
	      <tr>
		    <td>Expiration Date</td>
		    <td><span>
			    <select name="expm">
			        <option selected="selected" value="0">month</option>
			        <option value="01">01 - January</option>
			        <option value="02">02 - February</option>
			        <option value="03">03 - March</option>
			        <option value="04">04 - April</option>
			        <option value="05">05 - May</option>
			        <option value="06">06 - June</option>
			        <option value="07">07 - July</option>
			        <option value="08">08 - August</option>
			        <option value="09">09 - September</option>
			        <option value="10">10 - October!</option>
			        <option value="11">11 - November</option>
			        <option value="12">12 - December</option>
			    </select>
                <select name="expy">
			        <option selected="selected" value="0">year</option>
			        <option value="14">2013</option>
			        <option value="14">2014</option>
			        <option value="15">2015</option>
			        <option value="16">2016</option>
			        <option value="17">2017</option>
			        <option value="18">2018</option>
			        <option value="19">2019</option>
			        <option value="20">2020</option>
			        <option value="21">2021</option>
			    </select>
		    </span></td>
	      </tr>
	      <tr>
		    <td>Security Code on Back</td>
		    <td><input type="text" id="cardcode" name="cardcode"
                   size="7" maxlength="7"
                   class="payinfo validate[required,custom[onlyNumberSp]]" /></td>
	      </tr>
        </table>
      </div>

    <h3>Others are purchasing tickets right now, 
    and may get these tickets before you do. &nbsp;  Act fast!</h3>

    <div id="submits">
     <span class="small">&nbsp;By clicking the Buy Tickets button below, 
        you agree to our <a href="/hmTix.html">Ticket Policy</a>.</span><br/>
     <input type="submit" name="cancel"      value=" Cancel Order " style="float:left"
         onclick="\$(&quot;#tixForm&quot;).validationEngine(&quot;detach&quot;);" id="cancel" />
     <input type="submit" name="do_purchase" value=" Buy Tickets "  style="float:right" id="buytix" />
    </div>

    <input type="hidden" name="seqId" value="$seqId"/>
    <input type="hidden" name="sig"   value="$sigId"/>
    <input type="hidden" name="step"  value="tix"/>

  </form>

  <p class="ctext small">
	 For ticketing assistance, please email 
        Tickets<img src="/htx/img/at.bmp" border="0" width="9px"/>HauntedMines.org
  </p>
^;
    print $q->end_html;

    return 0;
}

#
# Pickup code - get here via step-pik, code=xxxx-xxxxx
#
sub _page_pik {
    my $q     = shift;
    my $alert = q{};

    # Dummy showdata so our js code is simpler
### TODO: change to real showdata, for possible show selection
    print qq^
  <script type="text/javascript">
    function show_data() {return {};}
  </script>
^;

    # check email addresses
    my $email  = $q->param("email");
    my $echeck = $q->param("emailcheck");
    $email  =~ s/^\s+//sm;    # trim leading
    $email  =~ s/\s+$//sm;    # trim trailing
    $echeck =~ s/^\s+//sm;    # trim leading
    $echeck =~ s/\s+$//sm;    # trim trailing
    _emit_bad_code(
        $q,
        "Bad Email Address",
        "The given email address is missing, appears to be invalid, "
            . "or does not match the repeated email address.  "
            . "We require a valid email address to send you your tickets and receipt."
    ) if (!$email || $email !~ m{$RE_EMAIL}i || (lc($echeck) ne lc($email)));

    # Check the pickup code
    my $pikCode = $q->param("pcode");
    my ($trnId, $trnPickupCode) = unpickup($pikCode);
    _emit_bad_code($q) if !$trnId || !defined($trnPickupCode);
    $pikCode = sprintf '%d-%5.5d', $trnId, $trnPickupCode;    # make it pretty for recording

    # Lookup the transaction
    #   Note: give only a single generic error message, lest we reveal to much to an attacker!
    my $trn = htx::transaction->load(-htx => $htx, -trnId => $trnId);
    _record_pickup($pikCode, $email, "Transaction error: " . $trn->error) && _emit_bad_code($q)
        if $trn->error;
    _record_pickup($pikCode, $email, "Pickup codes do not match") && _emit_bad_code($q)
        if $trnPickupCode != $trn->{trnPickupCode};
    _record_pickup($pikCode, $email, "Transaction not final: " . $trn->phase())
        && _emit_bad_code($q)
        if $trn->phase() ne $TRN_PHASE_FIN;

    # Are there tickets that need show selection? (shoId==0?)
        # Based on the price paid for the tickets (in the sale record),
        # indicate which shows are available for them to select on the 
        # calendar (or just do as a list).  
        # For price upgrade shows, or VIP tixClass, indicate extra cost
        #   needed ("VIP upgrade +$10.00") 

    # It's good
    _record_pickup($pikCode, $email, "OK");
    sleep 1;
    print $q->h1("Your Transaction Was Found");
    print $q->p("Here is your transaction summary.  "
            . " Your ticket(s) and receipt are ready for viewing and printing.");

    # Always re-create the PDF - the ticket use state may have changed
    my $tixfile = "htx-tix-" . $trn->fmtpickup() . ".pdf";
    my $pdffile = $ENV{DOCUMENT_ROOT} . "/tix/" . $tixfile;
    my $cmd
        = "../../bin/htx-pdfout --webdb --tickets --receipt --trnid "
        . $trn->trnid()
        . " --mailto '$email'"
        . " --output-file $pdffile";
    my $out = qx($cmd 2>&1);
    ### TODO: check status !!!

    # Display transaction
    $trnId = $trn->trnid();
    my $subtotal = dollars($trn->subtotal());
    my $tax      = dollars($trn->tax());
    my $svcchg   = dollars($trn->servicecharge());
    my $total    = dollars($trn->total());

    # table header
    print qq{
      <div id="order" class="ui-helper-reset ui-widget-content ui-corner-all">
		<table id="ordertable">
			<thead>
				<tr id="orderinfo">
		          <td colspan="4">Your Ticket Order - Transaction #$trnId</td>
				</tr>
				<tr id="orderhead">
					<th width="10%">Quantity</th>
					<th>Ticket and Show</th>
					<th width="13%">Cost Each</th>
					<th width="15%">Line Total</th>
				</tr>
			</thead>
			<tbody id="orderbody">
};

    # put line items here
    foreach my $sale ($trn->sales()) {
        my $qty = $sale->{salQuantity} || 0;
        my $nam = $sale->{salName}     || 'Tickets';
        if ($sale->{show}) {
            my $show = $sale->{show}; 
            my $nite = substr($show->{shoTime}, 0, 10);
            $nam .= " - Valid $nite Only";
        }
        my $paid = dollar($sale->{salPaid} || 0);
        my $ltot = dollar($sale->{salPaid} * $qty);
        print qq{<tr>\n};
        print qq{ <td align="center">$qty</td>\n};
        print qq{ <td>$nam</td>\n};
        print qq{ <td align="right">$paid</td>\n};
        print qq{ <td align="right">$ltot</td>\n};
        print qq{</tr>\n};
    }

    # footer
    print qq{
			</tbody>
            <tfoot id="orderfoot">
		  	  <tr>
				<td align="right" colspan="3">Subtotal: </td>
				<td width="15%" align="right" id="ordersubtotal">$subtotal</td>
			  </tr>
	      	  <tr>
				<td align="right" colspan="3">Tax: </td>
				<td width="15%" align="right" id="ordertax">$tax</td>
			  </tr>
			  <tr>
				<td align="right" colspan="3">Service Charge:</td>
				<td width="15%" align="right" id="ordercharge">$svcchg</td>
			  </tr>
			  <tr>
				<td align="right" colspan="3">Total: </td>
				<td width="15%" align="right" id="ordertotal">$total</td>
			  </tr>
            </tfoot>
		</table>
      </div>
};

    # Give access to the tickets
    print $q->br;
    print $q->p("Your tickets and full receipt have been emailed to you at $email ."
            . "   Or, you may view and print them now (recommended):");
    print $q->br;
    print $q->h3(
        {id => "get_tix"},
        a(  {   class => "ui-button ui-widget ui-state-default ui-corner-all",
                href  => "/tix/$tixfile"
            },
            " View and Print Tickets Now (PDF) "
        )
    );
    print $q->br;

    # Closing
    print $q->p(
        {id => "final"},
        "Go back to ",
        a(  {   class => "ui-button ui-widget ui-state-default ui-corner-all",
                href  => $q->url()
            },
            " purchase more tickets "
        ),
        ", or go to the ",
        a(  {   class => "ui-button ui-widget ui-state-default ui-corner-all",
                href  => $cfg->{haunt}->{website}
            },
            " " . $cfg->{haunt}->{name} . " home page. "
        )
    );

}

# Record that a pickup was done
sub _record_pickup {
    my ($pikCode, $email, $result) = @_;
    my $db = $htx->{db};
    my $sql
        = "INSERT INTO pickups SET "
        . " pikCode="
        . $db->quote($pikCode)
        . ",pikEmail="
        . $db->quote($email)
        . ",pikRemoteAddr="
        . $db->quote($ENV{REMOTE_ADDR} || "--n/a--")
        . ",pikResult="
        . $db->quote($result) . ";";
    $db->insert($sql);
    _emit_bad_code(
        $q,
        "Unable to Record Pickup Attempt",
        "Could not record pickup attempt: " . $db->error
    ) if $db->error;
    return 1;
}

sub _emit_bad_code {
    my ($q, $ttl, $msg) = @_;
    $msg ||= "The given pickup code is invalid.";
    sleep 3;
    print $q->h1($ttl || "Bad Pickup Code");
    print $q->p($msg);
    print $q->p(
        {id => "final"},
        "You may ",
        a(  {   class => "ui-button ui-widget ui-state-default ui-corner-all",
                href  => "/hmTix.html#pik"   ### TODO: parameterize the tickets page
            },
            " go back "
        ),
        " to try again,  ",
        a(  {   class => "ui-button ui-widget ui-state-default ui-corner-all",
                href  => $q->url()
            },
            " purchase more tickets"
        ),
        ", or go to the ",
        a(  {   class => "ui-button ui-widget ui-state-default ui-corner-all",
                href  => $cfg->{haunt}->{website}
            },
            " " . $cfg->{haunt}->{name} . " home page. "
        )
    );
    exit 0;
}

#
# Do ticket purchase, gen tickets, email tickets
#
sub _page_tix {
    my $q     = shift;
    my $alert = q{};

    # Dummy showdata so our js code is simpler
    print qq^
  <script type="text/javascript">
    function show_data() {return {};}
  </script>
^;

    # Is this a cancel?
    if ($q->param("cancel")) {
        print $q->h1("Order Cancelled");
        print $q->p("You have cancelled your ticket purchase.");
        print $q->p(
            {id => "final"},
            "You may ",
            a(  {   class => "ui-button ui-widget ui-state-default ui-corner-all",
                    href  => $q->url()
                },
                " go back to purchase "
            ),
            " again, or go to the ",
            a(  {   class => "ui-button ui-widget ui-state-default ui-corner-all",
                    href  => $cfg->{haunt}->{website}
                },
                " " . $cfg->{haunt}->{name} . " home page. "
            )
        );
        exit 0;
    }

    #    <input type="hidden" name="shoDate"    id="shoDate"    value=""/>
    #    <input type="hidden" name="shoIdREG"   id="shoIdREG"   value="0"/>
    #    <input type="hidden" name="shoIdVIP"   id="shoIdVIP"   value="0"/>

    # Verify the show information
    my $shoDate  = $q->param('shoDate')  || q{};
    my $shoIdREG = $q->param('shoIdREG') || q{};
    my $shoIdVIP = $q->param('shoIdVIP') || q{};
    my $ntixREG = int($q->param('ntixREG') || 0) || 0;
    my $ntixVIP = int($q->param('ntixVIP') || 0) || 0;
    $alert .= "<li>Show Date not selected</li>" if !$shoDate;
    $alert .= "<li>Show Date not valid format</li>"
        if $shoDate && $shoDate !~ m/^\d{4}-\d{2}-\d{2}$/;
    $alert .= "<li>Show ID for Regular tickets missing (are you tampering with me?)</li>"
        if $shoDate && !$shoIdREG;
    $alert .= "<li>Show ID for Regular tickets not valid format</li>"
        if $shoIdREG && $shoIdREG !~ m/^\d+$/;
    $alert .= "<li>Show ID for VIP tickets missing (are you tampering with me?)</li>"
        if $shoDate && !$shoIdVIP;
    $alert .= "<li>Show ID for VIP tickets not valid format</li>"
        if $shoIdVIP && $shoIdVIP !~ m/^\d+$/;
    $alert .= "<li>Negative regular ticket amounts not allowed.... are u messin' wit me?</li>"
        if $ntixREG < 0;
    $alert .= "<li>Negative VIP ticket amounts not allowed.... whatcha doin?</li>" if $ntixVIP < 0;
    $alert
        .= "<li>No tickets selected - please choose a day and enter the number of tickets desired</li>"
        if !$ntixREG && !$ntixVIP;

    # cleanup card number
    my $acctnum = $q->param('acctnum');
    $acctnum =~ s/[^0-9]//g;
    $q->param('acctnum', $acctnum);

    # Got all the credit card info?
    foreach my $f (
        qw/
        nameoncard
        email
        emailcheck
        address
        zip
        acctnum
        expm
        expy
        cardcode
        /
        )
    {
        my $v = $q->param($f);
        $v =~ s/^\s+//sm;
        $v =~ s/\s+$//sm;

        if (($f eq 'nameoncard') && !$v) {
            $alert .= "<li>The Name on Card is required</li>";
            next;
        }
        if (($f eq 'email') && ($v !~ m{$RE_EMAIL}i)) {
            $alert .= "<li>Invalid email address</li>";
            next;
        }
        if (($f eq 'emailcheck') && (lc($v) ne lc($q->param('email')))) {
            $alert .= "<li>Email addresses do not match</li>";
            next;
        }
        if (($f eq 'zip') && ($v !~ m/$RE_ZIP/i)) {
            $alert .= "<li>Zip Code is invalid</li>";
            next;
        }
        if (($f eq 'acctnum') && ($v !~ m/$RE_CC/i)) {
            $alert .= "<li>The Credit Card Number looks strange</li>";
            next;
        }
        if (($f eq 'expm') && (!$v || !exists $EXPM->{$v})) {
            $alert .= "<li>Expiration date's month is invalid, please select a month</li>";
            next;
        }
        if (($f eq 'expy') && (!$v || !exists $EXPY->{$v})) {
            $alert .= "<li>Expiration date's year is invalid, please select a year</li>";
            next;
        }
        if (($f eq 'cardcode') && ($v !~ m/$RE_CCV/i)) {
            $alert
                .= "<li>The Security Code is invalid.  It is a 3 or 4 digit number from the back of your credit or debit card.</li>";
            next;
        }
        $q->param($f, $v);    # Store-back the cleaned up value
    }
    if ($alert) {
        $alert
            = "<h1>Oops!</h1>"
            . "<p>Something is wrong with the submitted information:</p>"
            . "<ul>$alert</ul>"
            . "<br/><p>Please scroll down and correct the information, then try again.</p>";
        exit _page_buy($q, $alert);    # go back and try again
    }

    # Build show list
    my @wantshows = ();
    push @wantshows, {shoId => $shoIdREG, qty => $ntixREG} if $ntixREG > 0;
    push @wantshows, {shoId => $shoIdVIP, qty => $ntixVIP} if $ntixVIP > 0;

    # Build a progress area on the page
    $tix_proc_open = 1;
    print $q->start_div({id => "tix_proc"});
    print $q->h2("Processing Transaction, Please Wait...");
    print $q->start_pre;

    # Build transaction
    print "-- Creating transaction record... ";
    my $trn = htx::transaction->new(
        -htx           => $htx,
        -trnUser       => "web",
        -trmMOD        => "auto",
        -trnRemoteAddr => $ENV{REMOTE_ADDR} || "--n/a--",
        -trnEmail      => $q->param('email') || "--n/a--",
        -trnStation    => uc($cfg->{web}->{station_id} || $htx::transaction::TRN_STATIONS_WEB[0]),
    );
    exit _page_error($q, "Unable to create the transaction record: " . $trn->error)
        if $trn->error();
    print "transaction #" . $trn->trnid() . "\n";

    # index shows by show id for easier lookup
    print "-- Indexing shows... ";
    my @shows   = htx::show::all_shows($htx);
    my $showids = {};
    foreach my $show (@shows) {
        $showids->{$show->{shoId}} = $show;
    }
    print "done\n";

    # Add items (tickets) to the sale; this reserves the tickets
    #   Verify the requested shows as we do this.
    print "-- Reserving tickets... ";
    my $ntix = 0;
    foreach my $want (@wantshows) {
        my $qty   = $want->{qty};
        my $shoId = $want->{shoId};
        if (!exists $showids->{$shoId}) {
            $trn->cancel;
            my $t0err = $trn->error() || "Transaction $trn->{trnId} cancelled.";
            exit _page_error($q,
                "\n   The given show #$shoId does not exist.  Nothing to do but exit!  $t0err");
        }
        my $show = $showids->{$shoId};
        my $item = {
            trnId        => $trn->{trnId},
            show         => $show,
            itmType      => "prd",                 ### TODO: Use constant
            itmName      => $show->{shoName},      ### TODO: what about shoClass?
            itmCost      => $show->{shoCost},
            itmPaid      => 0,
            itmIsTaxable => 0,
            itmIsTicket  => 1,
            itmIsTimed   => $show->{shoIsTimed},
            tixPool      => $TIX_POOL_WEB,
        };
        $trn->add_item($item, $qty);
        $ntix += $qty;

        if ($trn->error) {
            my $t1err = $trn->error;
            $trn->cancel;
            my $t0err = $trn->error() || "Transaction $trn->{trnId} cancelled.";
            if ($t1err =~ m/Unable to get the (\d+) requested tickets; (\d+) available/i) {

                # Close the processing box
                _close_prog($q);

                # Not enough tickets!  Sold out.
                my $nwant  = $1;
                my $navail = $2;
                my $reason = ($navail == 0)
                    ? "<h3>This show is SOLD OUT</h3>"
                    . "<p>This show is sold out of the type of ticket you want.
                        You may try another ticket class (VIP vs Regular);
                        or more tickets may be available later, you can try again.</p>"
                    : "<h3>Not Enough Tickets are Left</h3>"
                    . "<p>not enough of the kind of ticket you want is available.
                        You may try another ticket class (VIP vs Regular);
                        or more tickets may be made available later, or you can decrease the "
                    . " number of tickets in your request and try again.";
                my $alert
                    = "<h1>Could Not Get The Tickets</h1>" 
                    . $reason
                    . "<p>Could not obtain the $nwant <!--of $navail --> ticket(s).</p>"
                    . "<p>Your card has NOT been charged. $t0err</p>";
                exit _page_buy($q, $alert);    # go back and try again
            }

            exit _page_error($q,
                "\n   Error adding item (show $shoId) to the transaction: $t1err, $t0err");
        }

    }
    print "done\n";

    # Automatic discounts
    print "-- Applying automatic discounts... ";
    my $group_threshold = 13;                    ### TODO: Get threshold from d/b
    if ($ntix >= $group_threshold) {
        my $item = {
            trnId        => $trn->{trnId},
            show         => undef,
            itmType      => "dsc",               ### TODO: Use constant
            itmName      => "Group Discount",    ### TODO: get from d/b
            itmCost      => -200,                ### TODO: get from d/b
            itmPaid      => 0,
            itmMethod    => "FixedAmount",
            itmIsTaxable => 0,
            itmIsTicket  => 0,
            itmIsTimed   => 0,
            tixPool      => undef,
        };
        $trn->add_item($item, $ntix - $group_threshold + 1);
        if ($trn->error) {
            my $t1err = $trn->error;
            $trn->cancel;
            my $t0err = $trn->error() || "Transaction $trn->{trnId} cancelled.";
            exit _page_error($q,
                "\n   Error applying discounts to the transaction: $t1err, $t0err");
        }
    }
    print "done\n";

    # Compute service charge
    my $percent = $cfg->{ccw}->{ServiceChargePercent} || 0;
    my $persale = cent($cfg->{ccw}->{ServiceChargePerSale}   || 0);
    my $roundup = cent($cfg->{ccw}->{ServiceChargeRoundUpTo} || 0);
    my $sc      = $persale + int($trn->total() * $percent / 100.0);
    $sc = int(($sc + $roundup - 1) / $roundup) * $roundup if $roundup;
    $trn->servicecharge($sc);
    $trn->retally();

    # Process credit/debit card
    # we don't use htx-ccproc because the cli info is visible to other users on the system, via ps
    print "-- Processing credit card for amount " . dol($trn->owed) . "\n";
    my $crg = new htx::charge(htx => $htx);
    $crg->trnid($trn->trnid);
    $crg->comment("Web Sale $ENV{REMOTE_ADDR}");
    $crg->amount_requested($trn->owed);
    $crg->dup_mode(1);
    $crg->acct($q->param('acctnum'));
    $crg->ccv($q->param('cardcode'));
    $crg->expdate($q->param('expm') . $q->param('expy'));

    print "  Submitting... ";
    my %ccdat = (
        AcctNum         => $q->param('acctnum'),
        ExpDate         => $q->param('expm') . $q->param('expy'),
        CardCode        => $q->param('cardcode'),
        CheckDups       => 1,
        Amount          => dol($trn->owed),
        ECI             => 7,
        Address         => substr("Web Sale $ENV{REMOTE_ADDR}", 0, 50),    ### TODO: Ask for this??
        ZipCode         => $q->param('zip'),
        UseWeb          => 1,
        CustomerPresent => "FALSE",
        CardPresent     => "FALSE",
        UseWeb          => 1,
    );
    my $rsp = htx::cc::charge($htx, %ccdat);
    print "done\n";

    print "  Parsing response... ";
    $crg->parse_proc($rsp);
    $trn->cc($crg) if $rsp->{ResponseCode} == 0;    # add it to the transaction
    print "done\n";

    print "  Saving charge record... ";
    $crg->save;
    if ($crg->error) {
        $trn->cancel;                               ### TODO:  refund any charges that went thru
        my $t0err = $trn->error() || "Transaction $trn->{trnId} cancelled.";
        exit _page_error($q,
                  "Error saving the charge record for HTX transaction #"
                . $trn->trnid()
                . ".  The charge error is : "
                . $crg->error()
                . "<br/><br/>Please contact support - your credit card MAY have been charged.  "
                . "The charge ID is "
                . ($crg->charge_id() || '--no id-')
                . "<br/><br/>$t0err");
    }
    print "done\n";

    # Credit card go thru?
    if ($rsp->{ResponseCode} != 0) {

        # Close the processing box
        _close_prog($q);

        # cancel the transaction
        $trn->cancel;
        my $t0err = $trn->error() || "Transaction $trn->{trnId} cancelled.";

        # Nope, go back so the user can try again
        my $perhaps = q{Something is wrong with the submitted information. };
        $perhaps
            = "Something is wrong with the submitted information. "
            . "Perhaps you have mis-entered your credit/debit card number, "
            . "expiration date, or card code?  "
            if $rsp->{ResponseCode} == 823;
        $perhaps
            = "It appears that you may have already purchased these tickets. "
            . "(Check your email).  If you really do intend to repeat another of the same "
            . "purchase, please wait a while to retry, or alter the purchase slightly so "
            . "the amount charged is different... for example, a few more or less tickets.  "
            . "This duplicate transaction check is a restriction imposed by your financial "
            . "institution.  "
            if $rsp->{ResponseCode} == 813;
        my $alert
            = "<h1>Could Not Charge Your Card</h1>" . "<p> " 
            . $perhaps
            . "Our merchant processing gateway responded:</p>" . "<ul>"
            . "<li>&nbsp;&nbsp;&nbsp;Code: "
            . $rsp->{ResponseCode} . "</li>"
            . "<li>&nbsp;&nbsp;&nbsp;Description: "
            . $rsp->{ResponseDescription} . "</li>"
            . "</ul><br/>"
            . "<p>Your card has NOT been charged, although an attempted charge may be "
            . "recorded by your bank. $t0err</p>"
            . "<p align='center'>-- Please correct the information below and try again --</p>";
        exit _page_buy($q, $alert);    # go back and try again
    }

    # Charge went thru OK, ...
    print "  Card charged OK\n";

    # Commit the transaction
    print "  Comitting the transaction record... ";
    $trn->retally;
    $trn->complete;
    if ($trn->error) {
        my $t1err = $trn->error;
        $trn->cancel;                  ### TODO: auto refund on cancel.
        my $t0err = $trn->error() || "Transaction $trn->{trnId} cancelled.";
        exit _page_error($q,
                  "Error comitting transaction #"
                . $trn->trnid()
                . ": $t1err"
                . "<br/><br/>Please contact support - your credit card was charged!  "
                . "The charge ID is "
                . $crg->charge_id()
                . "<br/><br/>$t0err");
    }
    print "done\n";

    # Generate tickets & receipt, mail it
    print "\n-- Generating tickets and receipt\n";

    # we already checked above that email matches the RE, but do it again
    # incase the check waaaaay above gets changed.  We don't want it to
    # be an attack vector into the command shell!
    print "  Verifying email address... ";
    my $email = $q->param('email');
    if ($email !~ $RE_EMAIL) {
        $trn->cancel;    ### TODO: auto refund on cancel.
        my $t0err = $trn->error() || "Transaction $trn->{trnId} cancelled.";
        exit _page_error($q,
                  "I don't like the email address that was given.  Somehow it got thru."
                . "It must be a simple email address, no complex forms are allowed." . "<br/>"
                . "Transaction "
                . $trn->trnid()
                . "<br/><br/>Please contact support - your credit card was charged!  "
                . "The charge ID is "
                . $crg->charge_id()
                . "<br/><br/>$t0err");
    }
    print "done\n";

    print "  Ticket and receipt generation, and sending via email...\n";
    my $tixfile = "htx-tix-" . $trn->fmtpickup() . ".pdf";
    my $pdffile = $ENV{DOCUMENT_ROOT} . "/tix/" . $tixfile;
    my $cmd
        = "../../bin/htx-pdfout --webdb --tickets --receipt --trnid "
        . $trn->trnid()
        . " --mailto '$email'"
        . " --output-file $pdffile";
    my $out = qx($cmd 2>&1);

    #    print "  (temp) command: $cmd\n";       ### TEMP
    #    print "  (temp)  output: $out\n";       ### TEMP
    print "done\n";

    # TODO - check generated output status and output file exists

    # Close progress box
    _close_prog($q);

    # Display result with tix link and pickup code
    my $event  = $crg->{haunt}->{name}    || 'event';
    my $masked = $crg->{chgMaskedAcctNum} || q{};
    my $ending = $masked;
    $ending =~ s/[^\d]//g;
    my $amount_charged = dollar($crg->amount_charged());
    print $q->h1("Purchase Complete");
    print $q->br;

    my $trnId    = $trn->trnid();
    my $subtotal = dollar($trn->subtotal());
    my $tax      = dollar($trn->tax());
    my $svcchg   = dollar($trn->servicecharge());
    my $total    = dollar($trn->total());

    # table header
    print qq{
      <div id="order" class="ui-helper-reset ui-widget-content ui-corner-all">
		<table id="ordertable">
			<thead>
				<tr id="orderinfo">
                    <td colspan="4">Your Ticket Order - Transaction #$trnId</td>
				</tr>
				<tr id="orderhead">
					<th width="10%">Quantity</th>
					<th>Ticket and Show</th>
					<th width="13%">Cost Each</th>
					<th width="15%">Line Total</th>
				</tr>
			</thead>
			<tbody id="orderbody">
};

    # line items
    foreach my $sale ($trn->sales()) {
        my $qty = $sale->{salQuantity} || 0;
        my $nam = $sale->{salName}     || 'Tickets';
        if ($sale->{show}) {
            my $show =$sale->{show}; 
            my $nite = substr($show->{shoTime}, 0, 10);
            $nam .= " - Valid for $nite Only";
        }
        my $paid = dollar($sale->{salPaid} || 0);
        my $ltot = dollar($sale->{salPaid} * $qty);
        print qq{<tr>\n};
        print qq{ <td align="center">$qty</td>\n};
        print qq{ <td>$nam</td>\n};
        print qq{ <td align="right">$paid</td>\n};
        print qq{ <td align="right">$ltot</td>\n};
        print qq{</tr>\n};
    }

    # footer
    print qq{
			</tbody>
            <tfoot id="orderfoot">
		  	  <tr>
				<td align="right" colspan="3">Subtotal: </td>
				<td width="15%" align="right" id="ordersubtotal">$subtotal</td>
			  </tr>
	      	  <tr>
				<td align="right" colspan="3">Tax: </td>
				<td width="15%" align="right" id="ordertax">$tax</td>
			  </tr>
			  <tr>
				<td align="right" colspan="3">
                    Service Charge:</td>
				<td width="15%" align="right" id="ordercharge">$svcchg</td>
			  </tr>
			  <tr>
				<td align="right" colspan="3">Total: </td>
				<td width="15%" align="right" id="ordertotal">$total</td>
			  </tr>
            </tfoot>
		</table>
      </div>
};

    print $q->br;
    print $q->p("Thank you for your $event ticket purchase.  "
            . "Your card ending in $ending has been charged $amount_charged for the above items.  "
            . "Your tickets and receipt have been emailed to you at $email .  "
            . "You may view and print your tickets and receipt now (recommended):");
    print $q->br;
    print $q->h3(
        {id => "get_tix"},
        a(  {   class => "ui-button ui-widget ui-state-default ui-corner-all",
                href  => "/tix/$tixfile"
            },
            " View and Print Tickets Now (PDF) "
        )
    );
    print $q->br;

    print $q->p("If you lose the email and the PDF available from this page, "
            . "you may still retrieve your tickets using the below Pickup Code.  "
            . "Save it in a safe place:");
    my $pcode = $trn->fmtpickup();
    print $q->h3({id => "pcode"}, "Pickup Code: $pcode");
    print $q->br;

    print $q->p(
        {id => "final"},
        "Go back to ",
        a(  {   class => "ui-button ui-widget ui-state-default ui-corner-all",
                href  => $q->url()
            },
            " purchase more tickets "
        ),
        ", or go to the ",
        a(  {   class => "ui-button ui-widget ui-state-default ui-corner-all",
                href  => $cfg->{haunt}->{website}
            },
            " " . $cfg->{haunt}->{name} . " home page. "
        )
    );

    print $q->end_html;
    return 0;
}

#
# Close the processing progress box
#
sub _close_prog {
    my $q = shift;
    if ($tix_proc_open) {
        print $q->end_pre;
        print $q->end_div;
        print q{
<script type="text/javascript">
    $('#tix_proc').css('display','none');
</script>
};
        $tix_proc_open = 0;
    }
}

#
# Error page
#
sub _page_error {
    my ($q, $err) = @_;
    _close_prog($q);
    print $q->h1("Error");
    print $q->p($err);
    print $q->end_html;
    return 1;
}

# Generate a page signature from the known global data
### Todo: include a chained timestamp as a sess key too
sub psig {
    my $step = shift;
    my $key  = $cfg->{web}->{page_bind_key};
    my $rem  = $ENV{REMOTE_ADDR} || q{non-net};
    my $dat  = join('/', ($step, $trnId, $seqId, $rem, $key));
    return md5_base64($dat);
}

# Find a show
sub find_show {
    my ($shows, $name, $class) = @_;
    foreach my $show (@$shows) {
        return $show
            if (lc($name) eq lc($show->{shoName}))
            and (lc($class) eq lc($show->{shoClass}));
    }
    return undef;
}

