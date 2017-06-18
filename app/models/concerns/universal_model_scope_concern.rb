module UniversalModelScopeConcern
  extend ActiveSupport::Concern

  included do
    # error class used in generate_permitted_identity_scopes
    permitted_identity_permission_error_class = Class.new(ArgumentError) do
      def initialize(identity, permission)
        super("unknown where_permitted_for_identity #{identity.class} permission: #{permission}")
      end
    end
    const_set("PermittedIdentityPermissionError", permitted_identity_permission_error_class)
  end


  module ClassMethods
    def generate_column_scopes(columns = column_names)
      columns = Array(columns).map(&:to_s)
      columns.each { |column| generate_where_scope column }
      columns.each { |column| generate_select_scope column }
      columns.each { |column| generate_order_scope column }
      generate_universal_scopes
    end

    def generate_universal_scopes
      scope :order_random, -> { order("RANDOM()") }
      scope :order_as_integer, -> (column, direction = :asc, null_order = nil) do
        direction = direction.to_s =~ /desc/i ? "DESC" : "ASC"
        null_order = null_order.to_s =~ /first/i ? "FIRST" : "LAST"
        order %Q[NULLIF(regexp_replace("#{table_name}"."#{column}", E'\\\\D', '', 'g'), '')::int #{direction} NULLS #{null_order}]
      end
    end

    def generate_where_scope(column)
      column = columns.find { |c| c if c.name == column.to_s }
      scope "where_#{column.name}", -> (params = {}) do
        break if params.blank?
        arel_column = arel_table[column.name]
        query = all
        params.each do |operator, value|
          operator = operator.to_s
          value = modify_operator_value(operator, value, column: column.name)
          if value.is_a?(ActiveRecord::Relation)
            # arel.to_sql does not substitute bind paramaters so a sql string is built manually
            where_sql = arel_column.send(operator, 1234567890).to_sql.gsub(/'?1234567890'?/, value.to_sql)
            query = query.where(where_sql)
          else
            arel_sql = -> (column_operator, column_value) { arel_column.send(column_operator, column_value).to_sql }
            case operator.presence
            when *%w[ in not_in ]
              has_nil_value = nil.in?(value)
              value -= [nil]
              if column.null == false || (operator == "in" && !has_nil_value)
                # IN value / NOT IN value
                query = query.where(arel_sql.call(operator, value))
              elsif (operator == "in" && has_nil_value) || (operator == "not_in" && !has_nil_value)
                # IN value OR IS NULL / NOT IN value AND IS NOT NULL
                query = query.where_or("#{column.name}_eq" => nil) { where(arel_sql.call(operator, value)) }
              elsif operator == "not_in" && has_nil_value
                # NOT IN value AND IS NOT NULL
                query = query.where(arel_sql.call(operator, value)).where(arel_sql.call(:not_eq, nil))
              else
                # should never be hit since all cases are handled above
                raise ArgumentError, "where_#{column.name}(#{operator} => #{value}) case has not been handled - contact griffith"
              end
            when *%w[ ieq not_ieq ]
              operator = operator.gsub("ieq", "eq")
              if value.nil?
                query = query.where(arel_sql.call(operator, value))
              else
                query = query.where(arel_column.lower.send(operator, arel_table.lower(value)).to_sql)
              end
            when *%w[ lt gt lteq gteq ]
              raise ArgumentError, "nil value passed to #{operator}" if value.nil?
              query = query.where(arel_sql.call(operator, value))
            when *%w[ matches does_not_match ]
              if value.nil?
                query = query.where("1=0") if operator == "does_not_match"
              else
                query = query.where(arel_sql.call(operator, value))
              end
            when nil
              raise ArgumentError, "no operator provided to where_#{column.name} query (value=#{value.inspect})"
            else
              query = query.where(arel_sql.call(operator, value))
            end
          end
        end
        query
      end
    end

    def generate_select_scope(column)
      scope "select_#{column}", -> { select(column) }
    end

    def generate_order_scope(column)
      # add order
      scope "order_#{column}", -> (direction = "asc", null_order = nil) do
        direction = direction.to_s =~ /desc/i ? :desc : :asc
        null_order = null_order.blank? || null_order.to_s !~ /first/i ? "LAST" : "FIRST"
        order(arel_table[column].send(direction).to_sql + " NULLS #{null_order}")
      end
      # override all previous orders
      scope "reorder_#{column}", -> (direction = "asc", null_order = nil) do
        direction = direction.to_s =~ /desc/i ? :desc : :asc
        null_order = null_order.blank? || null_order.to_s !~ /first/i ? "LAST" : "FIRST"
        reorder(arel_table[column].send(direction).to_sql + " NULLS #{null_order}")
      end
    end

    # order matters
    def split_column_and_operator(column_and_operator, options = {})
      options = options.with_indifferent_access
      column_and_operator = column_and_operator.to_s
      operators = {
        does_not_match: /_does_not_match\z/,
        matches: /_matches\z/,
        reorder: /\Areorder_/,
        order: /\Aorder_/,
        not_in: /_not_in\z/,
        not_ieq: /_not_ieq\z/,
        not_eq: /_not_eq\z/,
        lteq: /_lteq\z/,
        gteq: /_gteq\z/,
        in: /_in\z/,
        ieq: /_ieq\z/,
        eq: /_eq\z/,
        lt: /_lt\z/,
        gt: /_gt\z/,
      }.with_indifferent_access
      operator, operator_regex = operators.find { |operator, regex| column_and_operator =~ regex }
      if !operator || !operator_regex
        if options[:optional] != true
          raise ArgumentError, "unable to parse operator from #{column_and_operator.inspect} - Available: #{operators.keys}"
        else
          column_and_operator
        end
      else
        [column_and_operator.remove(operator_regex), operator]
      end
    end

    def modify_operator_value(operator, value, options = {})
      # ignore_blank_values removes blank values if possible otherwise returns nil
      options = options.with_indifferent_access.assert_valid_keys(*%w[ ignore_blank_values column ])
      operator = operator.to_s
      # force type casting
      type_cast_record =
        case value
        when ActiveRecord::Base then value
        when Array then value.find { |v| v.is_a?(ActiveRecord::Base) }
        end
      if type_cast_record
        raise ArgumentError, "query values must be type casted: #{operator} => #{type_cast_record.class}.#{options[:column] || :attribute}"
      end
      # modify value
      if value.is_a?(ActiveRecord::Relation)
        # check for valid subquery operator [in, not_in]
        raise ArgumentError, "operator [#{operator}] does not accept subqueries" if operator.not_in?(%w[ in not_in ])
        # select id if no selects
        value = value.arel.projections.first.try(:name) == "*" ? value.select_id : value
      else
        case operator
        when *%w[ order reorder ] then value =~ /desc/i ? "DESC" : "ASC"
        when *%w[ in not_in ]
          value = value.csv_to_a if value.is_a?(String)
          # skip empty arrays if ignoring blank values
          options[:ignore_blank_values] ? Array(value).select_present.presence : Array(value)
        when *%w[ matches does_not_match ]
          if value.blank?
            nil # always ignore blank values
          else
            # accept ^ and $ for start and end of match
            value =~ /\A%|%\z/ ? value : "%#{value}%".remove(/\A%\^|\$%\z/)
          end
        else options[:ignore_blank_values] ? value.presence : value
        end
      end
    end

    def where_or(seek_params = {}, &block)
      raise ArgumentError, "where_or expects a seek hash or block with an array of scopes" if !seek_params.is_a?(Hash)
      where_or_sql = []
      # simple helper for model column combinations
      seek_params.each do |column_and_operator, value|
        seek_where_sql = unscoped.seek(column_and_operator => value).to_where_sql
        where_or_sql << seek_where_sql if seek_where_sql.present?
      end
      # bind block to unscoped instance to prevent pollution of where statements
      if block
        block_queries = unscoped.instance_eval(&block)
        block_queries = [block_queries] if !block_queries.is_a?(Array)
        block_queries.compact.each do |block_query|
          block_query_where_sql = block_query.to_where_sql
          where_or_sql << "(#{block_query_where_sql})" if block_query_where_sql.present?
        end
      end
      # join where_or_sql with OR
      where(where_or_sql.join(" OR "))
    end

    def seek_or(*params, &block)
      where_or(*params, &block)
    end

    # batching
    def find_each_in_order(*params, &block)
      find_in_ordered_batches *params do |batch|
        batch.each(&block)
      end
    end

    def find_in_ordered_batches(options = {})
      options = options.with_indifferent_access
      batch_size = options[:batch_size] || 250
      raise ArgumentError, "batch_size must be greater than 0" if batch_size <= 0
      offset = options[:offset] || 0
      raise ArgumentError, "offset can not be negative" if offset < 0
      #batch_size = 0 if offset < 0
      # fallback order by id because records must have a definite order
      query = all.order_id(:desc)
      loop do
        current_batch = query.offset(offset).limit(batch_size)
        current_batch_size = current_batch.size
        break if current_batch_size == 0
        yield current_batch
        offset += current_batch_size
      end
      offset
    end

    # seek usage: seed(column_operator => value, "association.column_operator" => value)
    def seek(seek_params = {}, global_options = {})
      query = all
      seeks = {}.with_indifferent_access
      seek_params = seek_params.with_indifferent_access
      # global options
      global_options = global_options.with_indifferent_access.assert_valid_keys(*%w[ namespace defaults ignore_blank_values ])
      global_namespace = global_options[:namespace].to_s.presence
      seek_defaults = (global_options[:defaults] || {}).with_indifferent_access
      # modify seek hashes
      [seek_params, seek_defaults].each do |seek_hash|
        # standardize keys
        seek_hash.transform_keys! do |original_namespace|
          # whitelist namespace
          original_namespace = original_namespace.remove(/[^A-Z0-9a-z_.]/)
          # auto prepend table_name if no namespace provided
          original_namespace = "#{table_name}.#{original_namespace}" if !original_namespace.include?(".")
          original_namespace
        end
        # optional removal of blank values
        if global_options[:ignore_blank_values]
          # Array handled later after adjustment
          seek_hash.delete_if do |original_namespace, original_value|
            original_value.nil? || (original_value.is_a?(String) && original_value.blank?)
          end
        end
      end
      # append seek_defaults to seek_params
      seek_defaults.each do |original_namespace, original_value|
        seek_params[original_namespace] ||= original_value
      end
      # build seeks from format: without_unscoped_association.column_operator => original_value
      seek_params.each do |original_namespace, original_value|
        begin
          namespace, column_and_operator = original_namespace.split(".")
          association = namespace.dup
          # parse options [isolate, without]
          option_regex = /\Awithout_/
          option_without = association =~ option_regex ? true : false
          association.remove!(option_regex)
          option_regex = /\Aunscoped_/
          option_isolate = association =~ option_regex ? true : false
          association.remove!(option_regex)
          # parse column and operator
          column, operator = split_column_and_operator(column_and_operator, optional: true)
          # parse value
          requires_type_casting = original_value.is_a?(ActiveRecord::Base)
          requires_type_casting ||= original_value.is_a?(Array) && original_value.find { |v| v.is_a?(ActiveRecord::Base) }
          raise ArgumentError, "seek values must be type casted" if requires_type_casting
          value = modify_operator_value(operator, original_value, ignore_blank_values: global_options[:ignore_blank_values], column: column)
          next if value.nil? && global_options[:ignore_blank_values]
          # build seek scope
          seeks[namespace] ||= { association: association, isolate: option_isolate, without: option_without, queries: [] }
          seek_namespace = seeks[namespace]
          store_seek = -> (new_seek_query) do
            (seek_namespace[:isolate] ? seek_namespace[:queries] : seek_namespace[:queries].clear) << new_seek_query
          end
          seek_model =
            if association == table_name
              association.classify.constantize
            else
              reflection = reflect_on_association(association)
              if !reflection
                raise ArgumentError, "seek could not find reflection for #{association.inspect} association - #{original_namespace} => #{original_value}"
              end
              reflection.klass
            end
          seek_query = seek_namespace[:isolate] ? seek_model.unscoped : (seek_namespace[:queries].first || seek_model.unscoped)
          # order by columns on model only otherwise ignore
          if operator.in?(%w[ order reorder ])
            if seek_query.table_name == query.table_name && seek_query.respond_to?("#{operator}_#{column}")
              next store_seek.call(seek_query.send("#{operator}_#{column}", value))
            else
              Rails.env.production? ? next : raise(ArgumentError, "invalid sort seek: #{original_namespace} => #{original_value}")
            end
          # custom seek scope on query
          elsif query.respond_to?("seek_#{original_namespace.slugify}")
            next store_seek.call(query.send("seek_#{original_namespace.slugify}", value))
          # custom namespace scope
          elsif global_namespace && seek_query.respond_to?("#{global_namespace}_#{column_and_operator}")
            next store_seek.call(seek_query.send("#{global_namespace}_#{column_and_operator}", value))
          # custom seek scope
          elsif seek_query.respond_to?("seek_#{column_and_operator}")
            next store_seek.call(seek_query.send("seek_#{column_and_operator}", value))
          # auto seek
          elsif seek_query.respond_to?("where_#{column}")
            if operator.blank?
              raise ArgumentError, "no operator provided for #{global_namespace || :seek} query: #{original_namespace} => #{original_value}"
            end
            next store_seek.call(seek_query.send("where_#{column}", operator => value))
          end
          raise ArgumentError, "unknown #{global_namespace || :seek}: #{original_namespace} => #{original_value}"
        rescue StandardError => error
          subject = "#{(global_namespace || "seek").classify}Error [#{error.class}]: #{error.message}"
          body = "
            Seek Params: #{seek_params}
            Seek Options: #{global_options}
            Error: #{error.message}
            Backtrace:
            #{error.backtrace.join("\n")}
          ".to_multiline_s
          if Rails.env.production?
            StaticMailer.email(to: :developers, subject: subject, body: body).deliver_now
          else
            raise error
          end
        end
      end
      # perform seeks on query
      seeks.each do |namespace, seek_options|
        association = seek_options[:association]
        seek_queries = seek_options.delete(:queries)
        seek_operator = seek_options[:without] ? :not_in : :in
        seek_queries.each do |seek_query|
          # non-association seek
          if seek_query.table_name == query.table_name
            # IN: merge where scope into current query / NOT IN: perform NOT IN self query
            query = seek_operator == :in ? query.where_merge(seek_query) : where_id(seek_operator => seek_query)
          # custom association seek
          elsif respond_to?("seek_#{association}")
            query = query.send("seek_#{association}", seek_operator, seek_query)
          # association seek
          else
            query = query.merge_association_query(association, seek_query, operator: seek_operator)
          end
        end
      end
      # result
      query
    end

    def to_where_sql
      reorder(nil).to_sql[/ WHERE (.*)/i, 1].presence
    end

    def where_merge(other_query)
      query = all
      # verify same table
      if query.klass != other_query.klass
        raise ArgumentError, "where_merge queries must be for same class: #{query.klass} != #{other_query.klass}"
      end
      # pull WHERE sql
      query.where(other_query.to_where_sql)
    end

    # search calls seek and also handles sorting
    def search(search_params, search_defaults = {})
      search_params = search_params.with_indifferent_access
      search_defaults = search_defaults.with_indifferent_access
      sort_column, sort_direction = nil
      # support sorting params (Ex: sort=column&direction=desc)
      [search_defaults, search_params].each do |hash|
        new_sort_direction = hash.delete(:direction) =~ /desc/i ? "DESC" : "ASC"
        new_sort_column = hash.delete(:sort).to_s.split(".").last
        if new_sort_column
          sort_column, sort_direction = new_sort_column, new_sort_direction
        end
      end
      # seek
      query = seek(search_params, defaults: search_defaults, namespace: :search, ignore_blank_values: true)
      # sorting
      if sort_column
        if query.respond_to?("reorder_#{sort_column}")
          query = query.send("reorder_#{sort_column}", sort_direction)
        else
          begin
            raise ArgumentError, "unknown search sorting - sort=#{sort_column} direction=#{sort_direction}"
          rescue ArgumentError => error
            subject = "SearchError [#{error.message}]: #{error.message}"
            body = "
              Search Params: #{search_params}
              Search Defaults: #{search_defaults}
              Error: #{error.message}
              Backtrace:
              #{error.backtrace.join("\n")}
            ".to_multiline_s
            StaticMailer.email(to: :developers, subject: subject, body: body).deliver_now
            raise error if !Rails.env.production?
          end
        end
      end
      query
    end

    # merge association subquery into current query
    # acheived by building association jumps between association_query and current query
    # example: Member.merge_asssociation_query(:groups, Group.where_name(matches: "golf"))
    # example debug:
    # Group => Member
    # jump through MemberGroup.group
    # jump base Member.member_groups
    # MemberGroup.where_group_id(in: Group.select_id)
    # Member.where_id(in: MemberGroup.select_member_id)
    def merge_association_query(association, association_query, options = {})
      options = options.with_indifferent_access.reverse_merge(operator: :in, debug: false)
      # debug available for viewing jumps
      debug = -> (message) { puts message if options[:debug] }
      query = all
      association_reflection = query.reflect_on_association(association)
      raise ArgumentError, "unknown #{query.klass} association: #{association}" if !association_reflection
      debug.call("#{association_query.klass} => #{query.klass}")
      # final list of jumps containing model and association
      jumps = []
      add_jump = -> (klass, association) { jumps.push({ model: klass, association: association }.to_struct) }
      jump_builder = -> (ref) do
        # used to protect against infinite loop
        association = ref.source_reflection.name
        through_ref = ref.through_reflection
        if through_ref
          throughception = through_ref.klass.reflect_on_association(association)
          # check for throughception (jump through another association)
          # normal example:
          #   GroupProperty.has_many(:member_groups, through: :group)
          #   GroupProperty.has_many(:members, through: :member_groups)
          # throughception example:
          #   GroupProperty.has_many(:members, through: :group)
          if throughception && throughception.through_reflection
            debug.call("jump throughception #{ref.active_record}.#{association}")
            jump_builder.call(throughception) # add all throughception jumps
            jump_builder.call(through_ref) # continue
          else
            debug.call("jump through #{through_ref.klass}.#{association}")
            add_jump.call(through_ref.klass, association)
            jump_builder.call(through_ref)
          end
        else
          debug.call("jump base #{ref.active_record}.#{ref.name}")
          add_jump.call(ref.active_record, ref.name)
        end
      end
      jump_builder.call(association_reflection)
      # build subqueries using jumps
      jumps.each_with_index do |jump, i|
        jump_ref = jump.model.reflect_on_association(jump.association)
        primary_key, foreign_key = jump_ref.active_record_primary_key, jump_ref.foreign_key
        # belongs_to means foreign key is actually the primary key
        primary_key, foreign_key = [foreign_key, primary_key] if jump_ref.macro == :belongs_to
        # use provided operator for final jump which allows for not_in queries
        operator = i + 1 == jumps.size ? options[:operator] : :in
        debug.call("#{jump.model}.where_#{primary_key}(#{operator}: #{association_query.klass}.select_#{foreign_key})")
        # must call model.unscoped to remove existing scope queries
        association_query = jump.model.unscoped.send("where_#{primary_key}", operator => association_query.send("select_#{foreign_key}"))
      end
      # merge result into query
      query.where_merge(association_query)
    end

    def paginate(params = {})
      Paginate.new(self.all).paginate(params)
    end
  end

  class Paginate
    attr_reader :query, :records
    attr_reader :page, :pages, :raw_count, :next_page, :previous_page
    attr_reader :limit, :offset

    def initialize(query)
      # query must have a definite order
      @query = query.order_id(:desc)
    end

    def paginate(params = {})
      params = params.with_indifferent_access
      max = params[:max].to_i > 0 ? params[:max].to_i : 30
      min = params[:min].to_i > 0 && params[:min].to_i < max ? params[:min].to_i : 1
      @raw_count = @query.count(:id)
      @limit = params[:limit].to_i.between?(min,max) ? params[:limit].to_i : 15
      @limit = 1 if @limit < 1
      @pages = (@raw_count.to_f / @limit).ceil.to_i
      @pages = 1 if @pages < 1
      @page = params[:page].blank? ? 1 : params[:page].to_i
      @page = @pages if @page > @pages
      @page = 1 if @page < 1
      @next_page = @page < @pages ? @page + 1 : @pages
      @previous_page = @page > 1 ? @page - 1 : 1
      @offset = (@page - 1) * @limit
      @records = Array(@query.offset(@offset).limit(@limit))
      self
    end

    alias_method :current_page, :page

    def each_page(*params, &block)
      Array(1..pages).each(*params, &block)
    end

    def has_previous_page?
      current_page > 1
    end

    def has_next_page?
      current_page < pages
    end

    def method_missing(method, *params, &block)
      records.send(method, *params, &block)
    end
  end
end
