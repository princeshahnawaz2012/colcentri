// Call this on any function to transform it into a function that will only be called
// once in the given interval. Example: function().throttle(200) for 200ms.
// Useful, for example, to avoid constant processing while typing in a live search box.
Function.prototype.throttle = function(t) {
  var timeout, fn = this, tick = function() {
    var scope = this, args = arguments
    fn.apply(scope, args)
    timeout = null
  }
  return function() {
    var timeout, fn = this
    if (!timeout) timeout = setTimeout(tick, t)
  }
}

// Call this on any function to transform it into a function that will only be called
// after the first pause lasting at least the given interval.
// Call function().debounce(200) for 200ms. Useful, for example, to check an available username.
Function.prototype.debounce = function(t) {
  var timeout, fn = this
  return function() {
    var scope = this, args = arguments
    timeout && clearTimeout(timeout)
    timeout = setTimeout(function() { fn.apply(scope, args) }, t)
  }
}

Element.addMethods({
  forceShow: function(element, display) {
    return $(element).setStyle({ display: (display || 'block') })
  },
  swapVisibility: function(element, other) {
    $(other).forceShow('inline-block')
    return $(element).hide()
  },
  insertOrUpdate: function(element, selector, content) {
    element = $(element)
    var target = element.down(selector)
    if (!target) {
      var classnames = selector.match(/(?:\.\w+)+/)
      if (classnames) classnames = classnames[0].gsub('.', ' ').strip()
      var id = selector.match(/#(\w+)/)
      if (id) id = id[1]
      var tagName = (classnames || id) ? selector.match(/\w+/)[0] : selector
      target = new Element(tagName, { 'class': classnames, id: id })
      element.insert(target)
    }
    target.update(content)
    return target
  }
})

Event.onReady = function(fn) {
  if (document.body) fn()
  else document.on('dom:loaded', fn)
}

Event.addBehavior = function(hash) {
  var behaviors = $H(hash)
  behaviors.each(function(pair) {
    var selector = pair.key.split(':'), fn = pair.value
    document.on(selector[1], selector[0], function(e, el) { fn.call(el, e) })
  })
}
Event.addBehavior.reload = Prototype.emptyFunction

function hideBySelector(selector) {
  insertCss(selector + ' {display:none}')
}

function insertCss(css) {
  var head = document.getElementsByTagName('head')[0],
      style = document.createElement('style')

  style.setAttribute("type", "text/css")

  if (style.styleSheet) { // IE
    style.styleSheet.cssText = css;
  } else { // w3c
    var cssText = document.createTextNode(css);
    style.appendChild(cssText);
  }
  head.appendChild(style)
}

replace_ids = function(s){
  var new_id = new Date().getTime();
  return s.replace(/NEW_RECORD/g, new_id);
}

Event.addBehavior({
  ".add_nested_item:click": function(e){
    link = $(this);
    template = eval(link.href.replace(/.*#/, ''))
    $(link.rel).insert({ bottom: replace_ids(template) });
    Event.addBehavior.reload();
  },
  ".remove_nested_item:click": function(e){
    link = $(this);
    target = link.href.replace(/.*#/, '.')
    link.up(target).hide();
    if(hidden_input = link.previous("input[type=hidden]")) hidden_input.value = '1'
  }
});


Event.addBehavior({
  ".add_text_field_form:click": function(e){
    link = $(this);
    template = "<div class='form_text_fields'><div class='form_title'><label for='form_fields_attributes_NEW_RECORD_Nombre'>Nombre del Campo de texto</label></div><input id='form_fields_attributes_NEW_RECORD_name' name='form[fields_attributes][NEW_RECORD][name]' size='30' type='text' class='form_text_field_edit' /><input id='form_fields_attributes_NEW_RECORD_field_type' name='form[fields_attributes][NEW_RECORD][field_type]' type='hidden' value='0' /><a href='#text_field' class='remove_text_field trash_icon'></a><div class='clear'></div></div>";
    $(link.rel).insert({ bottom: replace_ids(template) });
    Event.addBehavior.reload();
  },
  ".remove_text_field:click": function(e){
    this.parentNode.parentNode.removeChild( this.parentNode );
  },
    ".remove_text_field_edit:click": function(e){
    link = $(this);
    this.parentNode.parentNode.removeChild( this.parentNode );
    field_to_delete = link.name;
    template = "<input type='hidden' name='" + field_to_delete + "' value='" + field_to_delete + "'>";
    $(link.rel).insert({ bottom: replace_ids(template) });
    Event.addBehavior.reload();
  }
});


Event.addBehavior({
  ".add_select_form:click": function(e){
    link = $(this);
    template = "<div class='form_selects'><div class='form_title'><label for='form_fields_attributes_NEW_RECORD_Nombre'>Nombre de la Lista</label></div><input id='form_fields_attributes_NEW_RECORD_name' name='form[fields_attributes][NEW_RECORD][name]' size='30' type='text' class='form_text_field_edit' /><input id='form_fields_attributes_NEW_RECORD_field_type' name='form[fields_attributes][NEW_RECORD][field_type]' type='hidden' value='1' /><a href='#select' class='remove_select trash_icon'></a><div class='option_fields' id='option_NEW_RECORD' style='margin-left: 50px'><a href='#option' class='add_option_form' rel='option_NEW_RECORD' name= 'NEW_RECORD' style='color: green; margin-left: 170px; font-size: 12px'><img src='/iconos/plus.png?1320255860' alt='Plus'> Opción</a><div class='clear'></div></div>";
    //template = "<div class='form_selects'><div class='form_title'><label for='form_fields_attributes_NEW_RECORD_Nombre'>Nombre de la Lista</label></div><input id='form_fields_attributes_NEW_RECORD_name' name='form[fields_attributes][NEW_RECORD][name]' size='30' type='text' class='form_text_field_edit' /><input id='form_fields_attributes_NEW_RECORD_field_type' name='form[fields_attributes][NEW_RECORD][field_type]' type='hidden' value='1' /><a href='#select' class='remove_select trash_icon'></a><div class='option_fields' id='option_NEW_RECORD' style='margin-left: 50px'><a class='add_option_form text_button' style='color: green;' rel='option' href='#option'><img src='/iconos/plus.png?1320255860' alt='Plus'>Opción</a><div class='clear'></div></div>";
    $(link.rel).insert({ bottom: replace_ids(template) });
    Event.addBehavior.reload();
  },
  ".remove_select:click": function(e){
    this.parentNode.parentNode.removeChild( this.parentNode );
  }
});


Event.addBehavior({
  ".add_checkbox_form:click": function(e){
    link = $(this);
    template = "<div class='form_checkboxes'><div class='form_title'><label for='form_fields_attributes_NEW_RECORD_Nombre'>Nombre del Checkbox</label></div><input id='form_fields_attributes_NEW_RECORD_name' name='form[fields_attributes][NEW_RECORD][name]' size='30' type='text' class='form_text_field_edit' /><input id='form_fields_attributes_NEW_RECORD_field_type' name='form[fields_attributes][NEW_RECORD][field_type]' type='hidden' value='2' /><a href='#checkbox' class='remove_checkbox trash_icon'></a><div class='clear'></div></div>";
    $(link.rel).insert({ bottom: replace_ids(template) });
    Event.addBehavior.reload();
  },
  ".remove_checkbox:click": function(e){
     this.parentNode.parentNode.removeChild( this.parentNode );
  }
});


Event.addBehavior({
  ".add_date_form:click": function(e){
    link = $(this);
    template = "<div class='form_dates'><div class='form_title'><label for='form_fields_attributes_NEW_RECORD_Nombre'>Nombre de la Fecha</label></div><input id='form_fields_attributes_NEW_RECORD_name' name='form[fields_attributes][NEW_RECORD][name]' size='30' type='text' class='form_text_field_edit' /><input id='form_fields_attributes_NEW_RECORD_field_type' name='form[fields_attributes][NEW_RECORD][field_type]' type='hidden' value='3' /><a href='#date' class='remove_date trash_icon'></a><div class='clear'></div></div>";
    $(link.rel).insert({ bottom: replace_ids(template) });
    Event.addBehavior.reload();
  },
  ".remove_date:click": function(e){
     this.parentNode.parentNode.removeChild( this.parentNode );
  }
});

Event.addBehavior({
  ".add_option_form:click": function(e){
    link = $(this);
    field_id = link.name;
    template = "<div class='edit_form_options'><div class='form_option'><label for='form_fields_attributes_" + field_id + "_form_options_attributes_NEW_RECORD_Opción' style='margin-right: 5px; margin-top:3px; float: left;'>Opción</label><input id='form_fields_attributes_NEW_RECORD_form_options_attributes_NEW_RECORD_name' name='form[fields_attributes][" + field_id + "][form_options_attributes][NEW_RECORD][name]' size='30' type='text' class='form_text_field_edit' style='float: left; margin-right: 5px'/><a href='#option' class='remove_option trash_icon'></a><div class='clear'></div></div></div>";
    //template = "<div class='form_options' style='width: 500px'><label for='form_fields_attributes_2_form_options_attributes_0_Opción'>Opción</label><input id='form_fields_attributes_2_form_options_attributes_0_name' name='form[fields_attributes][2][form_options_attributes][0][name]' size='30' type='text' value='Werder Bremen' /><a href='#option' class='remove_option_edit trash_icon' name='option_70318468789360' rel='destroyed_fields'></a></div><input id='form_fields_attributes_2_form_options_attributes_0_id' name='form[fields_attributes][2][form_options_attributes][0][id]' type='hidden' value='9' /><div class='clear'></div>";
    $(link.rel).insert({ top: replace_ids(template) });
    Event.addBehavior.reload();
  },
  ".remove_option:click": function(e){
     this.parentNode.parentNode.removeChild( this.parentNode );
  },
    ".remove_option_edit:click": function(e){
    link = $(this);
    this.parentNode.parentNode.removeChild( this.parentNode );
    field_to_delete = link.name;
    template = "<input type='hidden' name='" + field_to_delete + "' value='" + field_to_delete + "'>";
    $(link.rel).insert({ bottom: replace_ids(template) });
    Event.addBehavior.reload();
  }
});
