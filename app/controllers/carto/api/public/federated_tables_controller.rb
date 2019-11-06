module Carto
  module Api
    module Public
      class FederatedTablesController < Carto::Api::Public::ApplicationController
        include Carto::Api::PagedSearcher
        include Carto::ControllerHelper
        extend Carto::DefaultRescueFroms

        VALID_ORDER_PARAMS_FEDERATED_SERVER = %i(federated_server_name).freeze
        VALID_ORDER_PARAMS_REMOTE_SCHEMA = %i(remote_schema_name).freeze
        VALID_ORDER_PARAMS_REMOTE_TABLE = %i(remote_table_name).freeze

        FEDERATED_SERVER_ATTRIBUTES = %i(federated_server_name mode dbname host port username password).freeze
        REMOTE_TABLE_ATTRIBUTES = %i(federated_server_name remote_schema_name remote_table_name local_table_name_override id_column_name geom_column_name webmercator_column_name).freeze

        before_action :load_user
        before_action :load_service
        before_action only: [:list_federated_servers] do
          load_pagination_params(default_order: 'federated_server_name', valid_order_params: VALID_ORDER_PARAMS_FEDERATED_SERVER)
        end
        before_action only: [:list_remote_schemas] do
          load_pagination_params(default_order: 'remote_schema_name', valid_order_params: VALID_ORDER_PARAMS_REMOTE_SCHEMA)
        end
        before_action only: [:list_remote_tables] do
          load_pagination_params(default_order: 'remote_table_name', valid_order_params: VALID_ORDER_PARAMS_REMOTE_TABLE)
        end
        before_action :check_permissions
        before_action :load_federated_server_attributes, only: [:register_federated_server, :update_federated_server ]
        before_action :load_federated_server, only: [:update_federated_server, :unregister_federated_server, :show_federated_server]
        before_action :check_federated_server, only: [:unregister_federated_server, :show_federated_server]
        before_action :check_federated_server_attributes, only: [:register_federated_server, :update_federated_server]
        before_action :load_remote_table_attributes, only: [:register_remote_table, :update_remote_table ]
        before_action :load_remote_table, only: [:update_remote_table, :unregister_remote_table, :show_remote_table]
        before_action :check_remote_table, only: [:unregister_remote_table, :show_remote_table]
        before_action :check_remote_table_attributes, only: [:register_remote_table, :update_remote_table]

        setup_default_rescues

        # Federated Servers

        def list_federated_servers
          result = @service.list_servers(@pagination)
          total = @service.count_servers()

          render_paged(result, total)
        end

        def register_federated_server
          federated_server = @service.register_server(@federated_server_attributes)
          response.headers['Content-Location'] = "#{request.path}/#{federated_server[:federated_server_name]}"
          render_jsonp({}, 201)
        end

        def show_federated_server
          @federated_server[:password] = '********'
          render_jsonp(@federated_server, 200)
        end

        def update_federated_server
          unless @federated_server
            @federated_server = @service.register_server(@federated_server_attributes)
            response.headers['Content-Location'] = "#{request.path}"
            return render_jsonp({}, 201)
          end

          @federated_server = @service.update_server(@federated_server_attributes)
          render_jsonp({}, 204)
        end

        def unregister_federated_server
          @service.unregister_server(federated_server_name: params[:federated_server_name])
          render_jsonp({}, 204)
        end

        # Remote Schemas

        def list_remote_schemas
          result = @service.list_remote_schemas(params[:federated_server_name], @pagination)
          total = @service.count_remote_schemas(params[:federated_server_name])
          render_paged(result, total)
        end

        # Remote Tables

        def list_remote_tables
          result = @service.list_remote_tables(params[:federated_server_name], params[:remote_schema_name], @pagination)
          total = @service.count_remote_tables(params[:federated_server_name], params[:remote_schema_name])
          render_paged(result, total)
        end

        def register_remote_table
          remote_table = @service.register_table(@remote_table_attributes)
          response.headers['Content-Location'] = "#{request.path}/#{remote_table[:remote_table_name]}"
          render_jsonp({}, 201)
        end

        def show_remote_table
          render_jsonp(@remote_table, 200)
        end

        def update_remote_table
          unless @remote_table
            @remote_table = @service.register_table(@remote_table_attributes)
            response.headers['Content-Location'] = "#{request.path}"
            return render_jsonp({}, 201)
          end

          @remote_table = @service.update_table(@remote_table_attributes)

          render_jsonp({}, 204)
        end

        def unregister_remote_table
          @service.unregister_table(
            federated_server_name: params[:federated_server_name],
            remote_schema_name: params[:remote_schema_name],
            remote_table_name: params[:remote_table_name]
          )
          render_jsonp({}, 204)
        end

        private

        def load_user
          @user = ::User.where(id: current_viewer.id).first
        end

        def load_service
          @service = Carto::FederatedTablesService.new(user: @user)
        end

        def load_pagination_params(default_order:, valid_order_params:)
          page, per_page, order, direction = page_per_page_order_params(
            valid_order_params,
            default_order: default_order,
            default_order_direction: 'asc'
          )
          @pagination = { page: page, per_page: per_page, order: order, direction: direction }
        end

        def load_federated_server_attributes
          @federated_server_attributes = params.slice(*FEDERATED_SERVER_ATTRIBUTES)
        end

        def load_federated_server
          @federated_server = @service.get_server(federated_server_name: params[:federated_server_name])
        end

        def check_federated_server
          raise Carto::LoadError.new("Federated server key not found: #{params[:federated_server_name]}") unless @federated_server
        end

        def check_federated_server_attributes
          if request.post?
            raise Carto::CartoError.new("Missing 'federated server name' attribute", 422) unless params[:federated_server_name].present?
          end
          raise Carto::CartoError.new("Missing 'mode' attribute", 422) unless params[:mode].present?
          raise Carto::CartoError.new("Missing 'database name' attribute", 422) unless params[:dbname].present?
          raise Carto::CartoError.new("Missing 'host' attribute", 422) unless params[:host].present?
          raise Carto::CartoError.new("Missing 'port' attribute", 422) unless params[:port].present?
          raise Carto::CartoError.new("Missing 'username' attribute", 422) unless params[:username].present?
          raise Carto::CartoError.new("Missing 'password' attribute", 422) unless params[:password].present?
        end

        def load_remote_table_attributes
          @remote_table_attributes = params.slice(*REMOTE_TABLE_ATTRIBUTES)
          @remote_table_attributes[:local_table_name_override] ||= @remote_table_attributes[:remote_table_name]
        end

        def load_remote_table
          @remote_table = @service.get_remote_table(
            federated_server_name: params[:federated_server_name],
            remote_schema_name: params[:remote_schema_name],
            remote_table_name: params[:remote_table_name]
          )
        end

        def check_remote_table
          raise Carto::LoadError.new("Remote table key not found: #{params[:federated_server_name]}/#{params[:remote_schema_name]}.#{params[:remote_table_name]}") unless @remote_table
        end

        def check_remote_table_attributes
          if request.post?
            raise Carto::CartoError.new("Missing 'remote table name' attribute", 422) unless params[:remote_table_name].present?
          end
          raise Carto::CartoError.new("Missing 'id column name' attribute", 422) unless params[:id_column_name].present?
        end

        def check_permissions
          api_key = Carto::ApiKey.find_by_token(params["api_key"])
          raise UnauthorizedError unless api_key.master? || api_key.dataset_metadata_permissions
        end

        def render_paged(result, total)
          enriched_response = paged_result(
            result: result,
            total_count: total,
            page: @pagination[:page],
            per_page: @pagination[:per_page],
            params: params.except('controller', 'action')
          ) { |params| api_v4_federated_servers_list_servers_url(params) }

          render_jsonp(enriched_response, 200)
        end
      end
    end
  end
end
