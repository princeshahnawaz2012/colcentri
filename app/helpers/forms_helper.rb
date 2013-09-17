module FormsHelper

  def add_text_field_link(field)
    link_to image_tag('/iconos/plus.png') + t('forms.new.add_text_field'), "##{field}", :class => "add_text_field_form text_button", :rel => "#{field}", :style => 'color: green'
  end

  def add_select_link(field)
    link_to image_tag('/iconos/plus.png') + t('forms.new.add_select'), "##{field}", :class => "add_select_form text_button", :rel => "#{field}", :style => 'color: green'
  end

  def add_option_link(field)
    link_to image_tag('/iconos/plus.png') + t('forms.new.add_option'), "##{field}", :class => "add_option_form text_button", :rel => "#{field}", :style => 'color: green'
  end

  def add_checkbox_link(field)
    link_to image_tag('/iconos/plus.png') + t('forms.new.add_checkbox'), "##{field}", :class => "add_checkbox_form text_button", :rel => "#{field}", :style => 'color: green'
  end

  def add_date_link(field)
    link_to image_tag('/iconos/plus.png') + t('forms.new.add_date'), "##{field}", :class => "add_date_form text_button", :rel => "#{field}", :style => 'color: green'
  end

  def add_answer_link(field)
    link_to t('forms.new.add_answer'), "##{field}", :class => "add_answer_form", :rel => "#{field}", :style => 'color: green'
  end

  def add_text_field_edit_link(field)
    link_to t('forms.new.add_text_field'), "##{field}", :class => "add_text_field_edit_form", :rel => "#{field}", :style => 'color: green'
  end

  def add_select_edit_link(field)
    link_to t('forms.new.add_select'), "##{field}", :class => "add_select_edit_form", :rel => "#{field}", :style => 'color: green'
  end

  def add_checkbox_edit_link(field)
    link_to t('forms.new.add_checkbox'), "##{field}", :class => "add_checkbox_edit_form", :rel => "#{field}", :style => 'color: green'
  end

  def add_date_edit_link(field)
    link_to t('forms.new.add_date'), "##{field}", :class => "add_date_edit_form", :rel => "#{field}", :style => 'color: green'
  end

  def add_option_edit_link(field)
    link_to t('forms.new.add_option'), "##{field}", :class => "add_option_edit_form", :rel => "#{field}", :style => 'color: green'
  end

end
