module Services
  class AddressBook
    # regarding these methods' parameters or options, generally:
    #
    #  * `sender` is a User or a user ID
    #  * `context` is an asset string ('course_123', or optionally subscoped
    #    such as 'course_123_teachers') or a Course, CourseSection, or Group
    #  * `users` is a list of Users or user IDs
    #  * `search` is a string
    #  * `exclude` is a list of Users or of user IDs
    #  * `weak_checks` is a truthy/falsey value
    #

    # which of the users does the sender know, and what contexts do they and
    # the sender have in common?
    def self.common_contexts(sender, users)
      recipients(sender: sender, user_ids: users)
    end

    # which of the users have roles in the context and what are those roles?
    def self.roles_in_context(context, users)
      context = context.course if context.is_a?(CourseSection)
      recipients(context: context, user_ids: users)
    end

    # which users:
    #
    #  - does the sender know in the context and what are their roles in that
    #    context? (is_admin=false)
    #
    #      --OR--
    #
    #  - have roles in the context and what are those roles? (is_admin=true)
    #
    def self.known_in_context(sender, context, is_admin=false)
      if is_admin
        recipients(context: context)
      else
        recipients(sender: sender, context: context)
      end
    end

    # how many users does the sender know in the context?
    def self.count_in_context(sender, context)
      count_recipients(sender: sender, context: context)
    end

    # of the users who are not in `exclude_ids` and whose name matches the
    # `search` term, if any, which:
    #
    #  - does the sender know, and what are their common contexts with the
    #    sender? (no context provided)
    #
    #  - does the sender know in the context and what are their roles in that
    #    context? (context provided but not is_admin)
    #
    #      --OR--
    #
    #  - have roles in the context and what are those roles? (context provided
    #    and is_admin true)
    #
    def self.search_users(sender, options, service_options={})
      # [CNVS-31303] TODO
      #  - send pagination as specified in service_options
      #  - pass back pagination info from service call instead of just always true
      params = options.slice(:search, :context, :exclude_ids, :weak_checks)
      # include sender only if not admin
      params.merge!(sender: sender) unless options[:context] && options[:is_admin]
      # second return value indicates whether there are more pages of results
      [recipients(params), true]
    end

    def self.recipients(params)
      reshape(fetch("/recipients", query_params(params)))
    end

    def self.count_recipients(params)
      fetch("/recipients/count", query_params(params))['count'] || 0
    end

    def self.jwt # public only for testing, should not be used directly
      Canvas::Security.create_jwt({ iat: Time.now.to_i }, nil, jwt_secret)
    rescue StandardError => e
      Canvas::Errors.capture_exception(:address_book, e)
      nil
    end

    class << self
      private
      def setting(key)
        settings = Canvas::DynamicSettings.from_cache("address-book", expires_in: 5.minutes)
        settings[key]
      rescue Faraday::ConnectionFailed,
             Faraday::ClientError,
             Canvas::DynamicSettings::ConsulError => e
        Canvas::Errors.capture_exception(:address_book, e)
        nil
      end

      def app_host
        setting("app-host")
      end

      def jwt_secret
        Canvas::Security.base64_decode(setting("secret"))
      end

      # generic retrieve, parse
      def fetch(path, params={})
        url = app_host + path
        url += '?' + params.to_query unless params.empty?
        Canvas.timeout_protection("address_book") do
          response = CanvasHttp.get(url, 'Authorization' => "Bearer #{jwt}")
          if response.code.to_i == 200
            return JSON.parse(response.body)
          else
            Canvas::Errors.capture(CanvasHttp::InvalidResponseCodeError.new(response.code.to_i), {
              extra: { url: url, response: response.body },
              tags: { type: 'address_book_fault' }
            })
            return {}
          end
        end || {}
      end

      # serialize logical params into query string values
      def query_params(params={})
        query_params = {}
        query_params[:search] = params[:search] if params[:search]
        query_params[:for_sender] = serialize_user(params[:sender]) if params[:sender]
        query_params[:in_context] = serialize_context(params[:context]) if params[:context]
        query_params[:user_ids] = serialize_users(params[:user_ids]) if params[:user_ids]
        query_params[:exclude_ids] = serialize_users(params[:exclude_ids]) if params[:exclude_ids]
        query_params[:weak_checks] = 1 if params[:weak_checks]
        query_params
      end

      def serialize_user(user)
        Shard.global_id_for(user)
      end

      def serialize_users(users)
        users.map{ |user| serialize_user(user) }.join(',')
      end

      def serialize_context(context)
        if context.respond_to?(:global_asset_string)
          context.global_asset_string
        else
          context_type, context_id, scope = context.split('_', 3)
          global_context_id = Shard.global_id_for(context_id)
          asset_string = "#{context_type}_#{global_context_id}"
          asset_string += "_#{scope}" if scope
          asset_string
        end
      end

      # /recipients returns data in the (JSON) shape:
      #
      #   {
      #     '10000000000002': [
      #       { 'context_type': 'course', 'context_id': '10000000000001', 'roles': ['TeacherEnrollment'] }
      #     ],
      #     '10000000000005': [
      #       { 'context_type': 'course', 'context_id': '10000000000002', 'roles': ['StudentEnrollment'] },
      #       { 'context_type': 'group', 'context_id': '10000000000001', 'roles': ['Member'] }
      #     ]
      #   }
      #
      # where top-level keys are string representations of the recipient global
      # user IDs, and values are the list of contexts they have in common with
      # the sender. each context states the type, id (again as a string
      # representation of the global ID), and roles the recipient has in that
      # context (to the knowledge of the sender).
      #
      # the return from the service methods need to reshape that response into
      # a similar ruby hash, but with integers instead of strings for IDs (but
      # still global), and context types collated. this matches the
      # expectations of existing code that uses the common context information.
      # e.g. for the above example, the transformed data would have the (ruby)
      # shape:
      #
      #   {
      #     10000000000002 => {
      #       courses: { 10000000000001 => ['TeacherEnrollment'] },
      #       groups: {}
      #     },
      #     10000000000005 => {
      #       courses: { 10000000000002 => ['StudentEnrollment'] },
      #       groups: { 10000000000001 => ['Member'] }
      #     }
      #   }
      #
      def reshape(data)
        common_contexts = {}
        data.each do |global_user_id,contexts|
          global_user_id = global_user_id.to_i
          common_contexts[global_user_id] ||= { courses: {}, groups: {} }
          contexts.each do |context|
            context_type = context['context_type'].pluralize.to_sym
            global_context_id = context['context_id'].to_i
            common_contexts[global_user_id][context_type][global_context_id] = context['roles']
          end
        end
        common_contexts
      end
    end
  end
end
