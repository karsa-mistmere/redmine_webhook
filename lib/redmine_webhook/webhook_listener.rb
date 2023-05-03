module RedmineWebhook
  class WebhookListener < Redmine::Hook::Listener

    def skip_webhooks(context)
      return true unless context[:request]
      return true if context[:request].headers['X-Skip-Webhooks']

      false
    end

    def get_parent_webhooks(project)
      return unless project.parent
      t = Webhook.table_name
      webhooks = Webhook.where("#{t}.project_id = ? AND #{t}.subprojects = ?", project.parent.id, true)
      webhooks = get_parent_webhooks(project.parent) unless webhooks && webhooks.length > 0
      webhooks
    end

    def get_webhooks(project)
      webhooks = Webhook.where(:project_id => project[:id])
      webhooks = get_parent_webhooks(project) unless webhooks && webhooks.length > 0
      webhooks = Webhook.where(:project_id => 0) unless webhooks && webhooks.length > 0
      webhooks
    end

    def controller_issues_new_after_save(context = {})
      return if skip_webhooks(context)
      issue = context[:issue]
      controller = context[:controller]
      webhooks = get_webhooks(issue.project)
      return unless webhooks
      post(webhooks, issue_to_json(issue, controller))
    end

    def controller_issues_edit_after_save(context = {})
      return if skip_webhooks(context)
      journal = context[:journal]
      controller = context[:controller]
      issue = context[:issue]
      webhooks = get_webhooks(issue.project)
      return unless webhooks
      post(webhooks, journal_to_json(issue, journal, controller))
    end

    def controller_issues_bulk_edit_after_save(context = {})
      return if skip_webhooks(context)
      journal = context[:journal]
      controller = context[:controller]
      issue = context[:issue]
      webhooks = get_webhooks(issue.project)
      return unless webhooks
      post(webhooks, journal_to_json(issue, journal, controller))
    end

    def model_changeset_scan_commit_for_issue_ids_pre_issue_update(context = {})
      issue = context[:issue]
      journal = issue.current_journal
      webhooks = get_webhooks(issue.project)
      return unless webhooks
      post(webhooks, journal_to_json(issue, journal, nil))
    end

    private
    def issue_to_json(issue, controller)
      {
        :action => 'opened',
        :issue => RedmineWebhook::IssueWrapper.new(issue).to_hash,
        :url => controller.issue_url(issue)
      }.to_json
    end

    def journal_to_json(issue, journal, controller)
      {
        :action => 'updated',
        :issue => RedmineWebhook::IssueWrapper.new(issue).to_hash,
        :journal => RedmineWebhook::JournalWrapper.new(journal).to_hash,
        :url => controller.nil? ? 'not yet implemented' : controller.issue_url(issue)
      }.to_json
    end

    def post(webhooks, request_body)
      Thread.start do
        webhooks.each do |webhook|
          begin
            # Sign payload
            hmac_alg = webhook.hmac_alg
            hmac_alg = "sha256" unless hmac_alg
            key = webhook.secret_key
            if key
              Rails.logger.error 'The super secret key is: %p' % key
              mac = OpenSSL::HMAC.hexdigest(hmac_alg, key, request_body)
            end
            Faraday.post do |req|
              req.url webhook.url
              req.headers['Content-Type'] = 'application/json'
              req.headers['Authorization'] = "hmac-#{hmac_alg} #{mac}" if key && mac
              req.headers['X-Authorization-HMAC-Alg'] = "#{hmac_alg}" if key && mac
              req.body = request_body
            end
          rescue => e
            Rails.logger.error e
          end
        end
      end
    end
  end
end
