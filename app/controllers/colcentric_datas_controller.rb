class ColcentricDatasController < ApplicationController
  skip_before_filter :load_project
  before_filter :find_data, :except => [:index, :new, :create]

  def index
    # show current imports/exports
    @data_imports = current_user.colcentric_datas.find_all_by_type_id(0)
    @data_exports = current_user.colcentric_datas.find_all_by_type_id(1)
    
    respond_to do |f|
      f.html
    end
  end
  
  def show
    respond_to do |f|
      if @data.type_name == :import and @data.need_data? and @data.data == nil
        @data.status_name = :uploading
        @data.processed_data_file_name = nil
        @data.save
        flash.now[:error] = t('colcentric_datas.show_import.import_error')
        f.html { render view_for_data(:show) }
      else
        f.html { render view_for_data(:show) }
      end
    end
  end
  
  def new
    @data = current_user.colcentric_datas.build(:service => 'colcentric')
    @data.type_name = params[:type]
    
    respond_to do |f|
      f.html { render view_for_data(:new) }
    end
  end
  
  def create
    @data = current_user.colcentric_datas.build(params[:colcentric_data])
    
    respond_to do |f|
      if @data.save
        f.html { redirect_to colcentric_data_path(@data) }
      else
        flash.now[:error] = "There were errors with the information you supplied!"
        f.html { render view_for_data(:new) }
      end
    end
  end
  
  def update
    respond_to do |f|
      if !@data.processing? and !@data.update_attributes(params[:colcentric_data])
        if @data.status_name == :uploading
          flash.now[:error] = t('colcentric_datas.show_import.import_error')
        end
        f.html { render view_for_data(:show) }
      else
        if @data.processing?
          f.html { redirect_to colcentric_data_path(@data) }
        else
          flash.now[:error] = "There were errors with the information you supplied!"
          f.html { render view_for_data(:show) }
        end
      end
    end
  end
  
  def destroy
    @data.destroy
    
    respond_to do |f|
      f.html { redirect_to colcentric_datas_path }
    end
  end
  
private

  def find_data
    unless @data = ColcentricData.find_by_id(params[:id])
      flash[:error] = t('not_found.data')
      redirect_to colcentric_datas_path
    end
  end
  
  def view_for_data(action)
    "#{action}_#{@data.type_name}"
  end
  
end
