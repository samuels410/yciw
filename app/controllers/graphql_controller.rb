class GraphQLController < ApplicationController
  include Api::V1

  before_action :require_user, except: :execute
  before_action :require_graphql_feature_flag

  def execute
    query = params[:query]
    variables = params[:variables] || {}
    context = {
      current_user: @current_user,
      session: session,
      request: request,
    }

    ActiveRecord::Base.transaction do
      timeout = Integer(Setting.get('graphql_statement_timeout', '60_000'))
      ActiveRecord::Base.connection.execute "SET statement_timeout = #{timeout}"

      result = CanvasSchema.execute(query, variables: variables, context: context)
      render json: result
    end
  end

  def graphiql
    if Rails.env.production? &&
        !::Account.site_admin.grants_right?(@current_user, session, :read_as_admin)
       render plain: "unauthorized", status: :unauthorized
    else
      render :graphiql, layout: 'bare'
    end
  end

  private

  def require_graphql_feature_flag
    unless @domain_root_account.feature_enabled?("graphql")
      render plain: "not found", status: 404
    end
  end
end
