class Form < ActiveRecord::Base

    belongs_to :user
    belongs_to :project

    has_many :fields
    has_many :results
    has_many :participants, :class_name => 'User'

    accepts_nested_attributes_for :fields

  def num_results(user_id)
    num_results = Array.new
    #num_results = 0
    fields.each do |f|
      result = Result.where(:field_id => f.id, :user_id => user_id)
      result.each do |r|
        if not num_results.include?(r.result)
          num_results << r.result
        end
      end
    end
    num_results.count
  end

  def get_total_results
    num_results = Array.new
    #num_results = 0
    fields.each do |f|
      result = Result.where(:field_id => f.id)
      result.each do |r|
        if not num_results.include?(r.result)
          num_results << r.result
        end
      end
    end
    num_results.count
  end


  def get_last_result(user_id, result)
    time = Time.now - 100.year
    fields.each do |f|
      result = Result.where(:field_id => f.id, :user_id => user_id, :result => result)
      result.each do |r|
        if r.updated_at > time
          time = r.updated_at
        end
      end
    end
    time
  end

end
