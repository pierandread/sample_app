# frozen_string_literal: true

class User < ApplicationRecord
  has_many :microposts, dependent: :destroy
  #  pag 760
  # if Calvin is following Hobbes but not vice versa, Calvin has an active relationship with Hobbes and Hobbes has a passive relationship with Calvin.
  has_many :active_relationships, class_name: 'Relationship', foreign_key: 'follower_id', dependent: :destroy

  attr_accessor :remember_token, :activation_token, :reset_token

  before_save :downcase_email
  before_create :create_activation_digest
  # or self.email = email.downcase
  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true

  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  # returns hash digest of the given string
  def self.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost:)
  end

  # random token
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # remember user in db for use in persistent session
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
    remember_digest
  end

  # returns a session token to prevent session hijacking
  # we reuse the remember digest for convenience
  def session_token
    remember_digest || remember
  end

  # true if given token matches the digest
  # previous version: remember_digest same as self.remember_digest is created automatically by Active Record based on name of db column
  def authenticated?(attribute, token)
    # we can omit self.send because we are inside User model
    digest = send("#{attribute}_digest")
    return false if digest.nil?

    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    update_attribute(:remember_digest, nil)
  end

  # Activate account
  def activate
    # no self because optional in Model
    update_columns(activated: true, activated_at: Time.zone.now)
   end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(reset_digest: User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    # < to read as "earlier than"
    reset_sent_at < 2.hours.ago
  end

  def feed
    Micropost.where('user_id = ?', id)
  end

  private

  def downcase_email
    email.downcase!
  end

  def create_activation_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end
