desc "This task is called by the Heroku cron add-on"

task :cron => :environment do

  users = User.all
  users.each do |user|
    payments = Subscription.where("user_id = ?", user.id)
    payments.each do |payment|
      if payment.trial_expiration_date != nil
        days_left= ((payment.trial_expiration_date - Time.now) / 1.day).round
        if days_left == 5
          puts "Trial reminder email sent to " + user.login
          Emailer.send_email :trial_reminder, user.id
        elsif days_left == 0
          puts "Trial expiration email sent to " + user.login
          Emailer.send_email :trial_expiration, user.id
        end
      elsif payment.expiration_date!= nil
        days_left= ((payment.expiration_date - Time.now) / 1.day).round
        if days_left == 5
          puts "License reminder email sent to " + user.login
          Emailer.send_email :license_reminder, user.id
        elsif days_left == 0
          puts "License expiration email sent to " + user.login
          Emailer.send_email :license_expiration, user.id
        end
      end
    end
  end
end
