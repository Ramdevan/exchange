Pusher.app_id = ENV['PUSHER_APP']
Pusher.key    = ENV['PUSHER_KEY']
Pusher.secret = ENV['PUSHER_SECRET']
Pusher.host   = ENV['PUSHER_HOST']
Pusher.cluster= ENV['PUSHER_CLUSTER']
Pusher.port   = ENV['PUSHER_PORT'].present? ? ENV['PUSHER_PORT'].to_i : 80
# Pusher.encrypted = ENV['PUSHER_ENCRYPTED'].present?
# Pusher.port   = ENV['PUSHER_ENCRYPTED'] ? ENV['PUSHER_WSS_PORT'].to_i : ENV['PUSHER_WS_PORT'].to_i