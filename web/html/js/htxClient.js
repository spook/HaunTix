// Common, testable AJAX client functions.

var CLIENT = {
  use_test: false,
  showing: false,
  stats: {},
  version: "12.08",
  getJSON: function(app, func, msg, onSuccess, delay) {
        var st = new Date().valueOf();  //start time
        if (this.use_test)
            return setTimeout(function() {
                    var et = new Date().valueOf();
                    CLIENT.stat(app,func,et-st);
                    onSuccess(CLIENT.use_test.dispatch(func, msg));
                }, delay);
        $.ajax({url:      app,
                type:     'GET',
                dataType: 'json',
                data:     {func:func, version:this.version, data:$.JSON.encode(msg), ts:st},
                timeout:  13000,
                success:  function(msg) {
                    var et = new Date().valueOf(); //end time
                    CLIENT.stat(app,func,et-st);
                    onSuccess(msg);},
                error: function(jqXHR, textStatus, errorThrown) {
                    var et = new Date().valueOf();
                    CLIENT.stat(app,func,et-st);
                    if (textStatus == 'timeout')
                        return onSuccess({status:'error',
                                    reason:'The request to "'+app
                                    +'" for "'+func+'" has timed out.'});
                    if (jqXHR.status != 0)
                        onSuccess({status:'error',
                                    code:jqXHR.status,
                                    reason:'The request to "'+app
                                    +'" for "'+func+'" has returned '
                                    +jqXHR.status+'-'+jqXHR.statusText});
                }});
    },
  hideStats: function() {
        $('#debug').remove();
        this.showing = false;
    },
  showStats: function() {
        if ($('#debug').length == 0)
            $('<pre id="debug"></pre>').appendTo('body');
        this.showing = true;
        var tmp = [];
        for (var aid in this.stats) {
            var a = this.stats[aid];
            for (var fid in a) {
                var f = a[fid];
                tmp.push(aid+" "+fid+" cnt:"+f.cnt+" avg:"+Math.round(f.avg)+" min:"+f.min+" max:"+f.max);
            }
        }
        $('#debug').text(tmp.join("\n"));
    },
  stat: function(app, func, dt) {
        if (!(app in this.stats)) this.stats[app] = {};
        var a = this.stats[app];
        if (!(func in a)) a[func] = {cnt:0,min:9999999,avg:0,max:0};
        var f = a[func];
        var t = (f.avg * f.cnt) + dt;
        f.cnt++;
        f.avg = t / f.cnt;
        f.min = (f.min > dt) ? dt : f.min;
        f.max = (f.max < dt) ? dt : f.max;
        if (this.showing) this.showStats();
    }
};

String.prototype.ucfirst = function() {
    return this.charAt(0).toUpperCase() + this.slice(1);
}

// Everyone should use CLIENT, so everyone should get this...
$.extend({alert:function(msg, attrs) {
            if (attrs == null) attrs = {};
            attrs = $.extend(true, {type: 'error'}, attrs);
            if (!attrs.title) attrs.title = attrs.type.ucfirst();
            var ui = $('<div title="'+attrs.title+'"><table><tbody><tr>'
                       +'<td><img src="icons/dialog-'+attrs.type+'.gif" style="width:50px"/></td>'
                       +'<td><pre>'+msg+'</pre></td></tr></tbody></table></div>').appendTo('body');
            ui.dialog({autoOpen:       true,
                        closeOnEscape: false,
                        modal:         true,
                        zIndex:        1001,
                        buttons: [{text: 'Close',
                                click: function() {ui.remove();
                                if (attrs.onClose) attrs.onClose();}}]})
                .parent().find('.ui-dialog-titlebar-close').remove();
            // Auto-compute the width needed for the alert.
            ui.dialog('option','width',ui.find('table').outerWidth()+
                      parseInt(ui.css('padding-left'))+
                      parseInt(ui.css('padding-right'))+50);
            ui.dialog('option','position','center');
            return false;
        }
    });
$.extend({confirm:function(msg, attrs) {
            if (attrs == null) attrs = {};
            attrs = $.extend(false, {buttons: [{text:'Cancel'}],
                                     type:    'question'}, attrs);
            if (!attrs.title) attrs.title = attrs.type.ucfirst();
            var ui = $('<div title="'+attrs.title+'"><table><tbody><tr>'
                       +'<td><img src="icons/dialog-'+attrs.type+'.gif" style="width:50px"/></td>'
                       +'<td><pre>'+msg+'</pre></td></tr></tbody></table></div>').appendTo('body');
            var buttons = [];
            var funcs   = {};
            for (var i=0; i<attrs.buttons.length; ++i) {
                funcs[attrs.buttons[i].text] = attrs.buttons[i].click;
                buttons.push({text: attrs.buttons[i].text,
                            click: function(a) {
                            var b     = $(a.target).text();
                            var funcs = ui.funcs;
                            ui.remove();
                            if (funcs[b]) funcs[b]();
                        }});
            }
            ui.dialog({autoOpen:       true,
                        closeOnEscape: false,
                        modal:         true,
                        zIndex:        1001,
                        buttons:       buttons})
                .parent().find('.ui-dialog-titlebar-close').remove();
            ui.funcs = funcs;
            // Auto-compute the width needed for the confirmation box.
            ui.dialog('option','width',ui.find('table').outerWidth()+
                      parseInt(ui.css('padding-left'))+
                      parseInt(ui.css('padding-right'))+50);
            ui.dialog('option','position','center');
            return false;
        }
    });

$(document).ready(function() {
        // The alerts/confirms don't quite size properly without the images being loaded first.
        $('<div id="dialogIconPrep" class="ui-helper-hidden">'
          +'<img src="icons/dialog-question.gif"/>'
          +'<img src="icons/dialog-info.gif"/>'
          +'<img src="icons/dialog-warning.gif"/>'
          +'<img src="icons/dialog-error.gif"/>'
          +'</div>').appendTo('body');
        setTimeout(function(){$('#dialogIconPrep').remove();},3000);
    });
