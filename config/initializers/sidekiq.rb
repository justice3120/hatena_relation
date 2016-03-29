Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Middleware::Server::RetryJobs, :max_retries => 0
  end
  case Rails.env
    when 'production' then
      config.redis = { url: ENV['REDIS_URL'], namespace: 'sidekiq' }
    when 'staging' then
      config.redis = { url: ENV['REDIS_URL'], namespace: 'sidekiq' }
    else
      config.redis = { url: 'redis://127.0.0.1:6379', namespace: 'sidekiq' }
  end
end

Sidekiq.configure_client do |config|
  case Rails.env
    when 'production' then
      config.redis = { url: ENV['REDIS_URL'], namespace: 'sidekiq' }
    when 'staging' then
      config.redis = { url: ENV['REDIS_URL'], namespace: 'sidekiq' }
    else
      config.redis = { url: 'redis://127.0.0.1:6379', namespace: 'sidekiq' }
  end
end
