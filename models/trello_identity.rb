class TrelloIdentity < ActiveRecord::Base
  NotAnOrgMember = Class.new(StandardError)

  belongs_to :user

  serialize :omniauth_data
  validates :omniauth_data, presence: true

  before_save :check_is_org_member

  def client
    @client ||= Trello.new(Trello.key, credentials.token, credentials.secret)
  end

  def username
    omniauth_data.info.nickname
  end

  def email
    omniauth_data.info.email
  end

  def organizations
    omniauth_data.extra.raw_info.idOrganizations
  end

  delegate :credentials, to: :omniauth_data

  private

  def check_is_org_member
    raise NotAnOrgMember unless organizations.include?(ENV.fetch('ORGANIZATION_ID'))
  end
end
