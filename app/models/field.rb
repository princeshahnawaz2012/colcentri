class Field < ActiveRecord::Base

  belongs_to :form
  has_many :form_options
  has_many :results

  accepts_nested_attributes_for :form_options

  FIELD_TYPE = {:text_field => 0,
                  :select => 1,
                  :checkbox => 2,
                  :date => 3}

  FIELD_TYPE_TEXT = { FIELD_TYPE[:text_field] => I18n.t('forms.fields.text'),
                      FIELD_TYPE[:select] => I18n.t('forms.fields.select'),
                      FIELD_TYPE[:checkbox] => I18n.t('forms.fields.checkbox'),
                      FIELD_TYPE[:date] => I18n.t('forms.fields.date')}

  def delete_answers

    results.each do |f|
      begin
        results = Result.where(:field_id => f.id, :user_id => current_user.id, :result => result).first
        results.destroy
      rescue
      end
    end

  end



end
