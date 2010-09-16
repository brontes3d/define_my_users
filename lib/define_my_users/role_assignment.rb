class DefineMyUsers::RoleAssignment
  
  attr_accessor :for_user, :role, :user_type_class, :user_type
  
  def initialize(for_user, from_hash)
    self.for_user = for_user
    
    self.role = from_hash[:role]
    self.user_type_class = from_hash[:user_type_class]
    self.user_type = from_hash[:user_type]
    
    if self.user_type
      self.role ||= self.user_type.role
      self.user_type_class ||= self.user_type.class
    end
    
    if self.role.blank?
      raise ArgumentError, "Can't assign blank roles"
    end
    self.user_type_class ||= self.for_user.class.role_to_user_type[self.role.to_sym]
    self.role ||= self.user_type.available_roles[0]
    
    unless self.role
      raise ArgumentError, "Couldn't determine role to assign from hash given: " + from_hash.inspect
    end
    if !self.user_type_class || (self.user_type_class == nil.class)
      raise ArgumentError, "Couldn't determine user_type_class to assign from hash given: " + from_hash.inspect
    end
    
    self.user_type ||= self.user_type_class.new
    unless self.user_type
      raise ArgumentError, "Couldn't determine user_type to assign from hash given: " + from_hash.inspect
    end
    unless self.user_type.available_roles.include?(self.role.to_sym)
      raise ArgumentError, "#{self.role} is not a valid role for #{self.user_type_class}"
    end
    
    self.user_type.role = self.role.to_s
  end
  
  def assoc_name
    self.user_type_class.name.to_s.pluralize.underscore
  end
  
  def belongs_with_assoc?(assoc_string)
    self.user_type_class.name.to_s.pluralize.underscore == assoc_string.to_s
  end
  
  def self.reconcile_role_assignments(for_user, role_assigments)
    # puts "reconcile_role_assignments: " + for_user.inspect
    # puts "role_assigments: " + role_assigments.inspect
    
    user_types_existing = for_user.user_types.sort{ |a,b| a.sort_position <=> b.sort_position }
    
    primary_role_assigment = role_assigments[0]
    role_assigments = role_assigments.sort{|a,b| a.user_type <=> b.user_type }
    user_types_existing = user_types_existing.sort{|a,b| a <=> b }
    
    # puts "\n\n Primary role should be: " + primary_role_assigment.inspect
    
    # puts "role_assigments: " + role_assigments.collect{|ra| ut = ra.user_type; [ut.role, ut.secondary_sort_name]}.to_yaml
    # puts "user_types_existing: " + user_types_existing.collect{|ut| [ut.role, ut.secondary_sort_name]}.to_yaml
    
    # re-write:
    ri = 0
    ui = 0
    sort_position = 1
    while(ri < role_assigments.size || ui < user_types_existing.size) do
      rassign = role_assigments[ri]
      utype_exists = user_types_existing[ui]
      difference = if !utype_exists
        ui += 1
        -1
      elsif !rassign
        ri += 1
        1
      else
        (rassign.user_type <=> utype_exists)
      end
      # puts "difference: #{difference} ri #{ri} #{(rassign && rassign.user_type)} -- ui #{ui} #{utype_exists}"
      if difference == 0
        #same role, let it be
        # puts "therefore same role"
        
        if (primary_role_assigment == rassign)
          if(utype_exists.sort_position != 0)
            utype_exists.sort_position = 0
            utype_exists.save!
          end
        else
          if (utype_exists.sort_position != sort_position)
            utype_exists.sort_position = sort_position
            utype_exists.save!
          end
        end
        ri += 1
        ui += 1
      elsif difference < 0
        #utype_exists comes after rassign.user_type, therefore utype_exists does not exist in role_assigments
        #therefore add: rassign
        if(primary_role_assigment == rassign)
          rassign.user_type.sort_position = 0
        else
          rassign.user_type.sort_position = sort_position
        end
        arr = for_user.send(rassign.assoc_name).to_a
        arr << rassign.user_type
        for_user.send("#{rassign.assoc_name}=", arr)
        rassign.user_type.send("#{for_user.class.name.to_s.underscore}=", for_user)
        # puts "therefore add role #{ri} #{rassign.user_type}"
        ri += 1
      elsif difference > 0
        #rassign.user_type comes after utype_exists, therefore rassign.user_type does not exist in user_types_existing
        #therefore destroy: utype_exists, check the next utype_exists
        
        for_user.send(utype_exists.class.name.to_s.pluralize.underscore).destroy(utype_exists)
        for_user.send(utype_exists.class.name.to_s.pluralize.underscore).target.delete(utype_exists)
        
        # utype_exists.destroy
        # puts "therefore delete role #{ui} #{utype_exists}"
        ui += 1
      end
      sort_position += 1
    end
    
  end
  
end