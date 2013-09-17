module PagesHelper

  def page_primer(project)
    render 'pages/primer', :project => project if project.editable?(current_user)
  end

  def page_column(project,pages,current_target = nil)
    render 'pages/column',
      :project => project,
      :pages => pages,
      :current_target => current_target
  end


  # Is it used???
  def new_page_link(project)
    if can? :make_pages, project
      link_to image_tag(t('buttons.create_page')), new_project_page_path(project)
    end
  end

  def jsPagesValidation
    javascript_tag <<-EOS
       function validate_pages(form)  {
        var res = true;
        if (form.page_name.value.length < 1){
          form.page_name.up(0).setAttribute('class',"field_with_errors");
          form.page_name.up(0).setAttribute('style',"float: left");
          Element.show(blank_name_error)
          //form.down("div.errors_for").setAttribute('style','display: inline');
          res = false;
        }

      return res;
      }
    EOS

  end

  # Is it used?
  def page_fields(f)
    render 'pages/fields', :f => f
  end


  # Is it used???
  def list_pages_with_toc(pages)
    render pages
  end


  # Is it used??
  def edit_page_link(project,page)
    link_to '', edit_project_page_path(project,page), :class => 'edit_icon', :title => t('common.edit')
  end
  
  def rename_page_link(project,page)
    link_to t('common.rename'), edit_project_page_path(project,page)
  end
  
  def edit_mobile_page_link(project,page)
    link_to t('common.edit'), edit_project_page_path(project,page, :edit_part => 'page')
  end

  def delete_page_link(project,page)
    link_to '', project_page_path(project,page),
      :method => :delete,
      :class => 'big_trash_icon',
      :title => t('common.delete'),
      :confirm => t('confirm.delete_page')
  end
  
  def page_action_links(project,page)
    if can? :update, page
      render 'pages/actions', :project => project, :page => page
    end
  end
  
  def page_slot_fields(slot = 0, before = 0)
    render 'pages/slot_fields', :pos_slot => slot, :pos_before => before
  end
  
  def drag_widget_handle(widget)
    image_tag('drag.png', :class => 'slot_handle')
  end


  # Is it used?
  def page_buttons(project,page)
    if can? :update, page
      render 'pages/buttons', :project => project, :page => page
    end
  end
  
  def insert_widget(widget_id, position, location, view_options={})
    page.call "Page.insertWidget", widget_id, position, location, render(view_options)
  end
end
