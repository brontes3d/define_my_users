module DefineMyUsers::Declarations::IAmUser

  def self.run_after_included(base, params)
    
    user_types = params[:user_types] or raise ArgumentError, "no :user_types defined on i_am_user for #{base}"
    base.class_eval do
      cattr_accessor :all_user_type_classes      
    end
    base.all_user_type_classes = user_types
    
    base.class_eval do
      def self.role_to_user_type
        unless @role_to_user_type
          @role_to_user_type = {}
          all_user_type_classes.each do |user_type|
            user_type.available_roles.each do |role|
              @role_to_user_type[role.to_sym] = user_type
            end
          end
        end
        @role_to_user_type
      end
      
      def self.user_type_for_role(role)
        role_to_user_type[role.to_sym]
      end

      def self.all_roles
        role_to_user_type.keys
      end

      def self.all_user_types
        role_to_user_type.values.uniq
      end
      
      def self.all_roles_for_select
        role_to_user_type.keys.collect{ |role| [role.to_s.humanize, role] }
      end
         
      def roles_to_delete=(arg)
        @roles_to_delete = arg
      end
      def roles_to_delete
        @roles_to_delete ||= []
      end
      
      after_save :save_associated_roles
      def save_associated_roles
        user_types.each do |roleuser|
          # puts "self: #{self.class.name.underscore}="
          roleuser.send("#{self.class.name.underscore}=", self)
          # roleuser.user = self
          roleuser.save!
        end
        roles_to_delete.each do |roleuser|
          roleuser.destroy
        end
      end
      
    end
  end  
  
  def true_user_object
    self
  end  
  
  #another name for this is perhaps typed_users
  def user_types
    self.typed_user_associations.collect do |assoc|
      self.send(assoc)
    end.flatten.sort do |usera, userb|
      usera.sort_position ||= 0
      userb.sort_position ||= 0
      usera.sort_position <=> userb.sort_position
    end
  end
  
  #another name for this is perhaps typed_users
  def user_types=(values)
    role_assignments = []
    values.each do |value|
      role_assignments << DefineMyUsers::RoleAssignment.new(self, :user_type => value)
    end
    DefineMyUsers::RoleAssignment.reconcile_role_assignments(self, role_assignments)
  end
  
  #roles is like user_types BUT different
  #because we want to accept symbols for the roles as submitted by a form
  #instead of the typed_user/role objects accepted by user_types=
  #So, roles returns symbols, user_types returns 'user-like' objects
  
  def roles
    user_types.collect do |roleuser|
      roleuser.role.to_sym
    end
  end
  
  def has_role?(role_name)
    self.roles.include?(role_name.to_sym)
  end
  
  def roles=(roles_given)
    role_assignments = []
    roles_given.each do |role_name|
      role_assignments << DefineMyUsers::RoleAssignment.new(self, :role => role_name)
    end
    DefineMyUsers::RoleAssignment.reconcile_role_assignments(self, role_assignments)
  end
    
  def primary_user_type
    self.user_types[0] if user_types.size > 0
  end
    
  def primary_role
    self.primary_user_type.role.to_sym if primary_user_type
  end
  
  
end