require 'paramix'

$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'define_my_users'
require 'define_my_users/role_assignment'
require 'define_my_users/declarations/i_am_user'
require 'define_my_users/declarations/implements_user'
require 'define_my_users/active_record_extensions'

ActiveRecord::Base.class_eval do
  include DefineMyUsers::ActiveRecordExtensions
end