# frozen_string_literal: true

class User < ApplicationRecord
  has_many :microposts, dependent: :destroy
  #  pag 760
  # if Calvin is following Hobbes but not vice versa, Calvin has an active relationship with Hobbes and Hobbes has a passive relationship with Calvin.
  # foreign_key = user_id -> follower_id/followed_id
  has_many :active_relationships, class_name: 'Relationship', foreign_key: 'follower_id', dependent: :destroy
  has_many :passive_relationship, class_name: 'Relationship', foreign_key: 'followed_id', dependent: :destroy
  # source: option to explicitly tell Rails that the source of the following array is the set of followed ids in the active_relationships table.
  has_many :following, through: :active_relationships, source: :followed
  # in this case source not needed (rails will found it by itself), but added for symmetry and studying
  has_many :followers, through: :passive_relationship, source: :follower

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
    # 1st
    # Micropost.where('user_id IN (?) OR user_id = ?', following_ids, id)
    # 2nd
    following_ids = 'SELECT followed_id FROM relationships WHERE follower_id= :user_id'
    # Micropost.where("user_id IN (#{following_ids}) OR user_id = :user_id", user_id: id)
    #          .includes(:user, image_attachment: :blob)
    # 3rd
    part_of_feed = "relationships.follower_id = :id or microposts.user_id = :id"
    Micropost.left_outer_joins(user: :followers)
             .where(part_of_feed, {id: id}).distinct
             .includes(:user, image_attachment: :blob)
  end

  # 1st irb(main):001> User.first.feed
  # User Load (0.0ms)  SELECT "users".* FROM "users" ORDER BY "users"."id" ASC LIMIT ?  [["LIMIT", 1]]
  # User Pluck (0.1ms)  SELECT "users"."id" FROM "users" INNER JOIN "relationships" ON "users"."id" = "relationships"."followed_id" WHERE "relationships"."follower_id" = ?  [["follower_id", 1]]
  # Micropost Load (1.3ms)  SELECT "microposts".* FROM "microposts" WHERE (user_id IN (3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51) OR user_id = 1) ORDER BY "microposts"."created_at" DESC
  # =>
  # 2nd without include User Load (0.0ms)  SELECT "users".* FROM "users" ORDER BY "users"."id" ASC LIMIT ?  [["LIMIT", 1]]
  #   Micropost Load (0.4ms)  SELECT "microposts".* FROM "microposts" WHERE (user_id IN (SELECT followed_id FROM relationships WHERE follower_id= 1) OR user_id = 1) ORDER BY "microposts"."created_at" DESC
  # =>
  # 3rd (only third include DISTINCT for this  SELECT DISTINCT)
  # irb(main):002> User.last.feed
  #   User Load (0.1ms)  SELECT "users".* FROM "users" ORDER BY "users"."id" DESC LIMIT ?  [["LIMIT", 1]]
  #   Micropost Load (0.3ms) SELECT DISTINCT "microposts".* FROM "microposts" LEFT OUTER JOIN "users" ON "users"."id" = "microposts"."user_id" LEFT OUTER JOIN "relationships" ON "relationships"."followed_id" = "users"."id" LEFT OUTER JOIN "users" "followers_users" ON "followers_users"."id" = "relationships"."follower_id" WHERE (relationships.follower_id = 101 or microposts.user_id = 101) ORDER BY "microposts"."created_at" DESC

  def follow(other_user)
    following << other_user unless self == other_user
  end

  def unfollow(other_user)
    following.delete(other_user)
  end

  def following?(other_user)
    following.include?(other_user)
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
