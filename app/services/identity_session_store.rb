class IdentitySessionStore < ActionDispatch::Session::AbstractStore
  def session_id_to_session(session_id)
    session_model = IdentitySession
    if session_id.present?
      # already found session
      return @session if @session && @session.session_id == session_id
      # find session
      @session = session_model.find_by(session_id: session_id)
      return @session if @session
    end
    # create session
    @session = yield(session_model)
  end

  def find_session(env, session_id)
    session = session_id_to_session(session_id) { |model| model.create!(session_id: generate_sid) }
    [session.session_id, session.data]
  end

  def write_session(env, session_id, session_data, options)
    session = session_id_to_session(session_id) { |model| model.new({ session_id: generate_sid }, options) }
    if session.unsaved? || session.data != session_data
      session.data = session_data
      session.save!
    end
    session.session_id
  end

  def delete_session(env, session_id, options)
    session = session_id_to_session(session_id) { |model| nil }
    session.destroy! if session
    generate_sid
  end
end

