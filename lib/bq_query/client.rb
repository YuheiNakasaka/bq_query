module BqQuery
  class Client
    attr_accessor :dataset, :project_id

    def initialize(opts)
      @client = ::Google::Apis::BigqueryV2::BigqueryService.new

      @client.client_options.application_name = 'BigQuery ruby app'
      @client.client_options.application_version = BqQuery::VERSION

      scope = 'https://www.googleapis.com/auth/bigquery'
      if opts['json_key'].is_a?(String) && !opts['json_key'].empty?
        if File.exist?(opts['json_key'])
          auth = File.open(opts['json_key']) do |f|
            ::Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: f, scope: scope)
          end
        else
          key = StringIO.new(opts['json_key'])
          auth = ::Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: key, scope: scope)
        end
      else
        begin
          key = ::Google::APIClient::KeyUtils.load_from_pkcs12(opts['key'], 'notasecret')
        rescue ArgumentError
          key = ::Google::APIClient::KeyUtils.load_from_pem(opts['key'], 'notasecret')
        end
        auth = Signet::OAuth2::Client.new(
            token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
            audience: 'https://accounts.google.com/o/oauth2/token',
            scope: scope,
            issuer: opts['service_email'],
            signing_key: key)
      end

      @client.authorization = auth

      refresh_auth

      @project_id = opts['project_id']
      @dataset = opts['dataset']
    end

    def refresh_auth
      @client.authorization.fetch_access_token!
    end

    def sql(given_query, options={})
      query_request = ::Google::Apis::BigqueryV2::QueryRequest.new(
        query: given_query,
      )
      query_request.timeout_ms       = options[:timeout] || options[:timeoutMs] || 90 * 1000
      query_request.max_results      = options[:maxResults] if options[:maxResults]
      query_request.dry_run          = options[:dryRun] if options.has_key?(:dryRun)
      query_request.use_query_cache  = options[:useQueryCache] if options.has_key?(:useQueryCache)

      api(
        @client.query_job(
          @project_id,
          query_request
        )
      )
    end

    private

    def api(resp)
      data = deep_stringify_keys(resp.to_h)
      handle_error(data) if data && is_error?(data)
      arrange_records(data)
    end

    def deep_stringify_keys(response)
      convert_key_proc = Proc.new { |k| camel_case_lower(k.to_s) }
      Hash[response.map { |k, v| [convert_key_proc.call(k), process_value(v, convert_key_proc)] }]
    end

    def camel_case_lower(str)
      str.split('_').inject([]){ |buffer,e| buffer.push(buffer.empty? ? e : e.capitalize) }.join
    end

    def process_value(val, convert_key_proc)
      case val
      when Hash
        Hash[val.map {|k, v| [convert_key_proc.call(k), process_value(v, convert_key_proc)] }]
      when Array
        val.map{ |v| process_value(v, convert_key_proc) }
      else
        val
      end
    end

    def arrange_records(response)
      keys = column_names(response)
      types = column_types(response)
      records = extract_records(response)
      records.map do |record|
        vals = record.map.with_index do |v, index|
          Attribute.new(value: v, type: types[index]).parse
        end
        [keys, vals].transpose.to_h
      end
    end

    def column_names(response)
      response['schema']['fields'].map {|field| field['name'] }
    end

    def column_types(response)
      response['schema']['fields'].map {|field| field['type'] }
    end

    def extract_records(response)
      (response['rows'] || []).map {|row| row['f'].map {|record| record['v'] } }
    end

    def is_error?(response)
      !response["error"].nil?
    end

    def handle_error(response)
      error = response['error']
      case error['code']
      when 404
        fail BigQuery::Errors::NotFound, error['message']
      else
        fail BigQuery::Errors::BigQueryError, error['message']
      end
    end
  end
end
