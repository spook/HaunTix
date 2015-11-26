// HaunTix web script functions
// (c) 2011-2014 by Steve Roscio.  All Rights Reserved.
var show_info;
var popup_timer;

var show_date;      // Selected date
var show_info = {}; // will be deferred-loaded

function dollars(iamount) {
	var i = parseFloat(iamount/100.0);
	if(isNaN(i)) { i = 0.00; }
	var minus = '';
	if(i < 0) { minus = '-'; }
	i = Math.abs(i);
	i = parseInt((i + .005) * 100);
	i = i / 100;
	s = new String(i);
	if(s.indexOf('.') < 0) { s += '.00'; }
	if(s.indexOf('.') == (s.length - 2)) { s += '0'; }
	s = minus + '$' + s;
	return s;
}

// Since damn IE8 & under do not support toISOString(), and parsing from it,
//  we'll make our own functions
function isodat(str) {
    var date = new Date;
    var ymd = str.split("-");
    date.setFullYear(ymd[0], ymd[1]-1, ymd[2]);
    return date;
}

function isostr(date) {
    var y = date.getFullYear();
    var m = date.getMonth()+1;
    var d = date.getDate();
    var str = y;
    str += "-";
    if (m<10) str += "0";
    str += m;
    str += "-";
    if (d<10) str += "0";
    str += d;
    return str;
}

// Today's date in ISO format
function isotoday() {
    var today = new Date();
    return isostr(today);
}

function tally_row(q, s, c, t) {
    return '<tr><td align="center">' + q + '</td>'
            +  '<td>' + s + '</td>'
            +  '<td align="right">' + dollars(c) + '</td>'
            +  '<td align="right">' + dollars(t) + '</td></tr>'
            ;
}

function tally_order() {

    // Skip if no changes noticed
    /// todo

    var total = 0;
    var subtotal = 0;
    var tixcount = 0;
    $('#orderbody').html('');   // clear all rows

    if (show_date) {
        for (shoClass in {REG:0,VIP:0}) {
            var ntix = parseInt($("#ntix"+shoClass).val());
            var show = show_info[show_date][shoClass];
            if (ntix) {
                tixcount += ntix;
                var showname = $("#shoName"+shoClass).text()
                var showcost = show[2] || 1717;
                var linesum = ntix * showcost;
                subtotal += linesum;
                $('#orderbody').append(tally_row(ntix,
                                                 showname + " <i>(valid only on " + show_date + ")</i>",
                                                 showcost,
                                                 linesum
                                                 ));
            }
        }
    }

    if ((tixcount >= 10)                    // TODO: Get threshold from d/b
        && (show_date > '2014-10-09')) {    // Only valid after this date  TODO: Get date from d/b
            var discount
                = tixcount >= 30? 300
                : tixcount >= 20? 200
                : tixcount >= 10? 100
                : 0;
            var linesum = tixcount * (-discount);
            subtotal += linesum;
            $('#orderbody').append(tally_row(1,
                                             "Group Discount",
                                             linesum,
                                             linesum
                                             ));
    }

    // Enable/disable purchase button, and other nits
    if (tixcount == 0) {
        $('#orderbody').html('<tr><td colspan="4" align="center"><br/>'
                           + '-- No Date or Tickets Selected --'
                           + '<br/>&nbsp;</td></tr>');
        $('#buytix').button("disable");
    } else {
        if ($('#agreecheck').is(':checked')) {
            $('#buytix').button("enable");
        } 
        else {
            $('#buytix').button("disable");
        }
    }

    $('#ordersubtotal').text(dollars(subtotal));
    var svcchg = Math.round(0.0225*subtotal + 25);  // Merchant fee 2.25% + 25 cents each TODO: get from config
    svcchg = Math.floor((svcchg+49)/50)*50;         // round to 50 cent multiples TODO: get from config
    if (tixcount == 0) svcchg = 0;
    $('#ordercharge').text(dollars(svcchg));
    total = subtotal + svcchg;
    $('#ordertotal').text(dollars(total));
    $('#expect').val(total);

    $("#tixForm").validationEngine("updatePromptsPosition");
}

function set_failure_timer() {
    clearTimeout(popup_timer);
    popup_timer = setTimeout(clear_popups, 7000);
}

function set_success_timer() {
    clearTimeout(popup_timer);
}

function clear_popups() {
    $('#tixForm').validationEngine('hideAll');
}

function disableEnter(evt) {
   var evt = (evt) ? evt : ((event) ? event : null);
   var node = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null);
   if ((evt.keyCode == 13) && (node.type=="text")) {return false;}
}

function onlydigits(t) {
    var v = "0123456789";
    var w = "";
    for (i=0; i < t.value.length; i++) {
        x = t.value.charAt(i);
        if (v.indexOf(x,0) != -1)
            w += x;
    }
    if (w.length == 0) {
        t.value = "";
    }
    else {
        t.value = parseInt(w);
    }
}

function openDay(date) {
    var dstr = isostr(date);
    if (!show_info[dstr]) return false;
    return true;    // if it's defined, it's a day with shows, thus an open day
//    var reg = show_info[dstr]['REG'] || [0,0,0];
//    var vip = show_info[dstr]['VIP'] || [0,0,0];
//    return (reg[0] > 0) || (vip[0] > 0)? true : false;
}

function styleDay(date) {
    var dstr = isostr(date);
    if (!show_info[dstr]) return "";
    if (dstr < isotoday()) return "day_shut";
    var reg = show_info[dstr]['REG'] || [0,0,0];
    var vip = show_info[dstr]['VIP'] || [0,0,0];
//    if ((reg[0] == 3) && (vip[0] == 3)) return "day_full";
//    if ((reg[0] >= 2) || (vip[0] >= 2)) return "day_near";
//    if ((reg[0] == 1) || (vip[0] == 1)) return "day_open";

// *** a real HACK here *** FIXME !
// for now, we'll look at the price of the regular ticket to determine
// if it's a low, med, or hi-price day, then use the day open/near/full 
// styles (green/yellow/red) on the calendar.  The real solution is
// to use different show classes.  But with less than a week to opening,
// there's no time/too much risk to changing all that.  Thus, this hack:
    if ((reg[0] == 0) && (vip[0] == 0)) return "day_shut";
    if (dstr == "2014-10-17") return "day_full" // Force it red :-)
    if (dstr == "2014-10-18") return "day_full" // Force it red :-)
    if (dstr == "2014-10-24") return "day_full" // Force it red :-)
    if (dstr == "2014-10-25") return "day_full" // Force it red :-)
    if (reg[2] <= 1300) return "day_open";
    if (reg[2] <= 2000) return "day_near";
    if (reg[2] == 0)    return "day_shut";
    return "day_full";
}

function hoverTip(date) {
    var dstr = isostr(date);
    if (!show_info[dstr]) return "";
    var reg = show_info[dstr]['REG'] || [0,0,0];
    var vip = show_info[dstr]['VIP'] || [0,0,0];

    if (dstr < isotoday())              return "Day has past";
    if ((reg[0] == 0) && (vip[0] == 0)) return "We're Closed";
    if ((reg[0] == 3) && (vip[0] == 3)) return "SOLD OUT";
    if ((reg[0] >= 2) || (vip[0] >= 2)) 
        return "Hurry... Selling Out!"
            + "\n Regular: "  + dollars(reg[2]) + " each"
            + "\n VIP Tix:  " + dollars(vip[2]) + " each";
    if ((reg[0] >= 1) || (vip[0] >= 1))
        return "We're Open"
            + "\n Regular: "  + dollars(reg[2]) + " each"
            + "\n VIP Tix:  " + dollars(vip[2]) + " each";
    return "Show Canceled";
}

// Called by the datepicker to format a day cell
function perDay(date) {
    return [openDay(date), styleDay(date), hoverTip(date)];
}

// Called when the customer selects a date
function datePick (dstr, inst) {
    show_date = dstr;
    $('#shoDate').val(dstr);
    var date = isodat(dstr);
    $('#datewant').text(date.toDateString());

    var reg = show_info[dstr]['REG'] || [0,0,0];
    var vip = show_info[dstr]['VIP'] || [0,0,0];
    var regid   = reg[1];
    var regcost = reg[2];
    var regleft = reg[3];
    $('#shoIdREG').val(regid);
    $('#priceREG').text(dollars(regcost));
    if (regleft > 30) {
        $('#ntixStateREG').text(" ");
        $("#ntixREG").prop('disabled', false);
    }
    else if (regleft > 0) {
        $('#ntixStateREG').text("Hurry! Selling out... Only "+regleft+" left!");
        $("#ntixREG").prop('disabled', false);
    }
    else {
        $('#ntixStateREG').text("SOLD OUT");
        $("#ntixREG").val("0");
        $("#ntixREG").prop('disabled', true);
    }

    var vipid   = vip[1];
    var vipcost = vip[2];
    var vipleft = vip[3];
    $('#shoIdVIP').val(vipid);
    $('#priceVIP').text(dollars(vipcost));
    if (vipleft > 30) {
        $('#ntixStateVIP').text(" ");
        $("#ntixVIP").prop('disabled', false);
    }
    else if (vipleft > 0) {
        $('#ntixStateVIP').text("Hurry! Selling out... Only "+vipleft+" left!");
        $("#ntixVIP").prop('disabled', false);
    }
    else {
        $('#ntixStateVIP').text("SOLD OUT");
        $("#ntixVIP").val("0");
        $("#ntixVIP").prop('disabled', true);
    }


    tally_order();
}

var isMobile = {
    Android: function() {
        return navigator.userAgent.match(/Android/i) ? true : false;
    },
    BlackBerry: function() {
        return navigator.userAgent.match(/BlackBerry/i) ? true : false;
    },
    iOS: function() {
        return navigator.userAgent.match(/iPhone|iPad|iPod/i) ? true : false;
    },
    Windows: function() {
        return navigator.userAgent.match(/IEMobile/i) ? true : false;
    },
    any: function() {
        return (isMobile.Android() || isMobile.BlackBerry() || isMobile.iOS() || isMobile.Windows());
    }
};

$(function() {
    document.onkeypress = disableEnter; 
    show_info = show_data();
    $("#tixForm").validationEngine('attach', 
        {promptPosition : "bottomRight",
         onFailure : set_failure_timer,
         onSuccess : set_success_timer
        });

    $("#whatisVIP").dialog({autoOpen:false, modal:true});
    $("#whatisREG").dialog({autoOpen:false, modal:true});
    $("#pikInfo").dialog({autoOpen:false, modal:true, minWidth:540, title:"Enter Pickup Code"});
    $("#fpik").click(function(){$("#pikInfo").dialog("open");return false;});
    $("#getpik").button();
    $("#swapInfo").dialog({autoOpen:false, modal:true, minWidth:540, title:"Exchange Tickets"});
    $("#fswap").click(function(){$("#swapInfo").dialog("open");return false;});
    $("#doswap").button();
    $("#whatisServiceCharge").dialog({autoOpen:false, modal:true});
    $("#explainVIP").click(function(){$("#whatisVIP").dialog("open");return false;});
    $("#explainREG").click(function(){$("#whatisREG").dialog("open");return false;});
    $("#explainServiceCharge").click(function(){$("#whatisServiceCharge").dialog("open");return false;});
    $("#buytix").button();
    $("#cancel").button();
    $(".funcs a").button();
    $("#datepick").datepicker({dateFormat: "yy-mm-dd",
                               minDate: new Date(2014, 09-1, 19), 
                               maxDate: new Date(2014, 11-1, 01),
                               numberOfMonths: 2,
                               beforeShowDay:  perDay,
                               onSelect:       datePick});
}); 

