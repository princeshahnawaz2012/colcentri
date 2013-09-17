module PageNotesHelper




  # Is it used??
  def note_fields(f)
    render 'notes/fields', :f => f
  end


  # Is it used?
  def new_page_note_link(project,page)
    link_to image_tag(t('buttons.create_note')), new_project_page_note_path(project, page), :class => 'note_button'
  end
  
  def remove_form(show_element=nil)
    update_page do |page|  
      page << "$(this).up('form').remove();"
      if show_element
        page[show_element].show
      end
    end
  end

  def show_loading_note_form(id=nil)
    update_page do |page|
      page.loading_note_form(true,id)
    end  
  end
      
  def loading_note_form(toggle,id=nil)
    if toggle
      page["note_form_loading#{"_#{id}" if id}"].show
      page["note_submit#{"_#{id}" if id}"].hide
    else
      page["note_form_loading#{"_#{id}" if id}"].hide
      page["note_submit#{"_#{id}" if id}"].show
    end
  end
end