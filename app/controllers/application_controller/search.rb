class ApplicationController < ActionController::Base

  helper_method :permitted_action_data_params
  helper_method :permitted_action_search_params
  helper_method :permitted_action_pagination_params

  def permitted_action_data_params(options = {}, override_data_params = {})
    options = options.with_indifferent_access.assert_valid_keys(*%w[ namespace save pull ])
    session_action_data = session_action_data(options[:namespace])
    # permit current data
    # optional complete override: permitted_<action>_data_params
    override_method = "permitted_#{action_name}_data_params"
    if respond_to?(override_method, true)
      data_params = send(override_method)
    else
      permit_controller_data_method = "permit_data_params"
      permit_action_data_method     = "permit_#{action_name}_data_params"
      permit_data =
        if respond_to?(permit_action_data_method, true)
          send(permit_action_data_method)
        else
          send(permit_controller_data_method)
        end
      # permit current data
      data_params = params.permit(*permit_data)
    end
    data_params.merge!(override_data_params)
    # merge previous data if no current data
    if (options[:save] || options[:pull]) && data_params.blank?
      data_params.merge!(session_action_data.data_params.with_strong_access.permit(*permit_data))
    end
    # save new data if changed
    data_params = mutate_session_action_params(data_params)
    if options[:save]
      change_session_action_data(session_action_data, data_params: data_params)
      # merge data into params
      params.merge!(data_params)
    end
    data_params
  end

  def permitted_action_search_params(options = {}, override_search_params = {})
    options = options.with_indifferent_access.assert_valid_keys(*%w[ namespace save pull ])
    session_action_data = session_action_data(options[:namespace])
    # permit current search
    # optional complete override: permitted_<action>_data_params
    override_method = "permitted_#{action_name}_search_params"
    if respond_to?(override_method, true)
      search_params = send(override_method)
    else
      permit_controller_search_method = "permit_search_params"
      permit_action_search_method     = "permit_#{action_name}_search_params"
      permit_search =
        if respond_to?(permit_action_search_method, true)
          send(permit_action_search_method)
        else
          send(permit_controller_search_method)
        end
      # permit current search
      search_params = params.permit(*permit_search)
    end
    search_params.merge!(override_search_params)
    # merge previous search if no current search
    if (options[:save] || options[:pull]) && search_params.blank?
      search_params.merge!(session_action_data.search_params.with_strong_access.permit(*permit_search))
    end
    # save new search if changed
    search_params = mutate_session_action_params(search_params)
    if options[:save]
      change_session_action_data(session_action_data, search_params: search_params)
      # merge search into params
      params.merge!(search_params)
    end
    search_params
  end

  def permitted_action_pagination_params(options = {}, override_pagination_params = {})
    options = options.with_indifferent_access.assert_valid_keys(*%w[ namespace save pull ])
    session_action_data = session_action_data(options[:namespace])
    # permit current pagination
    permit_pagination = %w[ limit page ]
    pagination_params = params.permit(*permit_pagination).merge(override_pagination_params).select { |k,v| v.present? }
    # merge previous pagination if no current pagination
    if (options[:save] || options[:pull]) && pagination_params.blank?
      pagination_params.merge!(session_action_data.pagination_params.with_strong_access.permit(*permit_pagination))
    end
    # save new pagination if changed
    pagination_params = mutate_session_action_params(pagination_params)
    if options[:save]
      change_session_action_data(session_action_data, pagination_params: pagination_params)
      # merge pagination into params
      params.merge!(pagination_params)
    end
    pagination_params
  end

private

  def session_action_data(namespace = nil)
    if !(namespace.nil? || namespace.is_a?(String) || namespace.is_a?(Symbol))
      raise ArgumentError "namespace should be a string, symbol, or nil: #{namespace.inspect}"
    end
    # setup
    namespace = namespace.blank? ? "#{controller_name}_#{action_name}_#{params[:id]}".remove(/_+\z/) : namespace
    variable = "@session_#{namespace}_data"
    # return cached record
    return instance_variable_get(variable) if instance_variable_get(variable)
    session_id = session.id
    # find or create record
    record = SessionActionData.find_by(session_id: session_id, namespace: namespace)
    record ||= SessionActionData.new(session_id: session_id, namespace: namespace)
    instance_variable_set(variable, record)
  end

  def change_session_action_data(record, changes)
    record.assign_attributes(changes)
    record.save! if record.has_changes_to_save?
    record
  end

  def mutate_session_action_params(new_params)
    new_params.transform_values do |value|
      # type cast value to string with to_param
      value.is_a?(Array) ? value.map(&:to_param) : value.to_param
    end
    new_params
  end

end
