module DefineMyUsers::Declarations::ImplementsUser

  def self.run_after_included(base, params)
    
    user_attributes = params[:attributes]
    all_defined_roles = params[:roles] || []
    
    #if this call to implements_user includes roles
    #than the calling class must respond_to 'role'
    if all_defined_roles.size > 0
      # puts base.public_methods.inspect
      unless base.new.respond_to?(:role)
        raise ArgumentError, "#{base} can't have :roles unless it defines 'role'"
      end
      base.class_eval do
        def role
          val = read_attribute(:role)
          val.blank? ? nil : val.to_sym
        end
        def role=(arg)
          write_attribute(:role, arg ? arg.to_s : arg)
        end
      end
    end
    
    #give the User class a has_one for this associated user
    #we should also validate that 'base' has the appropriate belongs_to
    user_class = params[:user_class]
    underscore_name = base.name.to_s.pluralize.underscore
    method_for_user = user_class.name.to_s.underscore
    eval %Q{
      #{user_class.name.to_s}.class_eval do
        cattr_accessor :typed_user_associations
        has_many :#{underscore_name}
      end
    }
    user_class.typed_user_associations ||= []
    user_class.typed_user_associations << underscore_name
    
    #add getters and setters for each attribute on self that needs to be transplanted from User
    user_attributes.each do |att|
      eval %Q{
        #{base.name}.class_eval do
          def #{att.to_s}
            ensure_existance_of_user
            self.true_user_object.#{att.to_s}
          end
          def #{att.to_s}=(arg)
            ensure_existance_of_user
            self.true_user_object.#{att.to_s}=arg
          end
          
          def true_user_object
            self.#{method_for_user}
          end

          def ensure_existance_of_user
            self.#{method_for_user} ||= #{user_class.name}.new
          end
          
        end
      }
    end
    
    #setup class accessor for the user_attributes (to be used by the validation method defined below...)
    base.class_eval do
      cattr_accessor :implements_user_attributes
      cattr_accessor :available_roles      
    end
    base.implements_user_attributes = user_attributes
    base.available_roles = all_defined_roles
    
    base.class_eval do
      validates_inclusion_of :role, :in => available_roles
    end
    
  end
  
  def roles
    self.true_user_object.roles
  end
  
  def user_types
    self.true_user_object.user_types
  end
  
  def primary_user_type
    self.true_user_object.primary_user_type
  end
  
  def primary_role
    self.true_user_object.primary_role
  end
  
  def <=>(other_user_type)
    # puts "comparing #{self} to #{other_user_type}"
    to_return = (self.role.to_s <=> other_user_type.role.to_s)
    if to_return == 0
      if self.respond_to?(:secondary_sort_name) && other_user_type.respond_to?(:secondary_sort_name)
        self.secondary_sort_name.to_s <=> other_user_type.secondary_sort_name.to_s
      else
        0
      end
    else
      to_return
    end
  end
  
end