class Voter < ActiveRecord::Base 
end
class Candidate < ActiveRecord::Base
end
class InternalUser < ActiveRecord::Base
end

class Login < ActiveRecord::Base
  
  i_am_user :user_types => [Voter, Candidate, InternalUser]
  
end

class Candidate < ActiveRecord::Base
  
  belongs_to :login
  implements_user Login, :attributes => [:username, :password], 
                         :roles => [:republican_candidate, :democratic_candidate, :independent_candidate]
  
end

class Voter < ActiveRecord::Base
  
  belongs_to :login  
  implements_user Login, :attributes => [:username, :password], 
                         :roles => [:voter]
  
end

class InternalUser < ActiveRecord::Base
  
  belongs_to :login
  implements_user Login, :attributes => [:username, :password]
  
end