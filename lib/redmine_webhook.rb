unless Rails.try(:autoloaders).try(:zeitwerk_enabled?)
  require File.dirname(__FILE__) + '/redmine_webhook/projects_helper_patch.rb'
  require File.dirname(__FILE__) + '/redmine_webhook/issue_wrapper.rb'
  require File.dirname(__FILE__) + '/redmine_webhook/webhook_listener.rb'
end

module RedmineWebhook
end
