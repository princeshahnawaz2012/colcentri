class FormsController < ApplicationController
  # GET /forms
  # GET /forms.xml

  before_filter :load_project

  def load_project
    @current_project = Project.find_by_permalink(params[:project_permalink])
  end


  def index
    begin
      @own_forms = @current_project.forms & current_user.forms
    rescue
      @own_forms = []
    end

    begin
      @other_forms = @current_project.forms - current_user.forms
    rescue
      @other_forms = []
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @forms }
    end
  end

  # GET /forms/1
  # GET /forms/1.xml
  def show
    @form = Form.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @form }
    end
  end

  # GET /forms/new
  # GET /forms/new.xml
  def new
    @form = current_user.forms.build
    @user_id = current_user.id
    @fields = @form.fields.build
    @fields.form_options.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @form }
    end
  end

  # GET /forms/1/edit
  def edit
    @form = Form.find(params[:id])
    @text_fields = Field.where(:form_id => @form.id, :field_type => Field::FIELD_TYPE[:text_field])
    @selects = Field.where(:form_id => @form.id, :field_type => Field::FIELD_TYPE[:select])
    @checkboxes = Field.where(:form_id => @form.id, :field_type => Field::FIELD_TYPE[:checkbox])
    @dates = Field.where(:form_id => @form.id, :field_type => Field::FIELD_TYPE[:date])
  end


  def answer
    @form = Form.find(params[:id])
    @fields = Field.where(:form_id => @form.id)
    @result = params[:result]
  end


  def get_answers
    form_id = params[:form_id] if not params[:form_id].nil?
    user_id = params[:user_id] if not params[:user_id].nil?
    result = params[:result] if not params[:result].nil?
    form = Form.find(form_id)

    fields = Field.where(:form_id => form_id)

    fields.each do |f|

      value = params["field_" + f.id.to_s]
      if f.field_type == 3
        day = params["field_" + f.id.to_s + "_day"]
        month = params["field_" + f.id.to_s + "_month"]
        year = params["field_" + f.id.to_s + "_year"]
        value = day.to_s + "-" + month.to_s + "-" + year.to_s
      elsif f.field_type == 2
        if value.to_s == 1.to_s
          value = "Yes"
        else
          value = "No"
        end
      end

      r = Result.new
      r.field_id = f.id
      r.user_id = user_id
      r.value = value.to_s
      r.result = result
      r.save
    end

   redirect_to list_answers_form_path(:id => form_id, :project_permalink => @current_project.permalink)

  end


  def show_answers
    @form = Form.find(params[:id])
    @fields = Field.where(:form_id => @form.id)
  end


  def list_answers
    @form = Form.find(params[:id])
    @fields = Field.where(:form_id => @form.id)
  end


  def delete_answers
    form = Form.find(params[:id])
    fields = Field.where(:form_id => form.id)
    result = params[:result]

    fields.each do |f|
      begin
        results = Result.where(:field_id => f.id, :user_id => current_user.id, :result => result).first
        results.destroy
      rescue
      end

    end

    redirect_to list_answers_form_path(:id => form.id, :project_permalink => @current_project.permalink)
  end


  # POST /forms
  # POST /forms.xml
  def create

    permalink = params[:form][:project_permalink]
    params[:form].delete :project_permalink
    @form = Form.new(params[:form])

    respond_to do |format|
      if @form.save
        format.html { redirect_to( index_forms_path(:project_permalink => permalink), :notice => t('forms.new.success')) }
      else
        format.html { redirect_to( index_forms_path(:project_permalink => permalink), :notice => t('forms.new.error')) }
      end
    end
  end


  def publish
    @form = Form.find(params[:id])
    @form.publish = true

    respond_to do |format|
      if @form.save
        format.html { redirect_to(index_forms_path(:project_permalink => params[:project_permalink]), :notice => t('forms.publish.success')) }
      else
        format.html { redirect_to(index_forms_path(:project_permalink => params[:project_permalink]), :notice => t('forms.publish.error')) }
      end
    end

  end


  def close
    @form = Form.find(params[:id])
    @form.publish = false

    respond_to do |format|
      if @form.save
        format.html { redirect_to(index_forms_path(:project_permalink => params[:project_permalink]), :notice => t('forms.close.success')) }
      else
        format.html { redirect_to(index_forms_path(:project_permalink => params[:project_permalink]), :notice => t('forms.close.error')) }
      end
    end
  end


  # PUT /forms/1
  # PUT /forms/1.xml
  def update
    permalink = params[:form][:project_permalink]
    params[:form].delete :project_permalink
    @form = Form.find(params[:id])

    @fields = Field.where(:form_id => @form.id)
    @fields.each do |f|
      field_id = "field_" + f.id.to_s
      if params[field_id] # Field has to be deleted along with its results.
        results = Result.where(:field_id => f.id)
        results.each do |r|
          r.destroy
        end
        if f.type == Field::FIELD_TYPE[:select]


        end
        f.destroy
      end
    end

    respond_to do |format|
      begin # TODO - CHECK THIS EXCEPTION
        if @form.update_attributes(params[:form])
          format.html { redirect_to(edit_form_path(:id => @form.id, :project_permalink => permalink), :notice => t('forms.update.success')) }
          #format.html { redirect_to(edit_form_path(:id => @form.id, :project_permalink => permalink) ) }
        else
          format.html { redirect_to(edit_form_path(:id => @form.id, :project_permalink => permalink), :notice => t('forms.update.error')) }
        end
      rescue
        format.html { redirect_to(edit_form_path(:id => @form.id, :project_permalink => permalink), :notice => t('forms.update.success')) }
      end

    end
  end


  # DELETE /forms/1
  # DELETE /forms/1.xml
  def destroy
    permalink = params[:project_permalink]
    @form = Form.find(params[:id])

    @form.fields.each do |field|
      field.delete_answers
      field.destroy
    end


    @form.destroy

    respond_to do |format|
      format.html { redirect_to(index_forms_path(:project_permalink => permalink), :notice => t('forms.destroy.success') ) }
      format.xml  { head :ok }
    end
  end
end
