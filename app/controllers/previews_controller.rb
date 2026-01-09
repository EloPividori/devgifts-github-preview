class PreviewsController < ApplicationController
  def create
    github_username = params[:github_username]
    shirt_size = params[:shirt_size] || "M"
    shirt_color = params[:shirt_color] || "white"

    if github_username.blank?
      render json: { error: "github_username is required" }, status: :bad_request
      return
    end

    preview_url = PreviewService.generate_preview(github_username, shirt_size, shirt_color)

    if preview_url
      render json: { preview_url: preview_url }, status: :ok
    else
      render json: { error: "Failed to generate preview" }, status: :internal_server_error
    end
  end

  def health
    render json: { status: "ok" }, status: :ok
  end
end
