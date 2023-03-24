defmodule SlackNotification do
  require HTTPoison
  require Logger

  def send_notification(message) do
    payload = %{text: message}
    slack_webhook_url = Application.get_env(:mllparty, :slack_webhook_url, false)
    if slack_webhook_url do
      Logger.info("Sending slack notification to #{slack_webhook_url} (Message: #{message})")
      HTTPoison.post(slack_webhook_url, Jason.encode!(payload), headers())
      |> handle_response()
    else
      Logger.warn("Environment variable slack_webhook_url is not set. Slack notification will not be sent (Message: #{message})")
    end
  end

  defp handle_response({:ok, %{body: body}}) do
    IO.puts("Slack notification sent: #{body}")
  end

  defp handle_response({:error, reason}) do
    IO.puts("Slack notification failed: #{reason}")
  end

  defp headers do
    [{"Content-Type", "application/json"}]
  end
end
