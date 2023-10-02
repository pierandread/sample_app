class User < ApplicationRecord
  attr_accessor :remember_token

  before_save { email.downcase! }
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
  # remember_digest same as self.remember_digest is created automatically by Active Record based on name of db column
  def authenticated?(remember_token)
    return false if remember_digest.nil?

    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  def forget
    update_attribute(:remember_digest, nil)
  end
end
