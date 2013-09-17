class Videoconference < ActiveRecord::Base

  belongs_to :user
  has_many :participants, :foreign_key => 'videoconference_id'
  has_many :recordings, :foreign_key => 'videoconference_id'

  attr_accessible :video_number, :participants

  MAX_PARTICIPANTS = 25
  ALLOW_LINK_MINUTES = 15
  BETWEEN_VIDEOCONFERENCE_MINUTES = 30

  ROOM_NUMBER = [ :colcentric0001, :colcentric0002, :colcentric0003, :colcentric0004, :colcentric0005, :colcentric0006, :colcentric0007, :colcentric0008, :colcentric0009, :colcentric0010 ]

  TIMEZONE = [ [ "UTC -12:00" , "-1200"],  ["UTC -11:00" , "-1100"], ["UTC -10:00" , "-1000"], ["UTC -9:00" , "-0900"], ["UTC -8:00" , "-0800"], ["UTC -7:00" , "-0700"], ["UTC -6:00" , "-0600"], ["UTC -5:00" , "-0500"], ["UTC -4:00" , "-0400"], ["UTC -3:00" , "-0300"], ["UTC -2:00" , "-0200"], ["UTC -1:00" , "-0100"], ["UTC" , "+0000"], ["UTC +1:00" , "+0100"], ["UTC +2:00" , "+0200"], ["UTC +3:00" , "+0300"], ["UTC +4:00" , "+0400"], ["UTC +5:00" , "+0500"], ["UTC +6:00" , "+0600"], ["UTC +7:00" , "+0700"], ["UTC +8:00" , "+0800"], ["UTC +9:00" , "+0900"], ["UTC +10:00" , "+1000"], ["UTC +11:00" , "+1100"], ["UTC +12:00" , "+1200"] ]

  TIMEZONE2 = [ [ "UTC -12:00" , -(12 * 60 *60)],  ["UTC -11:00" , -(11 * 60 *60)], ["UTC -10:00" , -(10 * 60 *60)], ["UTC -9:00" , -(9 * 60 *60)], ["UTC -8:00" , -(8 * 60 *60)], ["UTC -7:00" , -(7 * 60 *60)], ["UTC -6:00" , -(6 * 60 *60)], ["UTC -5:00" , -(5 * 60 *60)], ["UTC -4:00" , -(4 * 60 *60)], ["UTC -3:00" , -(3 * 60 *60)], ["UTC -2:00" , -(2 * 60 *60)], ["UTC -1:00" , -(1 * 60 *60)], ["UTC" , 0], ["UTC +1:00" , (1 * 60 *60)], ["UTC +2:00" , (2 * 60 *60)], ["UTC +3:00" , (3 * 60 *60)], ["UTC +4:00" , (4 * 60 *60)], ["UTC +5:00" , (5 * 60 *60)], ["UTC +6:00" , (6 * 60 *60)], ["UTC +7:00" , (7 * 60 *60)], ["UTC +8:00" , (8 * 60 *60)], ["UTC +9:00" , (9 * 60 *60)], ["UTC +10:00" , (10 * 60 *60)], ["UTC +11:00" , (11 * 60 *60)], ["UTC +12:00" , (12 * 60 *60)] ]


  API_URL = "http://onsync.digitalsamba.com/api/1/"


  def old?
    start_time < (Time.now - ALLOW_LINK_MINUTES.minutes)
  end


  def num_moderators
    participants.where("role = ?", Participant::ROLE[:moderator]).count
  end

  def num_participants
    participants.where("role = ?", Participant::ROLE[:participant]).count
  end

  def num_observers
    participants.where("role = ?", Participant::ROLE[:observer]).count

  end


  def get_personal_session_link(email)

    url = URI.parse('http://onsync.digitalsamba.com/api/1/' + room_number.to_s + '/invitees/id/' + room_id.to_s)

    req = Net::HTTP::Get.new(url.path)
    req.basic_auth room_number, room_number
    #req.set_form_data( { "id" => room_id})

    response = Net::HTTP.new(url.host, url.port).start {|http| http.request(req)}

    res = Hash.from_xml response.body

    #["moderators", "participants", "observers"].each do |role|

    if num_moderators == 1
      if res["xml"]["moderators"]["item"]["email"] == email
        return res["xml"]["moderators"]["item"]["personal_session_link"]
      end
    elsif num_moderators > 1
      res["xml"]["moderators"]["item"].each do |p|
        if p["email"] == email
          return p["personal_session_link"]
        end
      end
    end

    if num_participants == 1
      if res["xml"]["participants"]["item"]["email"] == email
        return res["xml"]["participants"]["item"]["personal_session_link"]
      end
    elsif num_participants > 1
      res["xml"]["participants"]["item"].each do |p|
        if p["email"] == email
          return p["personal_session_link"]
        end
      end
    end

    if num_observers == 1
      if res["xml"]["observers"]["item"]["email"] == email
        return res["xml"]["observers"]["item"]["personal_session_link"]
      end
    elsif num_observers > 1
      res["xml"]["observers"]["item"].each do |p|
        if p["email"] == email
          return p["personal_session_link"]
        end
      end
    end




 end




  def get_session_link_old
    url = URI.parse('http://onsync.digitalsamba.com/api/1/' + room_number.to_s + '/session/id/' + room_id.to_s)

    req = Net::HTTP::Get.new(url.path)
    req.basic_auth room_number, room_number
    #req.set_form_data({"topic" => "Prueba Ivan", "duration" => "30", "start_time" => "2011-07-29 10:00:00", "timezone" => "UTC"})

    response = Net::HTTP.new(url.host, url.port).start {|http| http.request(req)}

    res = Hash.from_xml response.body

    res["xml"]["session_link"]


  end


  def create_room2

    params = []
    params << ['topic', 'Prueba1']
    params << ['duration', 60]
    params << ['start_time', '2011-06-27 14:45']
#    params << ['invited_participants']





    #params = []
    #params << ['name', name]
    #params << ['meetingID', meeting_id]
    #params << ['maxParticipants', MAX_PARTICIPANTS]
    #params << ['logoutURL', logout_url]

   # params << ['attendeePW', attendee_pw] if attendee_pw
   # params << ['moderatorPW', moderator_pw] if moderator_pw
   # params << ['welcome', welcome_msg] if welcome_msg

    url = create_msg_for_bbb('create', params)
    response = send_msg_to_bbb(url)

    return parse_xml(response, 'returncode', true)
  end

  def get_join_url(user)
    params = []
    params << ['fullName', user.name]
    params << ['meetingID', meeting_id]
    if moderator?(user)
      params << ['password', moderator_pw]
    else
      params << ['password', attendee_pw]
    end
    params << ['userID', user.id]

    return create_msg_for_bbb('join', params)
  end

  def is_meeting_running()
    params = []
    params << ['meetingID', meeting_id]

    url = create_msg_for_bbb('isMeetingRunning', params)
    response = send_msg_to_bbb(url)

    return parse_xml(response, 'running') == "true"
  end

  def close_room
    params = []
    params << ['meetingID', meeting_id]
    params << ['password', moderator_pw]

    url = create_msg_for_bbb('end', params)
    response = send_msg_to_bbb(url)

    return parse_xml(response, 'messageKey')
  end

  def moderator?(user)
    project.admin?(user)
  end



  protected

  def send_msg_to_bbb(url)
    open(URI.escape(url)).read
  end

  def create_msg_for_bbb(action,params)
   # domain = 'http://46.137.87.68'   # without final /
   # salt = '9dd81b4bbbe00ae8b8dacbe8fda35cfe'
   # context = '/bigbluebutton/api/'
   # domain = Colcentric.config.bbb_domain
   # salt = Colcentric.config.bbb_salt
   # context = Colcentric.config.bbb_context '/bigbluebutton/api/'

    domain = 'http://onsync.digitalsamba.com/api/4.0/colcentric/session'


    aux_params = []
    params.each do |param|
       aux_params << param.join("=")
    end
    query_params = aux_params.join("&")

    #sha1 = Digest::SHA1.hexdigest(URI.escape(action + query_params + salt))
    #url = domain + context + action + '?' + query_params + '&checksum=' + sha1
    sha1 = Digest::SHA1.hexdigest(URI.escape(action + query_params))
    url = domain + action + '?' + query_params + '&checksum=' + sha1
    Rails.logger.error(url)
    return url
  end

  def parse_xml(xml_data, return_msg ,save_info=false)
    Rails.logger.error(xml_data)
    parser = XML::Parser.string(xml_data)
    doc = parser.parse

    unless doc.find_first('returncode').child.content == 'SUCCESS'
      return false
    end

    if save_info
      #meeting_id = doc.find_first('meetingID').child
      self.attendee_pw = doc.find_first('attendeePW').child
      self.moderator_pw = doc.find_first('moderatorPW').child
      self.save
    end

    return doc.find_first(return_msg).child.content
  end
end
