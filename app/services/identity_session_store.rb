class IdentitySessionStore < ActionDispatch::Session::AbstractStore
  def session_id_to_session(session_id)
    session_model = IdentitySession
    if session_id.present?
      # always find session (no caching)
      session = session_model.find_by(session_id: session_id)
      return session if session
    end
    yield(session_model) if block_given?
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
    else
    end
    session.session_id
  end

  def delete_session(env, session_id, options)
    session = session_id_to_session(session_id)
    session.destroy! if session
    generate_sid
  end
end

