class UserEmail < ActiveRecord::Base
  belongs_to :user

  validates :email, presence: true
  before_create :format_email

  def reprocess_emails
    Email.unprocessed.where(from: email).find_each(&:process)
  end
  handle_asynchronously :reprocess_emails

  private

  def format_email
    self.email = email.to_s.downcase
  end
end
