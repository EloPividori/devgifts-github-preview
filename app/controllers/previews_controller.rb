class PreviewsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def health
    render json: { ok: true }
  end

  def create
    username = params[:username].to_s.strip
    custom_text = params[:customText].to_s.strip
    period = params[:period].to_s.strip

    if username.empty?
      return render json: { error: "username required" }, status: 422
    end

    # Date range selection
    today = Date.today
    from_date, to_date =
      case period
      when "year"
        year = params[:year].to_i
        return render json: { error: "year required" }, status: 422 if year <= 0
        [Date.new(year, 1, 1), Date.new(year, 12, 31)]
      when "custom_range"
        from = params[:from].to_s
        to = params[:to].to_s
        return render json: { error: "from/to required" }, status: 422 if from.empty? || to.empty?
        [Date.parse(from), Date.parse(to)]
      else
        # last_12_months (default)
        [today - 365, today]
      end

    # Fetch real GitHub contribution calendar (weeks/days with counts)
    calendar = GithubContributions.fetch_calendar!(
      username: username,
      from_date: from_date,
      to_date: to_date
    )

    # Render PNG (transparent background)
    text_to_use = custom_text.empty? ? "Push it real good" : custom_text
    png = GithubPngRenderer.render(calendar: calendar, text: text_to_use)

    base64 = Base64.strict_encode64(png)
    render json: { imageDataUrl: "data:image/png;base64,#{base64}" }
  rescue GithubContributions::NotFound
    render json: { error: "GitHub user not found" }, status: 404
  rescue StandardError => e
    render json: { error: "preview_failed", details: e.message }, status: 500
  end
end
