class FieldsController < ApplicationController

  before_filter :load_project

  def load_project
    @current_project = Project.find_by_permalink(params[:project_permalink])
  end


  def edit_fields
    @form = Form.find(params[:id])
    @fields = Field.where(:form_id => @form.id)
    @result = params[:result]
  end

  def update_fields
    form_id = params[:form_id] if not params[:form_id].nil?
    user_id = current_user.id
    form = Form.find(form_id)

    fields = Field.where(:form_id => form_id)

    fields.each do |f|
      @result = Result.where(:field_id => f.id, :user_id => user_id, :result => params[:result]).first
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

      @result.value = value.to_s
      @result.save
    end


    # Only checks the last result
    respond_to do |format|
      if @result.save
        format.html { redirect_to(edit_fields_form_path(:id => form_id, :project_permalink => params[:project_permalink], :result => params[:result]), :notice => t('forms.edit_fields.success') ) }
      else
        format.html { redirect_to(edit_fields_form_path(:id => form_id, :project_permalink => params[:project_permalink], :result => params[:result]), :notice => t('forms.edit_fields.error') ) }
      end
    end
  end


  # GET /fields
  # GET /fields.xml
  def index
    @fields = Field.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fields }
    end
  end

  # GET /fields/1
  # GET /fields/1.xml
  def show
    @field = Field.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @field }
    end
  end

  # GET /fields/new
  # GET /fields/new.xml
  def new
    @field = Field.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @field }
    end
  end

  # GET /fields/1/edit
  def edit
    @field = Field.find(params[:id])
  end

  # POST /fields
  # POST /fields.xml
  def create
    @field = Field.new(params[:field])

    respond_to do |format|
      if @field.save
        format.html { redirect_to(@field, :notice => 'Field was successfully created.') }
        format.xml  { render :xml => @field, :status => :created, :location => @field }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @field.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /fields/1
  # PUT /fields/1.xml
  def update
    @field = Field.find(params[:id])

    respond_to do |format|
      if @field.update_attributes(params[:field])

        format.html { redirect_to(@field) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @field.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /fields/1
  # DELETE /fields/1.xml
  def destroy
    @field = Field.find(params[:id])

    respond_to do |format|
      format.html { redirect_to(edit_form_path(:id => params[:form_id], :project_permalink => @current_project.permalink) ) }
    end
  end
end
