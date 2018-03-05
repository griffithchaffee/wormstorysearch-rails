class ApplicationController < ActionController::Base

  helper_method :permitted_action_model_params
  helper_method :permitted_action_data_params
  helper_method :permitted_action_search_params
  helper_method :permitted_action_pagination_params

  class << self
    def generate_permitted_record_params(namespace = controller_name.singularize)
      define_method("permitted_action_#{namespace}_params") do |override_record_params = {}|
        # optional complete override: permitted_<action>_record_params
        override_method = "permitted_#{action_name}_#{namespace}_params"
        if respond_to?(override_method, true)
          record_params = send(override_method)
        else
          permit_controller_record_method = "permit_#{namespace}_params"
          permit_action_record_method     = "permit_#{action_name}_#{namespace}_params"
          permit_params =
            if respond_to?(permit_action_record_method, true)
              send(permit_action_record_method)
            elsif respond_to?(permit_controller_record_method, true)
              send(permit_controller_record_method)
            else
              raise ArgumentError, "#{permit_action_record_method} or #{permit_controller_record_method} must be defined"
            end
          # permit current record
          record_params = params.optional(namespace).permit(*permit_params)
        end
        record_params.merge(override_record_params)
      end
    end
  end

  def permitted_action_record_params(override_record_params = {})
    # optional complete override: permitted_<action>_record_params
    override_method = "permitted_#{action_name}_record_params"
    if respond_to?(override_method, true)
      record_params = send(override_method)
    else
      permit_controller_record_method = "permit_record_params"
      permit_action_record_method     = "permit_#{action_name}_record_params"
      permit_params =
        if respond_to?(permit_action_record_method, true)
          send(permit_action_record_method)
        elsif respond_to?(permit_controller_record_method, true)
          send(permit_controller_record_method)
        else
          raise ArgumentError, "#{permit_action_record_method} or #{permit_controller_record_method} must be defined"
        end
      # permit current record
      record_params = params.permit(*permit_params)
    end
    record_params.merge(override_record_params)
  end

  def permitted_action_data_params(options = {}, override_data_params = {})
    options = options.with_indifferent_access.assert_valid_keys(*%w[ namespace save pull ])
    session_action_data = session_action_data(options[:namespace])
    # permit current data
    # optional complete override: permitted_<action>_data_params
    override_method = "permitted_#{action_name}_data_params"
    if respond_to?(override_method, true)
      data_params = send(override_method).merge(override_data_params)
    else
      permit_controller_data_method = "permit_data_params"
      permit_action_data_method     = "permit_#{action_name}_data_params"
      permit_params =
        if respond_to?(permit_action_data_method, true)
          send(permit_action_data_method)
        elsif respond_to?(permit_controller_data_method, true)
          send(permit_controller_data_method)
        else
          raise ArgumentError, "#{permit_action_data_method} or #{permit_controller_data_method} must be defined"
        end
      # permit current data
      data_params = params.permit(*permit_params).merge(override_data_params)
      # merge previous data if no current data
      if (options[:save] || options[:pull]) && data_params.blank?
        data_params.merge!(session_action_data.data_params.with_strong_access.permit(*permit_params))
      end
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
      search_params = send(override_method).merge(override_search_params)
    else
      permit_controller_search_method = "permit_search_params"
      permit_action_search_method     = "permit_#{action_name}_search_params"
      permit_params =
        if respond_to?(permit_action_search_method, true)
          send(permit_action_search_method)
        elsif respond_to?(permit_controller_search_method, true)
          send(permit_controller_search_method)
        else
          raise ArgumentError, "#{permit_action_search_method} or #{permit_controller_search_method} must be defined"
        end
      # permit current search
      search_params = params.permit(*permit_params).merge(override_search_params)
      # merge previous search if no current search
      if (options[:save] || options[:pull]) && search_params.blank?
        search_params.merge!(session_action_data.search_params.with_strong_access.permit(*permit_params))
      end
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
    permit_params = %w[ limit page ]
    pagination_params = params.permit(*permit_params).merge(override_pagination_params).select { |k,v| v.present? }
    # merge previous pagination if no current pagination
    if (options[:save] || options[:pull]) && pagination_params.blank?
      pagination_params.merge!(session_action_data.pagination_params.with_strong_access.permit(*permit_params))
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
    variable = "@session_action_data_for_#{namespace}"
    # return cached record
    return instance_variable_get(variable) if instance_variable_get(variable)
    session_id = promised_session.id
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

  def promised_session
    session[:init] = nil if session.id.nil?
    session
  end

end
