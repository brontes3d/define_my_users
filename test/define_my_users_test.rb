require 'test/unit'

#set rails env CONSTANT (we are not actually loading rails in this test, but activerecord depends on this constant)
RAILS_ENV = 'test' unless defined?(RAILS_ENV)

require 'rubygems'
require 'activerecord'

#setup active record to use a sqlite database
# ActiveRecord::Base.configurations = {"test"=>{"dbfile"=>"test.db", "adapter"=>"sqlite3"}}
# ActiveRecord::Base.establish_connection
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

#load the database schema for this test
load File.expand_path(File.dirname(__FILE__) + "/voting_system/schema.rb")

#require this plugin
require "#{File.dirname(__FILE__)}/../init"

#require the mock models for the voting system
require File.expand_path(File.dirname(__FILE__) + '/voting_system/models.rb')

class DefineMyUsersTest < Test::Unit::TestCase

  def test_that_bare_users_can_exist
    login = Login.new
    login.username = "bob"
    assert login.save

    assert_equal(nil, login.primary_user_type)
    assert_equal(nil, login.primary_role)

    login = Login.find_by_username("bob")

    assert_equal(nil, login.primary_user_type)
    assert_equal(nil, login.primary_role)
  end

  def test_that_voters_have_a_login
    voter = Voter.new

    #after assignment of a linked attribute, voter has an associated Login
    assert_equal(nil, voter.login)
    voter.username = "voter"
    voter.role = 'voter'
    assert voter.login.is_a?(Login)

    voter.save!

    #By creating a Voter with the username 'voter' we should have implicitly created a Login too
    login = Login.find_by_username("voter")
    assert login
  end
  
  def test_role_read_and_role_assign_is_symbol
    can = Candidate.new
    
    can.role = :republican_candidate
    assert_equal(:republican_candidate, can.role)
    assert_equal('republican_candidate', can.read_attribute(:role))
    can.role = 'republican_candidate'
    assert_equal(:republican_candidate, can.role)
    assert_equal('republican_candidate', can.read_attribute(:role))

    can.role = nil
    assert_equal(nil, can.role)
    assert_equal(nil, can.read_attribute(:role))
    
    can.role = :democratic_candidate
    assert_equal(:democratic_candidate, can.role)
    assert_equal('democratic_candidate', can.read_attribute(:role))
    
    can.save!
    can = Candidate.find(can.id)
    
    assert_equal(:democratic_candidate, can.role)
  end

  def test_that_you_can_be_both_voter_and_candidate
    login = Login.new
    login.username = "dual_purpose"

    #assert that you can't assign non-existent roles
    assert_raises(ArgumentError, "Expecting an error when setting a non-existent role") do
      login.roles = [:some_non_existent_role]
    end

    login.roles = [:republican_candidate, :voter]
    assert login.save

    login = Login.find_by_username("dual_purpose")
    assert login

    #since the first role is 'republican_candidate', it should be a Candidate
    assert login.user_types[0].is_a?(Candidate), "Expecting first user type to be of type Candidate"

    #check sort positions
    assert((login.user_types[1].sort_position > login.user_types[0].sort_position), 
      "second user_type should have greater sort position that first: " + 
      "#{login.user_types[1].sort_position} should be > than #{login.user_types[0].sort_position}")

    assert_equal(:republican_candidate, login.roles[0])
    #since the first role is 'voter', it should be a Voter
    assert login.user_types[1].is_a?(Voter)
    assert_equal(:voter, login.roles[1])

    #primary user should be the first user
    assert login.primary_user_type.is_a?(Candidate)

    #primary role should be 'republican_candidate'
    assert_equal(:republican_candidate, login.primary_role)
  end


  def test_that_you_can_be_both_voter_and_candidate_via_user_type
    login = Login.new
    login.username = "dual_purpose2"

    login.user_types = [Candidate.new(:role => :republican_candidate), Voter.new(:role => :voter)]
    assert login.save

    login = Login.find_by_username("dual_purpose2")
    assert login

    #since the first role is 'republican_candidate', it should be a Candidate
    assert login.user_types[0].is_a?(Candidate), "Expecting first user type to be of type Candidate"

    #check sort positions
    assert((login.user_types[1].sort_position > login.user_types[0].sort_position), 
      "second user_type should have greater sort position that first: " + 
      "#{login.user_types[1].sort_position} should be > than #{login.user_types[0].sort_position}")

    assert_equal(:republican_candidate, login.roles[0])
    #since the first role is 'voter', it should be a Voter
    assert login.user_types[1].is_a?(Voter)
    assert_equal(:voter, login.roles[1])

    #primary user should be the first user
    assert login.primary_user_type.is_a?(Candidate)

    #primary role should be 'republican_candidate'
    assert_equal(:republican_candidate, login.primary_role)    
  end

  def test_changing_user_types_and_roles
    login = Login.new
    login.username = "changing"

    voter_type = Voter.new(:role => :voter)
    login.user_types = [Candidate.new(:role => :republican_candidate), voter_type]
    asserts_to_run = Proc.new do |whenrun|
      assert_equal([:republican_candidate, :voter], login.roles, "#{whenrun} Should have the 2 roles we assigned, and no others")
      assert_equal(2, login.user_types.size, "#{whenrun} Expecting 2 user types but found: " + login.user_types.inspect)
    end

    asserts_to_run.call("before save: ")
    login.save!
    asserts_to_run.call("after save: ")

    assert_equal(voter_type, Voter.find_by_id(voter_type.id), "voter type should have been created")

    previous_candidate = login.user_types[0]

    login.roles = [:republican_candidate]
    asserts_to_run = Proc.new do |whenrun|
      assert_equal([:republican_candidate], login.roles, "#{whenrun} Should have the 1 role we assigned, and no others")
      assert_equal(1, login.user_types.size, "#{whenrun} Expecting 1 user type but found: " + login.user_types.inspect)
      assert_equal(previous_candidate, login.user_types[0], "should be the same user type object, since role and index didn't change")
    end

    asserts_to_run.call("before save: ")
    login.save!
    asserts_to_run.call("after save: ")

    assert_equal(nil, Voter.find_by_id(voter_type.id), "voter type should have been destroyed")

    login.user_types = [Candidate.new(:role => :democratic_candidate), Voter.new(:role => :voter)]
    asserts_to_run = Proc.new do |whenrun|
      assert_equal([:democratic_candidate, :voter], login.roles, "#{whenrun} Should have the 2 roles we assigned, and no others")
      assert_equal(2, login.user_types.size, "#{whenrun} Expecting 2 user types but found: " + login.user_types.inspect)
    end

    asserts_to_run.call("before save: ")
    login.save!
    asserts_to_run.call("after save: ")

    login.user_types = [Voter.new(:role => :voter)]
    asserts_to_run = Proc.new do |whenrun|
      assert_equal([:voter], login.roles, "#{whenrun} Should have the 1 role we assigned, and no others")
      assert_equal(1, login.user_types.size, "#{whenrun} Expecting 1 user type but found: " + login.user_types.inspect)
    end

    asserts_to_run.call("before save: ")
    login.save!
    asserts_to_run.call("after save: ")
  end

  #TODO: test the multiple role support exception (for a model that doesn't define sort_position)

  #TODO: test that things can't specify 'roles' unless they implement 'role'

  #TODO:
  # def test_that_internal_users_dont_need_defined_roles
  #   flunk
  # end
  # 
  # def test_exceptions_for_bad_calls_to_i_am_user
  #   flunk
  # end
  # 
  # def test_exceptions_for_bad_calls_to_implements_user
  #   flunk
  # end

end
