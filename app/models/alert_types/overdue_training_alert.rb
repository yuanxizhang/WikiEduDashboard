# frozen_string_literal: true

# == Schema Information
#
# Table name: alerts
#
#  id             :integer          not null, primary key
#  course_id      :integer
#  user_id        :integer
#  article_id     :integer
#  revision_id    :integer
#  type           :string(255)
#  email_sent_at  :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  message        :text(65535)
#  target_user_id :integer
#  subject_id     :integer
#  resolved       :boolean          default(FALSE)
#  details        :text(65535)
#

# Alert for when a student has an assigned training that is overdue
class OverdueTrainingAlert < Alert
  MINIMUM_DAYS_BETWEEN_ALERTS = 10

  def main_subject
    "Overdue training module for #{course.slug}"
  end

  def url
    "https://#{ENV['dashboard_url']}/courses/#{course.slug}"
  end

  def mailer
    OverdueTrainingAlertMailer
  end
end
