module DefineMyUsers::ActiveRecordExtensions
  
  def self.included(base)
    base.class_eval do

      #allows this class to login
      #assumes it implements certain required methods
      #TODO: validate such assumptions
      def self.implements_user(user_class, options = {})
        self.class_eval do
          include DefineMyUsers::Declarations::ImplementsUser
        end
        DefineMyUsers::Declarations::ImplementsUser.run_after_included(self, options.merge(:user_class => user_class))
      end      

      def self.i_am_user(options = {})
        self.class_eval do
          include DefineMyUsers::Declarations::IAmUser
        end
        DefineMyUsers::Declarations::IAmUser.run_after_included(self, options)
      end      

    end
  end
  
end