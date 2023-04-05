defmodule SlackNotification do
  require HTTPoison
  require Logger

  def send_notification(message) do
    missing_envs = []

    app_env = Application.get_env(:mllparty, :app_env)

    slack_webhook_url = Application.get_env(:mllparty, :slack_webhook_url, false)
    missing_envs = if slack_webhook_url == false, do: missing_envs ++ ["slack_webhook_url"], else: missing_envs

    slack_channel = Application.get_env(:mllparty, :slack_channel, false)
    missing_envs = if slack_channel == false, do: missing_envs ++ ["slack_channel"], else: missing_envs

    if length(missing_envs) == 0 do
      payload = %{
        text: message,
        channel: slack_channel,
        username: "MLLParty (#{app_env})",
        level: "alert"
      }
      json = Jason.encode!(payload)
      Logger.info("Sending slack notification to #{slack_webhook_url} (payload: #{json})")
      HTTPoison.post(slack_webhook_url, json, headers())
      |> handle_response()
    else
      Logger.warn("Environment variable is not set: #{Enum.join(missing_envs, ", ")}. Slack notification will not be sent (Message: #{message})")
    end
  end

  defp handle_response({:ok, %{body: body}}) do
    Logger.info("Slack notification sent: #{body}")
  end

  defp handle_response({:error, reason}) do
    Logger.info("Slack notification failed: #{reason}")
  end

  defp headers do
    [{"Content-Type", "application/json"}]
  end
end
