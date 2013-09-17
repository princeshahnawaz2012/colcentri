class VideoconferencesController < ApplicationController

  #layout "videoconference"

  #before_filter :load_videoconference_header
  before_filter :check_videoconference_subscription, :except => [ :index, :error, :show, :edit, :start ]
  before_filter :check_video_owner, :only => [ :edit ]
  before_filter :check_video_owner_or_participant, :only => [ :show, :start ]
  skip_before_filter :load_project

  class Encode
    def initialize(key)
      @salt= key
    end

    def encrypt(text)
       Digest::SHA1.hexdigest("--#{@salt}--#{text}--")
    end
  end


  def load_videoconference_header

    #@ruta = "NOTHING"
    #render :partial => 'shared/custom_header', :locals => { :first_bar => params[:controller], :second_bar => params[:action], :actions => 'videoconference'}


    #Application.load_custom_header("A", "B", "C")

    #request.headers["videoconference"] = 'shared/custom_header'
    #request.headers["header_type"] = "Vido"


  end


  def index
    @videoconferences = current_user.videoconferences.where("start_time > ?", Time.now - Videoconference::ALLOW_LINK_MINUTES.minutes)
    @old_videoconferences = current_user.videoconferences.where("start_time < ?", Time.now - Videoconference::ALLOW_LINK_MINUTES.minutes)
    @participations = []
    @old_participations = []
    current_user.participations.each do |p|
      videoconference = Videoconference.find(p.videoconference_id)
      if videoconference.start_time > (Time.now - Videoconference::ALLOW_LINK_MINUTES.minutes)
        @participations.push(p)
      else
        @old_participations.push(p)
      end
    end
    @email = current_user.email
  end


  # Prints details of current videoconference
  def show
      @videoconference = Videoconference.find(params[:id])
      @participants = @videoconference.participants.where("role = ?", Participant::ROLE[:participant])
      @moderators = @videoconference.participants.where("role = ?", Participant::ROLE[:moderator])
      @observers = @videoconference.participants.where("role = ?", Participant::ROLE[:observer])
  end


  # Changes current room details (i.e. topic, start_time...).
  def edit
    @videoconference = Videoconference.find(params[:id])
    @participants = @videoconference.participants.where("role = ?", Participant::ROLE[:participant])
    @moderators = @videoconference.participants.where("role = ?", Participant::ROLE[:moderator])
    @observers = @videoconference.participants.where("role = ?", Participant::ROLE[:observer])

  end


  def new

  end


  def error

  end


  def delete
    @videoconference = Videoconference.find(params[:id])
    room_number = @videoconference.room_number
    room_id = @videoconference.room_id
    @videoconference.participants.each do |p|
      # Send email (except to the owner)
      if p.user_id != @videoconference.user_id
        Emailer.send_email :videoconference_destruction, p.login_or_email, @videoconference.id
      end

      p.destroy
    end
    @videoconference.destroy
    send_destroy_msg_to_ds(room_number, room_id)
    flash[:success] = t('videoconferences.feedback.destroyed')
    redirect_to index_videoconference_path
  end


  def start
    @videoconference = Videoconference.find_by_id(params[:id])
    @user = User.find_by_username_or_email(params[:login])

    if @videoconference

      if ( Time.now.utc > (@videoconference.start_time - Videoconference::ALLOW_LINK_MINUTES.minutes) ) and ( Time.now.utc < @videoconference.start_time + Videoconference::ALLOW_LINK_MINUTES.minutes)
        redirect_to @videoconference.get_personal_session_link(@user.email), :target => "_blank"
      else
        flash[:error] = t('videoconferences.errors.time')
        redirect_to index_videoconference_path
      end
    else
        flash[:error] = t('videoconferences.errors.session_url')
        redirect_to index_videoconference_path
    end

  end


  # Creates a new videoconference
  def new_room


    start_day = params["date"]["day"]
    start_month = params["date"]["month"]
    start_year = params["date"]["year"]
    start_hour = params["date"]["hour"]
    start_minute = params["date"]["minute"]

    @duration = Integer(params["duration"])
    @timezone = Integer(params["timezone"])

    @start_time = Time.utc(start_year, start_month, start_day, start_hour, start_minute)
    @start_time -= @timezone


    # Check for a room

    if can_have_more_videoconferences

      room_number = get_room_number

      if room_number == "NA"
        flash[:error] = t('videoconferences.errors.not_available')
        redirect_to new_videoconference_path
      else
        room_id = create_room(room_number)
            save_room(room_number, room_id)
            create_participants(params["user_or_email"], params["role"])
            send_participants_to_ds
            send_invitation_email_to_new_participants

            #Check password

            e = Encode.new("This is a very hard key.")
            pass1 = e.encrypt(params["password"])
            pass2 = e.encrypt(params["repeat_password"])
            if pass1 != pass2
              flash[:error] = t('videoconferences.errors.password')
              redirect_to edit_videoconference_path(:id => @videoconference.id)
            else
              if params["password"] != ''
                @videoconference.password = pass1
                @videoconference.save
                send_password_to_ds(@videoconference.room_number, @videoconference.room_id, params["password"])
              end

              flash[:success] = t('videoconferences.feedback.new_room')
              redirect_to :action => 'edit', :id => @videoconference.id

          end
      end
    else
      flash[:error] = t('videoconferences.errors.max_videoconferences')
      redirect_to new_videoconference_path
    end

  end


  # Checks if user can have more videoconferences at
  def can_have_more_videoconferences

    num_videoconferences_subscriptions = current_user.num_videoconferences

    videoconferences = current_user.videoconferences.where("start_time > ?", Time.now.utc)


    num_videoconferences_at_same_time = 0
    local_time = Time.now

    videoconferences.each do |v|


      local_time = v.start_time
      if (v.start_time >= @start_time and v.start_time <= @start_time + @duration.minutes) or (v.start_time + v.duration.minutes >= @start_time and v.start_time + v.duration.minutes <= @start_time + @duration.minutes)
        num_videoconferences_at_same_time += 1
      end

    end


    num_videoconferences_at_same_time < num_videoconferences_subscriptions


  end

  # Checks the database in order to find an available room for the chosen day and duration.
  def get_room_number

    Videoconference::ROOM_NUMBER.each do |r|
      sessions = Videoconference.find(:all, :conditions=>["room_number = ? AND start_time > ?", r, Time.now])

      session_check = true

      sessions.each do |s|

        if ( (@start_time < (s.start_time - Videoconference::BETWEEN_VIDEOCONFERENCE_MINUTES.minutes) == false) or ( ((@start_time + @duration.minutes) < (s.start_time - Videoconference::BETWEEN_VIDEOCONFERENCE_MINUTES.minutes)) == false) ) and ( ((s.start_time + @duration.minutes + Videoconference::BETWEEN_VIDEOCONFERENCE_MINUTES.minutes) < @start_time) == false)
          session_check = false
        end

        #session_check = (session_check) and (@start_time < s.start_time) and ((@start_time + @duration.minutes) < s.start_time)
      end



      if session_check == true
        return r
      end

    #flash[:error] = t('videoconferences.errors.schedule')
        #redirect_to index_videoconference_path

    end

    return "NA"
  end


  # Sends a create room request to Digital Samba and returns session's id
  def create_room(room_number)
    url = URI.parse(Videoconference::API_URL + room_number.to_s + '/session/')

    req = Net::HTTP::Put.new(url.path)
    req.basic_auth room_number.to_s, room_number.to_s
    req.set_form_data({"topic" => params["topic"], "duration" => params["duration"], "start_time" => @start_time.strftime("%Y-%m-%d %H:%M:%S"), "timezone" => params["timezone"], "password" => params["password"]})

    response = Net::HTTP.new(url.host, url.port).start {|http| http.request(req)}

    res = Hash.from_xml response.body
    res["xml"]["id"]
  end


  # Saves current room into the database
  def save_room(room_number, room_id)

    @videoconference = current_user.videoconferences.new
    @videoconference.topic = params["topic"]
    @videoconference.start_time = @start_time - params["timezone"].to_i
    @videoconference.duration = @duration
    @videoconference.timezone = @timezone
    @videoconference.room_number = room_number
    @videoconference.room_id = room_id
    @videoconference.save

  end


  # Looks for videoconference assistants and send them e-mail invitation.
  # An assistant could be a Colcentric's member (e-mail sent to e-mail stored in Colcentric)
  # or not (e-mail sent to that indicated in text field).
  # Function expects a list of usernames or emails, their role in the videoconference and a boolean
  # value setting the creation of the owner as moderator
  def create_participants(user_or_email, role, moderator = true)

    # First of all, if the owner requires being moderator, it must be created.
    # No invitation e-mail to the moderator

    if moderator == true
      new_moderator = @videoconference.participants.build
      new_moderator.role = Participant::ROLE[ :moderator ]
      new_moderator.login_or_email = current_user.login
      new_moderator.user_id = current_user.id
      new_moderator.invitation_email = true
      new_moderator.save
    end


    # After that, participants are created

    targets = user_or_email.split( /, */ )

    targets.each do |person|
      user = User.find_by_username_or_email(person)
      if user

        participant = Participant.where( :user_id => user.id, :videoconference_id => @videoconference.id).first

        if @videoconference.participants.count >= Videoconference::MAX_PARTICIPANTS
          flash[:error] = t('videoconferences.errors.max_participants', :max_participants => Videoconference::MAX_PARTICIPANTS)
        elsif participant
          flash[:error] = t('videoconferences.errors.participant_in_video', :name => participant.login_or_email)
        else
          #Create participant
          participant = @videoconference.participants.build
          participant.role = role
          participant.login_or_email = person
          participant.invitation_email = false
          participant.user_id = user.id
          participant.save
        end
      else
        #Create participant
        participant = @videoconference.participants.build
        participant.role = role
        participant.login_or_email = person
        participant.invitation_email = false
        participant.save

      end
    end
  end

  # Sends message to Digital Samba in order to add a new participant to the videoconference.
  def send_participants_to_ds

    php_translator = "http://www.colcentric.com/videoconference.php"
    participants = @videoconference.participants
    emails = ''
    first_names = ''
    last_names = ''
    roles = ''
    delimiter = '!!'

    participants.each do |p|
      user = User.find_by_username_or_email(p.login_or_email)
      if user
        emails += user.email + delimiter
        first_names += user.first_name + delimiter
        last_names += user.last_name + delimiter
        roles += p.role.to_s + delimiter
      end
    end

    url = URI.parse(php_translator)

    req = Net::HTTP::Post.new(url.path)
    #req.basic_auth @videoconference.room_number.to_s, @videoconference.room_number.to_s
    req.set_form_data({"id" => @videoconference.room_id, "email" => emails, "first_name" => first_names, "last_name" => last_names, "role" => roles, "send_email_invitation" => false, "room_number" => @videoconference.room_number})

    response = Net::HTTP.new(url.host, url.port).start {|http| http.request(req)}

    #flash[:error] = response.body

    #res = Hash.from_xml response.body
  end


  # Sends email to new participants in videoconference
  def send_invitation_email_to_new_participants

    participants = @videoconference.participants
    participants.each do |p|
      if p.invitation_email == false
        user = User.find_by_username_or_email(p.login_or_email)
        if user # Colcentric user
          Emailer.send_email :videoconference_invitation, user.id, @videoconference.id
        else # Non-Colcentric user
          Emailer.send_email :videoconference_invitation_non_member, p.login_or_email, @videoconference.id
        end
      end

    end
  end



  def send_password_to_ds(room_number, room_id, password)
    url = URI.parse(Videoconference::API_URL + room_number.to_s + '/session/')

    req = Net::HTTP::Post.new(url.path)
    req.basic_auth room_number.to_s, room_number.to_s
    req.set_form_data({"id" => room_id, "password" => password})

    response = Net::HTTP.new(url.host, url.port).start {|http| http.request(req)}

    res = Hash.from_xml response.body
    res["xml"]["id"]
  end


  # Performs all tasks that must be done in order to edit videoconference's details.
  def edit_room

    @videoconference = Videoconference.find(params[:id])


    #change_room_number
    update_room
    create_participants(params[:user_or_email], params[:role], false) if params[:user_or_email]
    send_participants_to_ds if params[:user_or_email] # New participants. We must send the entire list again to DS


    #Check password

    e = Encode.new("This is a very hard key.")
    pass1 = e.encrypt(params["password"])
    pass2 = e.encrypt(params["repeat_password"])
    if pass1 != pass2
      flash[:error] = t('videoconferences.errors.password')
      redirect_to edit_videoconference_path(:id => @videoconference.id)
    else
      if (@videoconference.password != pass1) and params["password"] != "NOTHING"  and params["password"] != ''
        @videoconference.password = pass1
        @videoconference.save
        send_password_to_ds(@videoconference.room_number, @videoconference.room_id, params["password"])
      end

      if not flash.has_key?(:error)
        flash[:success] = t('videoconferences.edit.success')
      end

      redirect_to :action => 'edit', :id => @videoconference.id
    end

  end


  # Checks for changes in videoconference fields and updates them
  def update_room
    send_msg = false
    if params["topic"] != @videoconference.topic
      @videoconference.update_attribute(:topic, params["topic"])
      send_msg = true
    end


    if params["duration"] != @videoconference.duration
      @videoconference.update_attribute(:duration, params["duration"])
      send_msg = true
    end

    if params["timezone"] != @videoconference.timezone
      @videoconference.update_attribute(:timezone, params["timezone"])
      send_msg = true
    end

    start_day = params["date"]["day"]
    start_month = params["date"]["month"]
    start_year = params["date"]["year"]
    start_hour = params["date"]["hour"]
    start_minute = params["date"]["minute"]

    #@duration = Integer(params["duration"])

    start_time = Time.utc(start_year, start_month, start_day, start_hour, start_minute)
    start_time -= params["timezone"].to_i


    if start_time != @videoconference.start_time
      # Check if this start_time is available
      room_number = get_room_number

      if room_number == "NA"
        flash[:error] = t('videoconferences.errors.not_available')
      else
        if room_number != @videoconference.room_number
          @videoconference.update_attribute(:room_number, room_number)
          @videoconference.update_attribute(:start_time, start_time)
          send_msg = true
        end
      end


    end


    if send_msg == true
      send_update_msg_to_ds
    end

  end


  # Sends message to Digital Samba to inform about the changes made by user in videoconference's details.
  def send_update_msg_to_ds

    url = URI.parse(Videoconference::API_URL + @videoconference.room_number.to_s + '/session/')

    req = Net::HTTP::Post.new(url.path)
    req.basic_auth @videoconference.room_number.to_s, @videoconference.room_number.to_s
    req.set_form_data({"id" => @videoconference.room_id, "topic" => @videoconference.topic, "duration" => @videoconference.duration, "timezone" => @videoconference.timezone})

    response = Net::HTTP.new(url.host, url.port).start {|http| http.request(req)}

  end


  # Sends message to Digital Samba to destroy a room.
  def send_destroy_msg_to_ds(room_number, room_id)
    url = URI.parse(Videoconference::API_URL + room_number.to_s + '/session/')

        req = Net::HTTP::Delete.new(url.path)
        req.basic_auth room_number.to_s, room_number.to_s
        req.set_form_data({"id" => room_id})

        response = Net::HTTP.new(url.host, url.port).start {|http| http.request(req)}

  end


  def show_records

    @videoconference = Videoconference.find(params[:id])

  end

  # Help function
  # Source: http://blog.assimov.net/post/653645115/post-put-arrays-with-ruby-net-http-set-form-data
  # Using custom set_form_data and urlencode
  # Ruby NET/HTTP does not support duplicate parameter names
  # File net/http.rb, line 1426
  def set_form_data(request, params, sep = '&')
    request.body = params.map {|k,v|
      if v.instance_of?(Array)
        v.map {|e| "#{urlencode(k.to_s)}=#{urlencode(e.to_s)}"}.join(sep)
      else
        "#{urlencode(k.to_s)}=#{urlencode(v.to_s)}"
      end
    }.join(sep)
    request.content_type = 'application/x-www-form-urlencoded'
  end


  def urlencode(str)
    str.gsub(/[^a-zA-Z0-9_\.\-]/n) {|s| sprintf('%%%02x', s[0]) }
  end


  # Removes a participant from a videoconference
  def delete_participant
    p = Participant.find(params[:participant])
    name = p.login_or_email
    @videoconference = Videoconference.find(params[:id]) if p
    p.destroy if p
    send_participants_to_ds

    #p = Participant.find(params[:participant])
    #if not p
    flash[:success] = t('videoconferences.edit.delete_participant', :name => name)
    #else
    #flash[:error] = t('.videoconferences.errors.delete_participant', :name => name)
    #end

    redirect_to edit_videoconference_path(:id => params[:id])
  end


  # Not currently used
  def destroy
   # authorize! :destroy, @current_project
   # if @videoconference.close_room
   #   @videoconference.destroy
   #   respond_to do |f|
   #     f.any(:html, :m) {
   #       flash[:success] = t('projects.videoconference.deleted')
   #       redirect_to projects_path(@current_project)
   #     }
   #   end
   # else
   #   flash[:error] = t('projects.videoconference.deleted_failed')
   #   redirect_to projects_path(@current_project)
   # end
  end



  # Has current user paid for a videoconference?
  def check_videoconference_subscription

    if not current_user.has_videoconference_subscription?
      redirect_to error_videoconference_path
    end

  end


  # Index page. The user must have a videoconference subscription or must be a participant of a future videoconference. If not, error shown.
  def check_pending_videoconferences

    if (not current_user.videoconference_subscription or not current_user.videoconference_subscription.active?) and not current_user.future_participations?
      redirect_to error_videoconference_path
    end

  end


  # Is current user the owner of the videoconference?
  def check_video_owner

    videoconference = Videoconference.find(params[:id])

    if current_user.id != videoconference.user_id
      flash[:error] = t('videoconferences.errors.not_allowed')
      redirect_to index_videoconference_path
    end
  end


  def check_video_owner_or_participant

    videoconference = Videoconference.find(params[:id])
    participants =  Participant.where("videoconference_id = ?", videoconference.id)

    permission = false

    participants.each do |p|
      if p.user_id == current_user.id
        permission = true
      end
    end

    if permission == false and current_user.id != videoconference.user_id
      flash[:error] = t('videoconferences.errors.not_allowed')
      redirect_to index_videoconference_path
    end

  end

end
